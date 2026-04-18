# SKILL.md — Contesto progetto per Claude Code
## Segretario AI

### Scopo del progetto
Assistente personale AI accessibile via Signal (voce e testo).
Gestisce calendari (Outlook + Google), task con solleciti proattivi
ed escalation, e invia un briefing mattutino vocale giornaliero.

### Stack tecnico
- n8n (già in esecuzione su Docker)
- signal-cli-rest-api (Docker, porta 8085)
- Claude API — modello Sonnet
- Whisper API (OpenAI) — STT
- Edge TTS (Microsoft) — TTS
- SQLite — database locale
- Microsoft Graph API — Outlook Calendar
- Google Calendar API — calendario privato

### Struttura cartelle
- 01_infra/       → docker-compose.yml, config signal-cli
- 02_n8n/         → workflow JSON esportati da n8n, system prompt
- 03_database/    → schema.sql, file .db (non committato)
- 04_docs/        → guide operative
- 05_test/        → scenari di test

### Note operative
- Il file .db NON va su GitHub (già in .gitignore)
- I workflow n8n si esportano da UI e si salvano in 02_n8n/workflows/
- Il system prompt è in 02_n8n/prompts/system-prompt.md
- Variabili sensibili (API key, OAuth) sempre e solo nel file .env
