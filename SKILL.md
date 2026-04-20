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
| n8n | 5678 | orchestratore principale — volume /data montato su 03_database/ |
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
| 2 | Community node Signal in n8n + workflow base | ✅ FATTO | Workflow completo funzionante — vedi dettagli sotto |
| 3 | Database SQLite: schema completo | ✅ FATTO | 4 tabelle: task, messages_inbox, messages_outbox, system_settings |
| 4 | System prompt Claude | ✅ FATTO | System prompt Alfred integrato nel workflow — vedi dettagli sotto |
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

## Dettagli tecnici — n8n

### Nodo SQLite
n8n 2.4.6 non include il nodo SQLite nativo nei workflow.
SQLite è presente solo come database interno di n8n, non come nodo utilizzabile.
**Soluzione adottata:** nodo Code (JavaScript) con `require('sqlite3')`.

Variabili ambiente aggiunte al docker-compose di automation:
```yaml
- NODE_FUNCTION_ALLOW_EXTERNAL=sqlite3
- NODE_FUNCTION_ALLOW_BUILTIN=*
- N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE=true
```

### Volume database
Il database è montato nel container n8n come volume cartella:
- **Host:** `/home/cesare/progetti/segretario-ai/03_database`
- **Container:** `/data`
- **Permessi file .db:** 666

### Codice standard per accesso SQLite nei nodi Code
```javascript
const sqlite3 = require('sqlite3').verbose();
const db = new sqlite3.Database('/data/segretario.db');
// ... operazioni ...
db.close();
```

### Workflow "Segretario AI" — stato nodi
| Nodo | Tipo | Stato | Note |
|---|---|---|---|
| Signal Trigger | Community node | ✅ Funzionante | Credenziale: segretario_signal_cli:8080 |
| Salva in messages_inbox | Code (JS) | ✅ Funzionante | Deduplicazione per timestamp Signal |
| Chiama Claude API | HTTP Request | ✅ Funzionante | POST https://api.anthropic.com/v1/messages |
| Valuta needs_confirmation | IF | ✅ Funzionante | Branch true = chiedi conferma, false = rispondi |
| Invia risposta Signal | Code (JS) | ✅ Funzionante | Usa http.request nativo — vedi nota sotto |
| Salva in messages_outbox | Code (JS) | ⏳ Da costruire | |

### Invio messaggi Signal da n8n
Il nodo community Signal Send e il nodo HTTP Request danno entrambi errore 400
quando usati per inviare messaggi. **Soluzione adottata:** nodo Code (JS) con
`http.request` nativo di Node.js.

```javascript
const http = require('http');

const payload = JSON.stringify({
  message: testo,
  number: "+393517872627",       // numero mittente (account signal-cli)
  recipients: [destinatario]     // numero destinatario
});

const options = {
  hostname: 'segretario_signal_cli',
  port: 8080,
  path: '/v2/send',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Content-Length': Buffer.byteLength(payload)
  }
};

await new Promise((resolve, reject) => {
  const req = http.request(options, (res) => {
    let data = '';
    res.on('data', chunk => data += chunk);
    res.on('end', () => {
      if (res.statusCode === 200 || res.statusCode === 201) resolve(data);
      else reject(new Error(`Status ${res.statusCode}: ${data}`));
    });
  });
  req.on('error', reject);
  req.write(payload);
  req.end();
});
```

### System prompt Alfred
Il segretario si chiama **Alfred**. System prompt da usare nelle chiamate Claude API:
```
Sei Alfred, il segretario personale di Cesare Rizzo, dottore commercialista.
Rispondi sempre in italiano, tono professionale ma cordiale, dai del tu a Cesare.
Restituisci SOLO un oggetto JSON valido, senza backtick, senza markdown, senza
testo aggiuntivo prima o dopo. La struttura è sempre questa:
{"intent": "domanda_generica", "testo_risposta": "...", "needs_confirmation": false, "motivo_conferma": ""}
Gli intent possibili sono: crea_appuntamento, crea_task, lista_giornata,
completa_task, posticipa_task, snooze_oggi, domanda_generica.
```

### API key Anthropic nei workflow n8n
⚠️ MAI committare il JSON del workflow con la API key in chiaro.
GitHub Push Protection blocca il push automaticamente.
Prima di esportare e committare un workflow: sostituire la API key con il
placeholder `YOUR_ANTHROPIC_API_KEY_HERE`.

### Campi chiave dal payload Signal Trigger
```
item.messageText                        → testo del messaggio
item.envelope.timestamp                 → ID univoco messaggio (usato come signal_message_id)
item.envelope.source                    → numero mittente
item.sourceName                         → nome mittente
item.attachments                        → array allegati (vocali)
item.envelope.dataMessage.message       → testo alternativo
```

### Riferimento URL interno signal-cli
`http://segretario_signal_cli:8080` (nome container, porta interna Docker)

---

## Note operative
- Il file .db NON va su GitHub (già in .gitignore)
- I workflow n8n si esportano da UI → 02_n8n/workflows/
- Il system prompt è in 02_n8n/prompts/system-prompt.md
- Variabili sensibili (API key, OAuth) sempre e solo nel file .env
- Non creare nuovi container PostgreSQL — si usa SQLite
- Non modificare container o reti esistenti
