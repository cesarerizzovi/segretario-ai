# SKILL.md — Contesto progetto per Claude Code
## Segretario AI

### Scopo del progetto
Assistente personale AI accessibile via Signal (voce e testo).
Gestisce calendari (Outlook + Google), task con solleciti proattivi
ed escalation, e invia un briefing mattutino vocale giornaliero.

### Stack tecnico
- n8n (già in esecuzione su Docker, porta 5678)
- signal-cli-rest-api (Docker, porta 8085) — **DEPLOYATO E FUNZIONANTE**
- Claude API — modello Sonnet
- Whisper API (OpenAI) — STT
- Edge TTS (Microsoft) — TTS
- SQLite — database locale (niente PostgreSQL)
- Microsoft Graph API — Outlook Calendar
- Google Calendar API — calendario privato

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

### Porte disponibili per questo progetto
- 8085 → signal-cli-rest-api (già assegnata e in uso)
- Nessuna porta Next.js necessaria (no frontend)
- Nessuna porta PostgreSQL necessaria (SQLite locale)

### Reti Docker
- **automation_automation_network** — rete condivisa con n8n e
  cloudflared. signal-cli-rest-api è su questa rete.
- **segretario_network** — rete privata interna del progetto

### Struttura cartelle
- 01_infra/       → docker-compose.yml, .env, .env.example
- 02_n8n/         → workflow JSON esportati da n8n, system prompt
- 03_database/    → schema.sql, file .db (non committato)
- 04_docs/        → guide operative
- 05_test/        → scenari di test

### Principio architetturale chiave
"AI propone, logica esegue": Claude restituisce JSON con campo
needs_confirmation (true/false). È n8n a decidere se eseguire
o chiedere conferma all'utente, mai il modello.

---

## STATO AVANZAMENTO — Aprile 2026

### Fase A — MVP funzionale

| # | Attività | Stato | Note |
|---|---|---|---|
| 0 | SIM prepagata dedicata | ✅ FATTO | Numero: +393517872627 |
| 1 | Deploy signal-cli-rest-api, registrazione, test | ✅ FATTO | Vedi dettagli sotto |
| 2 | Community node Signal in n8n + workflow base | ⏳ DA FARE | Prossimo passo |
| 3 | Database SQLite: schema completo | ⏳ DA FARE | |
| 4 | System prompt Claude | ⏳ DA FARE | |
| 5 | Integrazione Microsoft Graph API (Outlook) | ⏳ DA FARE | |
| 6 | Integrazione Google Calendar API | ⏳ DA FARE | |

### Fase B — Proattività
| # | Attività | Stato |
|---|---|---|
| 7 | Briefing mattutino | ⏳ DA FARE |
| 8 | Solleciti task con escalation | ⏳ DA FARE |

### Fase C — Voce
| # | Attività | Stato |
|---|---|---|
| 9 | Whisper API (STT) + Edge TTS | ⏳ DA FARE |

### Fase D — Alert forti
| # | Attività | Stato |
|---|---|---|
| 10 | CallMeBot / Pushover | ⏳ DA FARE |

---

## Dettagli tecnici — signal-cli-rest-api

### Configurazione
- **Image:** `bbernhard/signal-cli-rest-api:latest`
- **Container:** `segretario_signal_cli`
- **Porta:** 8085 (host) → 8080 (container)
- **Modo:** `json-rpc` (richiesto dal community node n8n)
- **Volume:** `segretario_signal_cli_config`
- **Config file:** `01_infra/docker-compose.yml`
- **Variabili:** `01_infra/.env` (non committato)

### Numero Signal registrato
- **Numero:** +393517872627
- **Stato:** registrato e verificato via SMS

### Bug risolto in fase di setup
`docker exec` gira come root → signal-cli salvava l'account in
`/root/.local/share/signal-cli/data/` invece del volume montato
in `/home/.local/share/signal-cli/data/`.
**Soluzione applicata:** copiati manualmente i file dal path root
al path corretto. L'account ora è visibile alla REST API.
**Verifica:** `curl http://localhost:8085/v1/accounts` → `["+393517872627"]`

### Comandi utili
```bash
# Verificare che il container risponda
curl http://localhost:8085/v1/health

# Verificare account registrati
curl http://localhost:8085/v1/accounts

# Inviare messaggio di test
curl -X POST "http://localhost:8085/v2/send" -H "Content-Type: application/json" -d '{"message": "Test", "number": "+393517872627", "recipients": ["+39DESTINATARIO"]}'

# Riavviare il container
docker restart segretario_signal_cli
```

---

## Prossimo passo: n8n — Community Node Signal

### Installazione community node
1. Aprire n8n (http://localhost:5678 o subdomain configurato)
2. Settings → Community Nodes → Install
3. Package: `n8n-nodes-signal-cli-rest-api`
4. Riavviare n8n dopo l'installazione

### Primo workflow da costruire (Fase A, punto 2)
**Nome:** `segretario-webhook-base`

Nodi in sequenza:
1. **Signal Trigger** — riceve messaggi in arrivo
2. **SQLite** — salva messaggio in `messages_inbox` (con deduplicazione per `signal_message_id`)
3. **HTTP Request** — chiama Claude API con system prompt
4. **IF** — valuta `needs_confirmation` nel JSON risposta
5. **Signal Send** — invia risposta testuale all'utente
6. **SQLite** — salva risposta in `messages_outbox`

### Riferimento signal-cli-rest-api in n8n
- L'URL da usare nei nodi n8n per raggiungere signal-cli è:
  `http://segretario_signal_cli:8080` (nome container, porta interna)
  perché n8n e signal-cli sono sulla stessa rete Docker

---

## Note operative
- Il file .db NON va su GitHub (già in .gitignore)
- I workflow n8n si esportano da UI → 02_n8n/workflows/
- Il system prompt è in 02_n8n/prompts/system-prompt.md
- Variabili sensibili (API key, OAuth) sempre e solo nel file .env
- Non creare nuovi container PostgreSQL — si usa SQLite
- Non modificare container o reti esistenti
