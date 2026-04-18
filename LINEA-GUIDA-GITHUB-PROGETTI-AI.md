# Linea Guida -- GitHub per Progetti AI su MiniPC
**Studio Rizzo -- Infrastruttura di Sviluppo**
*Versione 2.0 -- Aggiornata Aprile 2026*

---

## Premessa e obiettivo

Questa linea guida definisce lo standard operativo per tutti i nuovi progetti AI sviluppati sul MiniPC. L'obiettivo e' svincolare il lavoro di sviluppo dalla postazione fisica, mantenendo l'intera infrastruttura (Docker, PostgreSQL, servizi) sul MiniPC e portando su GitHub tutto cio' che serve per ricostruire, versionare e accedere al progetto da qualsiasi device.

**Principio fondamentale:**
> GitHub gestisce il **codice e la configurazione**. Il MiniPC gestisce i **dati e i servizi in esecuzione**.

**Riferimento primario infrastruttura:**
Questo documento e' complementare -- non alternativo -- a `WORKFLOW_PROGETTI.MD`, che resta il riferimento operativo principale per la realizzazione di nuovi progetti. In caso di conflitto tra i due documenti, `WORKFLOW_PROGETTI.MD` prevale.

---

## 1. Prerequisiti una-tantum

### 1.1 Sul MiniPC

Git e' gia' installato e configurato sull'infrastruttura Studio Rizzo. Verificare la configurazione con:

```bash
git config --global user.name
git config --global user.email
```

Se non configurato:

```bash
git config --global user.name "Cesare Rizzo"
git config --global user.email "cesare.rizzo.vi@gmail.com"
```

Altri prerequisiti gia' operativi:
- VS Code con estensione **Remote - SSH** (configurato)
- SSH server attivo sul MiniPC (gia' attivo)
- Claude Code installato sul MiniPC
- Node.js 22 via nvm (verificare sempre che sia la versione attiva: `node --version`)

**Nota Node.js:** Ubuntu Server ha Node.js 18 come versione di sistema. nvm e' configurato con Node.js 22. Prima di qualsiasi operazione `npm`, verificare:

```bash
node --version   # deve rispondere v22.x.x
nvm use 22       # se necessario
```

### 1.2 Su GitHub

- Account GitHub con repository **privati** (piano gratuito supporta repo privati illimitati)
- Autenticazione SSH configurata tra MiniPC e GitHub:

```bash
# Verificare se la chiave esiste gia'
ls ~/.ssh/id_ed25519.pub

# Se non esiste, generarla:
ssh-keygen -t ed25519 -C "cesare.rizzo.vi@gmail.com"
cat ~/.ssh/id_ed25519.pub
# Copiare l'output e aggiungerlo su GitHub -> Settings -> SSH Keys

# Testare la connessione:
ssh -T git@github.com
```

### 1.3 Su ogni device remoto (laptop, Windows PC)

- VS Code installato
- Estensione **Remote - SSH** installata
- Accesso al MiniPC configurato (vedere sezione 9)

---

## 2. Struttura standard di ogni repository

Ogni progetto deve rispettare questa struttura dalla prima inizializzazione:

```
nome-progetto/
|
+-- .gitignore                  # OBBLIGATORIO -- vedi sezione 3
+-- .env.example                # Template variabili d'ambiente (senza valori reali)
+-- .env                        # NON committato -- valori reali locali
|
+-- docker-compose.yml          # Definizione completa dei servizi
+-- Dockerfile                  # Dockerfile per immagine Next.js custom
|
+-- README.md                   # Descrizione progetto + istruzioni avvio rapido
+-- SKILL.md                    # Istruzioni per Claude Code (vedi sezione 10)
+-- STRUTTURA_[PROGETTO].MD     # Specifiche tecniche complete (vedi WORKFLOW_PROGETTI.MD)
|
+-- /src                        # Codice sorgente applicativo
|   +-- /app                    # Route e pagine Next.js (App Router)
|   +-- /api                    # Endpoint API (se presenti)
|   +-- /components             # Componenti React riutilizzabili
|   +-- /lib                    # Funzioni di utilita', helpers
|   +-- /generated              # Output Prisma -- NON modificare a mano
|       +-- /prisma             # Client Prisma generato (output path standard)
|
+-- /prisma                     # Schema e migration Prisma
|   +-- schema.prisma           # Definizione modelli e relazioni
|   +-- /migrations             # Migration generate automaticamente da Prisma
|
+-- /docs                       # Documentazione tecnica e funzionale
|   +-- architettura.md         # Diagramma servizi e flussi dati
|   +-- note-sviluppo.md        # Decisioni tecniche, TODO, problemi noti
|
+-- /scripts                    # Script operativi (non fanno parte dell'app)
    +-- apply_migration.sh      # Applica una migration manualmente
```

**Note importanti sulla struttura:**

- La cartella `/src/generated/prisma` contiene il client Prisma generato. Deve essere inclusa nel `.gitignore` parzialmente: i file generati non vanno committati, ma il percorso deve esistere.
- `STRUTTURA_[PROGETTO].MD` e' il documento di specifiche tecniche del progetto. Va redatto **prima** di scrivere codice (vedere `WORKFLOW_PROGETTI.MD` sezione 2).
- Non esiste una cartella `/migrations` manuale: con Prisma le migration sono gestite dallo strumento stesso nella cartella `/prisma/migrations`.

---

## 3. File `.gitignore` standard

Da copiare in ogni nuovo progetto senza modifiche, poi estendere se necessario:

```gitignore
# Variabili d'ambiente -- MAI su GitHub
.env
.env.local
.env.production
.env.*.local

# Next.js build output
.next/
out/

# Prisma client generato -- si rigenera con prisma generate
src/generated/

# Volumi Docker e dati persistenti
/data/
/volumes/
/pgdata/
/uploads/

# Backup database (gestiti da sistema Restic centralizzato)
/backup/
*.sql.gz
*.dump
*.sql

# Modelli AI (troppo pesanti)
/models/
*.gguf
*.bin

# Log applicativi
*.log
/logs/

# Dipendenze (si reinstallano)
node_modules/
__pycache__/
*.pyc
.venv/
venv/

# File di sistema
.DS_Store
Thumbs.db

# IDE
.vscode/settings.json
.idea/

# File temporanei
*.tmp
*.swp
```

**Attenzione -- `.env` vs `.env.local`:**
Docker non carica `.env.local`. Le variabili d'ambiente per i container Docker devono stare sempre nel file `.env` (o essere dichiarate esplicitamente in `docker-compose.yml` con la direttiva `env_file: .env`). Il file `.env.local` viene letto solo da Next.js in sviluppo locale fuori Docker -- non usarlo come fonte primaria di configurazione.

---

## 4. File `.env.example` -- standard

Questo file **va committato** su GitHub. Contiene la struttura delle variabili senza i valori reali. Serve a chiunque cloni il repo per sapere cosa configurare.

```dotenv
# ── Database PostgreSQL ────────────────────────────────────────
POSTGRES_HOST=[progetto]_postgres
POSTGRES_PORT=5432
POSTGRES_DB=nome_database
POSTGRES_USER=nome_utente
POSTGRES_PASSWORD=

# Porta host per il container PostgreSQL (consultare WORKFLOW_PROGETTI.MD sezione 11.1)
# Esempi assegnati: 5433 KronoHub, 5434 Spese Abbonamenti
DB_PORT=

# DATABASE_URL per Prisma (formato stringa di connessione)
DATABASE_URL=postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DB}

# ── Applicazione Next.js ───────────────────────────────────────
# Porta host (consultare WORKFLOW_PROGETTI.MD sezione 11.1 prima di sceglierla)
# Esempi assegnati: 3002 Caterina, 3003 KronoHub, 3004 Spese Abbonamenti, 3005 Tracker
APP_PORT=

# URL pubblico esposto da Cloudflare Tunnel
NEXTAUTH_URL=https://[subdomain].studiorizzo.it
NEXTAUTH_SECRET=

NODE_ENV=production

# ── Servizi esterni (se utilizzati) ───────────────────────────
# Decommentare solo se il progetto li usa
# OPENAI_API_KEY=
# N8N_WEBHOOK_URL=https://n8n.studiorizzo.it/webhook/...
```

---

## 5. `docker-compose.yml` -- template standard

Il template seguente e' allineato allo standard Studio Rizzo documentato in `WORKFLOW_PROGETTI.MD` sezione 13. In caso di aggiornamento di quel template, questo va aggiornato di conseguenza.

```yaml
# docker-compose.yml -- Template standard Studio Rizzo
# Sostituire tutti i valori tra [PARENTESI] con i valori effettivi
# Prima di scegliere le porte, consultare WORKFLOW_PROGETTI.MD sezione 11.1

services:

  # ── Database ──────────────────────────────────────────────────
  [progetto]_postgres:
    image: postgres:15
    container_name: [progetto]_postgres
    restart: always
    environment:
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ${POSTGRES_DB}
    volumes:
      - [progetto]_postgres_data:/var/lib/postgresql/data
    ports:
      - "192.168.1.50:${DB_PORT}:5432"  # accesso pgAdmin da LAN -- solo IP locale
      # MAI usare "[PORTA]:5432" senza bind IP (espone su 0.0.0.0)
    networks:
      - [progetto]_network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB}"]
      interval: 10s
      timeout: 5s
      retries: 5

  # ── Applicazione Next.js ──────────────────────────────────────
  [progetto]_nextjs:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: [progetto]_nextjs
    restart: always
    env_file: .env
    depends_on:
      [progetto]_postgres:
        condition: service_healthy
    environment:
      HOSTNAME: "0.0.0.0"   # CRITICO -- senza questo Next.js non risponde fuori container
      NODE_ENV: "production"
    ports:
      - "${APP_PORT}:3000"
    networks:
      - [progetto]_network               # rete privata per DB
      - automation_automation_network    # rete condivisa per Cloudflare Tunnel
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 1G
        reservations:
          cpus: '0.25'
          memory: 256M

# ── Reti ──────────────────────────────────────────────────────
networks:
  [progetto]_network:
    driver: bridge
  automation_automation_network:
    external: true   # rete esistente -- NON dichiararla come nuova

# ── Volumi ────────────────────────────────────────────────────
volumes:
  [progetto]_postgres_data:
    driver: local
```

**Note critiche sul template:**

1. **PostgreSQL versione 15** -- non usare versioni superiori. Il sistema di backup (`pg_dump`) e' calibrato su PostgreSQL 15.
2. **`HOSTNAME: "0.0.0.0"`** -- obbligatorio nel blocco `environment` del servizio Next.js. Senza questa riga, il server Next.js rimane in ascolto solo su `localhost` dentro il container e Cloudflare Tunnel non lo raggiunge.
3. **Porta DB con bind IP** -- usare sempre `"192.168.1.50:${DB_PORT}:5432"` e mai `"${DB_PORT}:5432"`. La forma senza IP espone il database su tutte le interfacce di rete.
4. **`automation_automation_network`** -- questa rete esterna deve essere dichiarata come `external: true`. E' la rete attraverso cui il container `cloudflared` raggiunge l'applicazione.
5. **`env_file: .env`** -- Docker non carica `.env.local`. Assicurarsi che tutte le variabili necessarie siano nel file `.env`.

---

## 6. Schema Prisma -- configurazione standard

### 6.1 Schema base

```prisma
// prisma/schema.prisma

generator client {
  provider      = "prisma-client-js"
  output        = "../src/generated/prisma"    // percorso fisso -- non modificare
  binaryTargets = ["native", "linux-musl-openssl-3.0.x"]  // necessario per Alpine Docker
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}
```

### 6.2 Regole Prisma per questo stack

- **Output path**: sempre `../src/generated/prisma`. Non usare il percorso di default.
- **binaryTargets**: dichiarare sempre entrambi i target. Senza `linux-musl-openssl-3.0.x` il container Alpine crasha a runtime.
- **Versione bloccata**: usare Prisma `5.22.0`. Non aggiornare a Prisma 7 -- introduce breaking change nell'API incompatibili con il codice esistente.
- **Relazioni one-to-one**: i campi FK richiedono `@unique` per le relazioni uno-a-uno.

**In `package.json`, bloccare esplicitamente la versione:**

```json
{
  "dependencies": {
    "@prisma/client": "5.22.0"
  },
  "devDependencies": {
    "prisma": "5.22.0"
  }
}
```

### 6.3 Comandi Prisma essenziali

```bash
# Generare il client dopo ogni modifica allo schema
npx prisma generate

# Applicare lo schema al database (sviluppo)
npx prisma db push

# Creare una migration formale (produzione)
npx prisma migrate dev --name descrizione_modifica

# Aprire Prisma Studio per ispezionare i dati
npx prisma studio
```

---

## 7. Gestione porte -- regola fondamentale

**Prima di assegnare qualsiasi porta a un nuovo progetto, consultare `WORKFLOW_PROGETTI.MD` sezione 11.1 (Mappa Porte).**

Questo e' il passo piu' importante della pianificazione: un conflitto di porta non viene rilevato fino al momento del deploy e causa il fallimento dell'avvio.

**Porte gia' assegnate (stato attuale):**

| Porta host | Servizio |
|------------|---------|
| 3000 | WAHA tel1 |
| 3001 | WAHA tel2 |
| 3002 | Gestionale Caterina (Next.js) |
| 3003 | KronoHub (Next.js) |
| 3004 | Spese Abbonamenti (Next.js) |
| 3005 | Tracker Abbonamenti (Next.js) |
| 3006 | Prima porta libera (Next.js) |
| 5433 | KronoHub (PostgreSQL) |
| 5434 | Spese Abbonamenti (PostgreSQL) |

**Procedura corretta:**

```bash
# 1. Consultare la mappa in WORKFLOW_PROGETTI.MD sezione 11.1
# 2. Scegliere la prima porta libera
# 3. Verificare che sia effettivamente libera sul sistema
sudo ss -tlnp | grep [PORTA_SCELTA]

# 4. Aprire la porta sul firewall UFW
sudo ufw allow [PORTA_SCELTA]/tcp

# 5. Dopo il deploy, aggiornare la mappa in WORKFLOW_PROGETTI.MD
```

---

## 8. Backup -- integrazione con sistema centralizzato

### 8.1 Sistema gia' operativo

Il MiniPC ha un sistema di backup centralizzato e automatizzato (`backup-automation.sh`) che gestisce:
- Backup giornaliero notturno di tutta la cartella `~/progetti/`
- `pg_dump` automatico di tutti i database PostgreSQL
- Doppia destinazione: QNAP NAS (7 giorni) + Backblaze B2 (30 giorni + versioni settimanali/mensili)
- Notifica email in caso di errore

**Non creare script di backup per-progetto.** Tutto viene gestito centralmente.

### 8.2 Cosa fare per un nuovo progetto

L'unica azione richiesta e' aggiungere il nuovo database allo script centralizzato. Vedere `CONFIGURAZIONE_BACKUP_QNAP_NAS.md` per la procedura dettagliata.

In sintesi:

```bash
# Aprire lo script centralizzato
nano ~/backup-automation.sh

# Aggiungere il dump del nuovo DB nell'array o sezione dedicata
# (seguire il pattern dei DB gia' presenti)

# Testare manualmente il backup
~/backup-automation.sh
```

### 8.3 Script di restore (per emergenza)

```bash
# Restore da un dump pg_dump esistente
# I dump si trovano in ~/progetti/db-backups/

# Identificare il file corretto
ls ~/progetti/db-backups/

# Restore
docker exec -i [progetto]_postgres psql -U [db_user] [db_name] < /percorso/dump.sql
```

---

## 9. Accesso remoto -- VS Code Remote SSH

### 9.1 Da rete locale (LAN)

Configurazione `~/.ssh/config` sul laptop/PC Windows:

```
Host minipc
    HostName 192.168.1.50
    User cesare
    IdentityFile ~/.ssh/id_ed25519
```

In VS Code: `F1` --> `Remote-SSH: Connect to Host` --> `minipc`

### 9.2 Da rete esterna (fuori LAN)

**Usare Tailscale**, non l'IP LAN. L'IP LAN (192.168.1.50) non e' raggiungibile da fuori rete locale.

```
Host minipc-tailscale
    HostName 100.124.163.105
    User cesare
    IdentityFile ~/.ssh/id_ed25519
```

Tailscale deve essere attivo sia sul MiniPC sia sul device remoto. Per verificare lo stato:

```bash
tailscale status
```

### 9.3 Comportamento dell'ambiente su VS Code Remote SSH

Quando ci si connette al MiniPC via VS Code Remote SSH:
- Claude Code e' disponibile direttamente nel terminale integrato
- Docker e tutti i container sono accessibili
- Il filesystem e' quello reale del MiniPC (`~/progetti/`)
- Node.js va verificato manualmente (`node --version`) -- potrebbe risultare attiva la versione di sistema (18) invece di quella nvm (22)

---

## 10. File `SKILL.md` -- template per Claude Code

Il file `SKILL.md` nella root del progetto fornisce a Claude Code il contesto necessario per assistere nello sviluppo senza doverlo rispiegare ogni sessione. E' uno dei file piu' importanti dell'intero repository.

**Template minimo:**

```markdown
# SKILL.md -- Contesto progetto per Claude Code
## [Nome Progetto]

### Scopo del progetto
[Descrizione in 2-3 righe di cosa fa l'applicazione]

### Stack tecnico
- Next.js 15 (App Router)
- PostgreSQL 15 (container Docker: [progetto]_postgres)
- Prisma 5.22.0 (output: src/generated/prisma)
- NextAuth.js 5 beta
- Tailwind CSS v4
- shadcn/ui
- Node.js 22

### Porte assegnate
- Applicazione: [PORTA_APP] (host) --> 3000 (container)
- Database: [PORTA_DB] (host) --> 5432 (container)

### Subdomain pubblico
https://[subdomain].studiorizzo.it

### Struttura database principale
[Elencare le tabelle principali con i campi piu' significativi]

### Convenzioni di questo progetto
[Eventuali scelte specifiche: naming, pattern usati, dipendenze particolari]

### File di riferimento
- STRUTTURA_[PROGETTO].MD -- specifiche tecniche complete
- docker-compose.yml -- definizione servizi
- prisma/schema.prisma -- schema database

### Errori noti e soluzioni
[Riportare qui gli errori specifici di questo progetto con la soluzione adottata]
```

---

## 11. Configurazione Cloudflare Tunnel e Access

Ogni nuovo progetto deve essere esposto pubblicamente via Cloudflare Tunnel su un sottodominio `*.studiorizzo.it`. **Nessuna porta viene mai esposta direttamente su Internet.**

### 11.1 Prerequisiti

- Il container dell'applicazione deve essere collegato alla rete `automation_automation_network` (rete esterna condivisa con il container `cloudflared`)
- Il container deve avere `HOSTNAME: "0.0.0.0"` nella configurazione environment

### 11.2 Aggiungere un Public Hostname su Cloudflare

1. Accedere a [dash.cloudflare.com](https://dash.cloudflare.com)
2. Navigare in: **Zero Trust** --> **Networks** --> **Tunnels**
3. Selezionare il tunnel `studiorizzo-services`
4. Tab **Public Hostnames** --> **Add a public hostname**
5. Compilare:
   - **Subdomain:** `[nome-progetto]`
   - **Domain:** `studiorizzo.it`
   - **Service Type:** `HTTP`
   - **URL:** `[progetto]_nextjs:3000` (nome container, non localhost)
6. Salvare

Il DNS su Cloudflare viene aggiornato automaticamente. Attendere qualche minuto per la propagazione.

### 11.3 Verificare il funzionamento

```bash
# Dal MiniPC, testare che Cloudflare raggiunga il container
curl -I https://[subdomain].studiorizzo.it

# Verificare che il container sia sulla rete corretta
docker inspect [progetto]_nextjs | grep -A 20 "Networks"
```

### 11.4 Proteggere con Cloudflare Access (opzionale ma consigliato)

Per applicazioni che non devono essere pubblicamente accessibili senza autenticazione:

1. **Zero Trust** --> **Access** --> **Applications** --> **Add an application**
2. Tipo: **Self-hosted**
3. **Application domain:** `[subdomain].studiorizzo.it`
4. **Policy:** Allow -- Email -- `cesare.rizzo.vi@gmail.com` (OTP via email)

Per permettere chiamate non autenticate a endpoint specifici (es. webhook):

1. Aggiungere una seconda policy di tipo **Bypass**
2. Regola: **Everyone**
3. **Path:** `/webhook/*` (o il percorso specifico)

---

## 12. Flusso Git -- operatività quotidiana

### 12.1 Primo avvio di un nuovo progetto

```bash
# 1. Creare la cartella progetto sul MiniPC (percorso corretto)
mkdir ~/progetti/nome-progetto && cd ~/progetti/nome-progetto

# 2. Inizializzare Git
git init
git branch -M main

# 3. Creare il repo su GitHub (privato) tramite interfaccia web GitHub
#    oppure con GitHub CLI: gh repo create nome-progetto --private

# 4. Collegare il repo remoto
git remote add origin git@github.com:cesare-rizzo/nome-progetto.git

# 5. Creare la struttura base (vedi sezione 2), poi:
git add .
git commit -m "chore: struttura iniziale progetto"
git push -u origin main
```

### 12.2 Convenzione messaggi di commit

| Prefisso | Quando usarlo |
|----------|--------------|
| `feat:` | Nuova funzionalita' |
| `fix:` | Correzione bug |
| `chore:` | Manutenzione, config, dipendenze |
| `docs:` | Documentazione |
| `db:` | Migration o modifica schema Prisma |
| `refactor:` | Ristrutturazione codice senza cambi funzionali |
| `style:` | Modifiche CSS/UI senza impatti funzionali |

Esempi:

```bash
git commit -m "feat: aggiunta pagina lista pagamenti"
git commit -m "db: aggiunta colonna note alla tabella clienti"
git commit -m "fix: correzione calcolo importo mensile abbonamenti"
git commit -m "docs: aggiornato SKILL.md con schema tabelle"
```

### 12.3 Frequenza consigliata

Committare **almeno al termine di ogni sessione di lavoro**, anche se la feature non e' completa. Un commit incompleto con messaggio `fix: WIP` vale piu' di nessun commit.

---

## 13. Cosa NON mettere mai su GitHub

| Categoria | Esempi |
|-----------|--------|
| Credenziali e segreti | `.env`, password, API key, token, NEXTAUTH_SECRET |
| Dati di clienti | Qualsiasi documento, anagrafica, elaborazione |
| Volumi Docker | Cartelle `pgdata/`, `data/`, `uploads/` |
| Backup database | File `.sql`, `.dump`, `.sql.gz` |
| Modelli AI | File `.gguf`, `.bin`, pesi di modelli |
| Client Prisma generato | Cartella `src/generated/` |
| Build Next.js | Cartella `.next/` |
| File pesanti | Dataset, PDF, immagini di grandi dimensioni |

**Regola pratica:** se un file contiene informazioni che non puoi mostrare a uno sconosciuto, non va su GitHub -- nemmeno su repo privato.

---

## 14. Checklist nuovo progetto

Da eseguire nell'ordine indicato prima di scrivere la prima riga di codice.

### Pianificazione

- [ ] Consultare `WORKFLOW_PROGETTI.MD` sezione 11.1 per scegliere porta app disponibile
- [ ] Consultare `WORKFLOW_PROGETTI.MD` sezione 11.1 per scegliere porta DB disponibile
- [ ] Scegliere il sottodominio `[nome].studiorizzo.it`
- [ ] Redigere `STRUTTURA_[PROGETTO].MD` con tutte le specifiche tecniche

### Setup repository

- [ ] Creare cartella `~/progetti/nome-progetto` sul MiniPC
- [ ] Copiare `.gitignore` standard (sezione 3)
- [ ] Creare `.env.example` con tutte le variabili previste
- [ ] Creare `.env` con i valori reali (non committato)
- [ ] Scrivere `docker-compose.yml` con servizi app + db (template sezione 5)
- [ ] Configurare `prisma/schema.prisma` (sezione 6)
- [ ] Scrivere `README.md` con: descrizione, prerequisiti, istruzioni avvio
- [ ] Scrivere `SKILL.md` con il contesto per Claude Code (template sezione 10)
- [ ] `git init` + collegamento repo GitHub privato
- [ ] Primo commit e push

### Deploy e verifica

- [ ] `docker compose build` eseguita senza errori
- [ ] `docker compose up -d` avviato correttamente
- [ ] `docker compose ps` -- tutti i container in stato `running`
- [ ] `npx prisma db push` applicato sul container DB
- [ ] Accesso locale verificato: `http://192.168.1.50:[PORTA]`
- [ ] Porta UFW aperta: `sudo ufw allow [PORTA]/tcp`

### Cloudflare

- [ ] Public Hostname aggiunto su Cloudflare Tunnel (sezione 11.2)
- [ ] DNS propagato -- test: `curl -I https://[subdomain].studiorizzo.it`
- [ ] Cloudflare Access configurato se richiesto (sezione 11.4)
- [ ] Accesso HTTPS pubblico verificato

### Backup e documentazione finale

- [ ] Nuovo DB aggiunto allo script di backup centralizzato (`backup-automation.sh`)
- [ ] Backup manuale eseguito e verificato
- [ ] `WORKFLOW_PROGETTI.MD` sezione 11.1 (Mappa Porte) aggiornata
- [ ] `WORKFLOW_PROGETTI.MD` sezione 11.2 (Mappa Subdomain) aggiornata
- [ ] `CONFIGURAZIONE_MINIPC.MD` aggiornato (container, porte, subdomain)
- [ ] Credenziali salvate nel password manager

---

## 15. Log modifiche documento

| Versione | Data | Autore | Modifiche |
|----------|------|--------|-----------|
| 1.0 | Gen 2026 | Cesare + Claude AI | Prima versione |
| 2.0 | Apr 2026 | Cesare + Claude AI | Allineamento infrastruttura reale: PostgreSQL 15, porte variabili, backup centralizzato Restic, Tailscale, Cloudflare Tunnel, stack Prisma, SKILL.md template, percorsi corretti |

---

*Fine documento -- v2.0*
*Da aggiornare ogni volta che l'infrastruttura evolve. In caso di conflitto con `WORKFLOW_PROGETTI.MD`, quest'ultimo prevale.*
