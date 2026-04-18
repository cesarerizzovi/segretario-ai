# SKILL.md — Contesto progetto per Claude Code
## Segretario AI

### Scopo del progetto
Assistente personale AI accessibile via Signal (voce e testo).
Gestisce calendari (Outlook + Google), task con solleciti proattivi
ed escalation, e invia un briefing mattutino vocale giornaliero.

### Stack tecnico
- n8n (già in esecuzione su Docker, porta 5678)
- signal-cli-rest-api (Docker, porta 8085) — da aggiungere
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

### Porte disponibili per questo progetto
- 8085 → signal-cli-rest-api
- Nessuna porta Next.js necessaria (no frontend)
- Nessuna porta PostgreSQL necessaria (SQLite locale)

### Reti Docker
- **automation_automation_network** — rete condivisa con n8n e
  cloudflared. signal-cli-rest-api deve essere su questa rete.
- La rete privata interna del progetto: segretario_network

### Struttura cartelle
- 01_infra/       → docker-compose.yml, config signal-cli
- 02_n8n/         → workflow JSON esportati da n8n, system prompt
- 03_database/    → schema.sql, file .db (non committato)
- 04_docs/        → guide operative
- 05_test/        → scenari di test

### Principio architetturale chiave
"AI propone, logica esegue": Claude restituisce JSON con campo
needs_confirmation (true/false). È n8n a decidere se eseguire
o chiedere conferma all'utente, mai il modello.

### Note operative
- Il file .db NON va su GitHub (già in .gitignore)
- I workflow n8n si esportano da UI → 02_n8n/workflows/
- Il system prompt è in 02_n8n/prompts/system-prompt.md
- Variabili sensibili (API key, OAuth) sempre e solo nel file .env
- Non creare nuovi container PostgreSQL — si usa SQLite
- Non modificare container o reti esistenti
