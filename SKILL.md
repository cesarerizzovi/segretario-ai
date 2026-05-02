---
name: segretario-ai
description: >
  Contesto completo del progetto Segretario AI — assistente personale via Signal orchestrato da n8n.
  Usa questa skill per qualsiasi lavoro su workflow n8n, sub-workflow tool, database SQLite,
  integrazione Whisper, calendari Outlook/Google, o qualsiasi componente del progetto Segretario AI.
---

# SKILL.md — Contesto progetto per Claude Code
## Segretario AI

### Scopo del progetto
Assistente personale AI accessibile via Signal (voce e testo).
Gestisce calendari (Outlook + Google), task con solleciti proattivi
ed escalation, e invia un briefing mattutino giornaliero.

### Stack tecnico
- n8n 2.4.6 (self-hosted Docker, porta 5678)
- signal-cli-rest-api (Docker, porta 8085) — **DEPLOYATO E FUNZIONANTE**
- Claude API — modello `claude-sonnet-4-20250514` — **AI Agent con tool**
- Whisper API (OpenAI) — STT per messaggi vocali Signal
- Edge TTS — **NON implementato** (decisione: risposte solo in testo)
- SQLite — database locale (`/data/segretario.db` nel container n8n)
- Microsoft Graph API — Outlook Calendar
- Google Calendar API — calendario privato
- ffmpeg statico — conversione audio AAC→MP3 per Whisper (`/data/ffmpeg`)
- SQLite Web — interfaccia web database (`http://192.168.1.50:8002`)

### Architettura principale
**AI Agent con tool** (migrazione completata aprile/maggio 2026).
L'orchestrazione avviene tramite il nodo AI Agent di n8n con 9 tool dedicati,
ciascuno implementato come sub-workflow separato.

**Principio:** "AI capisce l'intent, n8n calcola i dati deterministici"
- Claude sceglie il tool e i parametri semantici
- n8n esegue i calcoli di date, query SQLite, chiamate API

---

### Infrastruttura Docker esistente (NON toccare)
| Container | Porta host | Note |
|---|---|---|
| waha_tel1 | 3000 | |
| waha_tel2 | 3001 | |
| gestionale-caterina | 3002 | |
| gestionale_nextjs | 3003 | |
| spese_nextjs | 3005 | |
| trasferte-app | 3006 | |
| cantinetta_nextjs | 3007 | |
| n8n | 5678 | orchestratore principale |
| servizi_postgres | 5432 | |
| gestionale_postgres | 5433 | |
| spese_postgres | 5434 | |
| trasferte-db | 5435 | |
| cantinetta_postgres | 5436 | |
| pgadmin | 8080 | |
| dockge | 5001 | |
| portainer | 9000/9443 | |
| cloudflared | — | Cloudflare Tunnel |

### Container di questo progetto
| Container | Porta host | Stato |
|---|---|---|
| segretario_signal_cli | 8085 | Attivo e funzionante |
| sqliteweb | 8002 | Attivo — interfaccia web SQLite |

---

### ⚠️ RETI DOCKER — MAPPA E REGOLE CRITICHE

| Rete | Container |
|---|---|
| **automation_network** | servizi_postgres, pgadmin, trasferte-app, gestionale-caterina |
| **automation_automation_network** | cloudflared, waha_tel1, waha_tel2, cantinetta_nextjs, gestionale_nextjs, segretario_signal_cli |
| **entrambe** | **n8n** (collegato a entrambe dopo fix 20/04/2026) |

**Regola critica:** MAI eseguire `docker compose down` in `~/progetti/automation`.
Dopo ogni riavvio di n8n: `docker network connect automation_network n8n`

---

### Database SQLite — Schema

**Path host:** `/home/cesare/progetti/segretario-ai/03_database/segretario.db`
**Path container n8n:** `/data/segretario.db`

Tabelle:
- `task` — id, descrizione, scadenza, priorita, stato, reminder_count, ultimo_sollecito, next_followup_at, snooze_until, source_message_id, calendar_event_id, creato_il, updated_at, completato_il, categoria
- `messages_inbox` — messaggi ricevuti (deduplicazione su signal_message_id UNIQUE)
- `messages_outbox` — risposte inviate
- `system_settings` — configurazioni operative
- `conversazione` — storico conversazione (ultimi 10 scambi)

**Valori system_settings correnti:**
| chiave | valore |
|---|---|
| orario_quiete_inizio | 21:00 |
| orario_quiete_fine | 07:30 |
| giorni_esclusi | domenica |
| briefing_orario | 07:00 |
| frequenza_solleciti_ore | 3 |
| escalation_soglia_chiamata | 4 |
| slot_mattina_inizio | 08:00 |
| slot_mattina_fine | 12:00 |
| slot_pomeriggio_inizio | 14:30 |
| slot_pomeriggio_fine | 18:30 |

---

### Workflow n8n — Struttura completa

#### Workflow principale: "Segretario AI"
```
Signal Trigger
  → Salva in inbox (SQLite, deduplicazione, mappa date, storico conversazione)
  → IF Deduplicazione (is_nuovo)
  → IF È vocale?
      → true: Scarica audio → Converti audio (ffmpeg) → Leggi audio MP3 → Whisper STT → Estrai trascrizione
      → false: diretto
  → AI Agent (Claude Sonnet + 9 tool)
  → Invia risposta Signal
  → Salva in outbox
```

#### Sub-workflow tool (tutti pubblicati e attivi):
| Nome workflow | Tool | Input |
|---|---|---|
| Tool - Crea Task | crea_task | descrizione, scadenza, priorita |
| Tool - Lista Task | lista_task | filtro |
| Tool - Completa Task | completa_task | task_descrizione |
| Tool - Annulla Task | annulla_task | task_descrizione |
| Tool - Posticipa Task | posticipa_task | task_descrizione, nuova_scadenza |
| Tool - Crea Appuntamento Outlook | crea_appuntamento_outlook | title, start, end |
| Tool - Crea Appuntamento Google | crea_appuntamento_google | title, start, end |
| Tool - Leggi Calendario | leggi_calendario | tipo, valore, filtro_calendario |
| Tool - Cerca Slot | cerca_slot | descrizione, durata_minuti, data_preferita, ora_preferita |
| Tool - Conferma Slot | conferma_slot | start_iso, end_iso, descrizione |

#### Workflow autonomi:
- **Segretario AI — Briefing Mattutino** — cron ore 07:00, legge Outlook + Google + task, invia via Signal
- **Segretario AI — Scheduler Solleciti** — ogni 3 ore, controlla task scaduti, escalation 4 livelli

---

### Dettagli tecnici critici

#### Tool leggi_calendario — logica date
Il tool usa `tipo` + `valore` invece di date ISO dirette.
Claude passa solo il tipo semantico, n8n calcola le date:
- `tipo: "relativo"` + `valore: "oggi|domani|questa_settimana|prossima_settimana"`
- `tipo: "assoluto"` + `valore: "YYYY-MM-DD"`

Il nodo **Prepara Filtro** usa Luxon (`DateTime`) — disponibile nativamente nei nodi Code n8n.

#### Tool crea_task e posticipa_task — date
La description del parametro `scadenza`/`nuova_scadenza` include istruzione esplicita
di usare la TABELLA_DATE dal system prompt. Senza questa istruzione Claude calcola
le date autonomamente e sbaglia.

#### Ricezione vocali
Flusso: Signal vocale → signal-cli → HTTP GET `/v1/attachments/{id}` → ffmpeg statico
`/data/ffmpeg` → MP3 in `/home/node/.n8n-files/` → Whisper API → testo → AI Agent

**Note critiche ffmpeg:**
- Binario statico in `/data/ffmpeg` (accessibile dal task runner n8n)
- File temporanei in `/home/node/.n8n-files/` (unica path scrivibile dal nodo Read/Write Files)
- I nodi Code nel task runner NON possono usare `/tmp` (permessi negati)
- Il nodo Read/Write Files accetta solo path sotto `/home/node/.n8n-files/`

#### Invia risposta Signal
Il destinatario è hardcodato: `+393495931632`.
Non usa riferimenti a nodi precedenti per evitare errori `pairedItem`.

#### System prompt AI Agent
Contiene `<CONTESTO_TEMPORALE>` con mappa date generata dinamicamente da `Salva in inbox`.
La mappa include: giorni nominali, `questa_settimana [lunedì TO domenica]`, `prossima_settimana [lunedì TO domenica]`.

#### Nodo Code come tool — regola fondamentale
I nodi Code usati come tool devono restituire una **stringa**, non `[{ json: {} }]`.
Attivare **Specify Input Schema** con JSON Schema per ogni parametro.

#### require('sqlite3') nei tool
`require('sqlite3')` funziona nei **sub-workflow** (nodi Code normali) ma NON nei nodi Code
collegati direttamente come tool all'AI Agent (task runner sandbox). Per questo tutti i tool
SQLite sono implementati come sub-workflow chiamati tramite "Call n8n Workflow".

---

### Struttura cartelle
- `01_infra/` → docker-compose.yml, .env, .env.example
- `02_n8n/workflows/` → workflow JSON esportati da n8n
- `02_n8n/prompts/` → system-prompt.md
- `03_database/` → schema.sql, segretario.db (non committato), ffmpeg (non committato)
- `04_docs/` → guide operative
- `05_test/` → scenari di test

---

## STATO AVANZAMENTO — Maggio 2026

### Fase A — MVP funzionale ✅ COMPLETA
| # | Attività | Stato |
|---|---|---|
| 0 | SIM prepagata dedicata | ✅ Numero: +393517872627 |
| 1 | Deploy signal-cli-rest-api | ✅ Container: segretario_signal_cli |
| 2 | Community node Signal in n8n + workflow base | ✅ |
| 3 | Database SQLite schema completo | ✅ 5 tabelle |
| 4 | AI Agent con 9 tool (migrazione da HTTP Request + IF) | ✅ |
| 5 | Integrazione Microsoft Graph API (Outlook) | ✅ |
| 6 | Integrazione Google Calendar API | ✅ |

### Fase B — Proattività ✅ COMPLETA
| # | Attività | Stato |
|---|---|---|
| 7 | Briefing mattutino ore 07:00 | ✅ |
| 8 | Solleciti task con escalation 4 livelli | ✅ |

### Fase C — Voce ⚠️ PARZIALE
| # | Attività | Stato | Note |
|---|---|---|---|
| 9a | Whisper API STT (ricezione vocali) | ✅ | |
| 9b | Edge TTS (risposte vocali) | ❌ | Decisione: risposta sempre in testo |

### Fase D — Alert forti ❌ NON implementata
| # | Attività | Stato | Note |
|---|---|---|---|
| 10 | CallMeBot / Pushover | ❌ | Decisione: non aggiunge valore per uso personale |

---

## Note operative
- Il file `.db` NON va su GitHub (già in .gitignore)
- Il binario `ffmpeg` NON va su GitHub (80MB) — aggiungere `03_database/ffmpeg` a .gitignore
- I workflow n8n si esportano da UI → `02_n8n/workflows/`
- Il system prompt è in `02_n8n/prompts/system-prompt.md`
- Variabili sensibili (API key, OAuth) sempre e solo nel file `.env`
- SQLite Web: `http://192.168.1.50:8002`
- Dopo ogni `docker restart n8n`: `docker network connect automation_network n8n`
