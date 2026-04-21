# CONFIGURAZIONE MINI PC SERVER

**Data creazione:** 9 Febbraio 2026
**Responsabile:** Cesare
**Versione:** 2.9
**Ultimo aggiornamento:** 21 Aprile 2026
**Scopo:** Documento di riferimento infrastruttura per sviluppo nuovi progetti

---

## 1. PANORAMICA SISTEMA

### 1.1 Descrizione Generale

Sistema server domestico basato su Mini PC dedicato, operativo 24/7 per hosting applicazioni Docker, automazioni workflow e servizi cloud accessibili pubblicamente via dominio professionale. L'infrastruttura e' progettata per scalabilita', sicurezza multi-livello e disaster recovery completo.

**Caratteristiche principali:**
- Hardware dedicato con alte prestazioni
- Sistema operativo server Linux (Ubuntu LTS)
- Containerizzazione completa (Docker)
- Accesso pubblico HTTPS tramite Cloudflare Tunnel
- Backup automatico dual-repository (locale + cloud)
- Accesso amministrazione privato via VPN
- Storage ridondante RAID 1

---

## 2. HARDWARE

### 2.1 Specifiche Mini PC

**Modello:** MINISFORUM Mini PC NAB6 Lite

**Componenti:**
```
CPU: Intel Core i5-12600H
  - 12 core / 16 thread
  - Base: 2.1 GHz, Turbo: 4.5 GHz
  - TDP: 45W
  - Cache: 18 MB

RAM: 32 GB DDR4
  - Velocita': 3200 MHz
  - Dual channel
  - Espandibile fino a 64 GB

Storage: 500 GB SSD PCIe 4.0 NVMe
  - Lettura: ~7000 MB/s
  - Scrittura: ~5000 MB/s
  - Partizionato LVM (flessibile)

Rete:
  - 2x RJ45 2.5 Gigabit LAN
  - WiFi 6 (802.11ax)
  - Bluetooth 5.2

Porte I/O:
  - 7x USB (3.2 Gen 2 + 2.0)
  - 2x HDMI 2.0
  - 1x Audio jack 3.5mm
  - 1x Lettore SD card
```

**Consumo energetico:**
```
Idle: ~15W
Carico medio: ~25W
Carico massimo: ~40W
Costo elettrico: ~60-90 EUR/anno
```

### 2.2 Storage NAS Backup

**Modello:** QNAP TS-219P+

**Specifiche:**
```
CPU: ARM-based (Marvell)
RAM: 512 MB
Dischi: 2x WDC 3TB in RAID 1
Capacita' netta: 2.8 TB
File system: EXT4
Rete: 1x Gigabit Ethernet
IP: 192.168.1.100
```

**Configurazione RAID:**
```
Tipo: RAID 1 (mirroring)
Protezione: 1 disco puo' guastarsi senza perdita dati
Rebuild automatico su sostituzione disco
```

---

## 3. SISTEMA OPERATIVO

### 3.1 Ubuntu Server

**Distribuzione:**
```
OS: Ubuntu Server 24.04 LTS (Noble Numbat)
Kernel: Linux 6.8.x
Architettura: x86_64 (amd64)
Supporto LTS: fino ad Aprile 2029 (5 anni)
```

**Configurazione sistema:**
```
Hostname: server-miniPC
Username amministratore: cesare
Home directory: /home/cesare
Timezone: Europe/Rome
Locale: it_IT.UTF-8
```

### 3.2 Partizionamento Disco

**Schema LVM:**
```
/dev/sda (500 GB SSD)
|-- /boot/efi (1 GB, fat32)
|-- /boot (2 GB, ext4)
|-- / (100 GB, ext4)        --> Sistema + Docker
+-- LVM Volume Group (373 GB)
    +-- ubuntu-lv (espandibile al volo)
```

**Utilizzo storage:**
```
Sistema operativo:  ~4 GB
Docker images:      ~15 GB
Progetti:           ~5 GB
Backup logs:        ~500 MB
Disponibile:        ~350 GB (LVM)
```

---

## 4. NETWORKING

### 4.1 Configurazione Rete Locale

**Interfaccia primaria:**
```
Device: enp1s0 (Ethernet 2.5G)
IP statico: 192.168.1.50
Netmask: 255.255.255.0 (/24)
Gateway: 192.168.1.1 (router)
DNS primario: 192.168.1.1
DNS secondario: 8.8.8.8 (Google)
MTU: 1500
```

**Switch di rete:**
```
Modello: TP-Link TL-SG1008D
Porte: 8x Gigabit Ethernet
Connessioni attive:
  - Mini PC (port 1)
  - NAS QNAP (port 2)
  - Router (uplink)
```

### 4.2 Tailscale VPN (Accesso Privato)

**Configurazione:**
```
IP VPN: 100.124.163.105
Hostname VPN: server-miniPC
Subnet: 100.64.0.0/10 (CGNAT)
Protocollo: WireGuard
Crittografia: end-to-end
```

**Account:**
```
Provider: Tailscale (piano Free)
Autenticazione: Account Google/GitHub
Limite dispositivi: 100 (gratuiti)
```

**Dispositivi autorizzati:**
```
- server-miniPC (questo server)
- PC ufficio Cesare
- Smartphone (amministrazione mobile)
```

**Usi VPN:**
- Amministrazione server (SSH, Portainer, Dockge)
- Accesso diretto container (sviluppo/debug)
- Gestione WAHA WhatsApp
- Accesso NAS (alternativa a SMB pubblico)

### 4.3 Cloudflare Tunnel (Accesso Pubblico)

**Dominio:** studiorizzo.it

**Configurazione DNS:**
```
Registrar: Flazio Srl
Nameserver: Cloudflare
  - harleigh.ns.cloudflare.com
  - hunts.ns.cloudflare.com
Scadenza dominio: 13 Novembre 2026
```

**Cloudflare Account:**
```
Email: cesare.rizzo.vi@gmail.com
Piano: Free (0 EUR/mese)
Team Zero Trust: studio-rizzo
```

**Tunnel configurato:**
```
Nome: studiorizzo-services
Tunnel ID: 3d3bea8e-ab94-4cee-9105-0486360b74bf
Status: HEALTHY [OK]
Connessioni: 4 attive (ridondanza)
Protocollo: HTTP/2 cifrato
```

**Public Hostname attivi:**
```
https://n8n.studiorizzo.it
  --> Container: n8n (porta 5678)
  --> Protocollo interno: HTTP
  --> Protocollo esterno: HTTPS (certificato SSL automatico)
  --> Protezione: Cloudflare Access (autenticazione email)

https://gestionale-caterina.studiorizzo.it
  --> Container: gestionale-caterina (porta 3002)
  --> Protocollo interno: HTTP
  --> Protocollo esterno: HTTPS (certificato SSL automatico)
  --> Protezione: Nessuna (pubblico)
  --> Status: ATTIVO dal 13 Febbraio 2026

https://trasferte.studiorizzo.it
  --> Container: trasferte-app (porta 3006)
  --> Protocollo interno: HTTP
  --> Protocollo esterno: HTTPS (certificato SSL automatico)
  --> Protezione: Nessuna (accesso con login applicativo)
  --> Status: ATTIVO dal 15 Marzo 2026

https://cantinetta.studiorizzo.it
  --> Container: cantinetta_nextjs (porta 3007)
  --> Protocollo interno: HTTP
  --> Protocollo esterno: HTTPS (certificato SSL automatico)
  --> Protezione: Login applicativo (NextAuth.js 5 — ruoli Admin/Membro)
  --> Status: ATTIVO dal 06 Aprile 2026
```

**Cloudflare Access:**
```
Applicazione: n8n Production
Session duration: 24 ore
Policy: Admin Access Only
  - Email whitelistata: cesare.rizzo.vi@gmail.com
  - Autenticazione: OTP via email
Bypass pubblico: /rest/oauth2-credential/callback (OAuth)
```

### 4.4 Firewall (UFW)

**Status:** ATTIVO

**Regole configurate:**
```
22/tcp    --> SSH (amministrazione)
3000/tcp  --> WAHA Tel1 (WhatsApp HTTP API)
3001/tcp  --> WAHA Tel2 (WhatsApp HTTP API)
3002/tcp  --> Gestionale Caterina Next.js
3006/tcp  --> Gestione Trasferte Next.js
3007/tcp  --> Cantinetta Wine Cellar Manager
5001/tcp  --> Dockge (gestione stack Docker Compose)
5435/tcp  --> PostgreSQL Trasferte (solo da 192.168.1.50)
5436/tcp  --> PostgreSQL Cantinetta (solo da 192.168.1.50)
5678/tcp  --> n8n automation
8080/tcp  --> pgAdmin (gestione PostgreSQL)
9000/tcp  --> Portainer web UI
9443/tcp  --> Portainer HTTPS
```

**Policy di default:**
```
Incoming: DENY (tutto bloccato di default)
Outgoing: ALLOW (traffico in uscita permesso)
Routed: DENY
```

**Note sicurezza:**
- Nessuna porta esposta pubblicamente su router
- Traffico pubblico solo via Cloudflare Tunnel (outbound)
- SSH accessibile solo da rete locale o Tailscale

---

## 5. DOCKER

### 5.1 Installazione

**Versione:**
```
Docker Engine: 27.4.1
Docker Compose: v2.30.3
Installazione: Repository ufficiale Docker
```

**Configurazione:**
```
Socket: /var/run/docker.sock
Directory dati: /var/lib/docker
Storage driver: overlay2
Logging driver: json-file (max 10MB, 3 file)
```

**Permessi:**
```
User cesare membro gruppo docker
Comando docker senza sudo: [OK]
```

### 5.2 Network Docker

**Network predefinite:**
```
bridge (default)
host
none
```

**[ATTENZIONE] PROBLEMA "DOPPIO NOME" AUTOMATION_AUTOMATION_NETWORK**

Esistono due reti Docker con nomi simili:

1. **`automation_network`** (NOME CORRETTO - IN USO)
   - Creata dal progetto `~/progetti/automation/`
   - Contiene: n8n, WAHA, cloudflared, servizi_postgres, pgadmin
   - Tutti i container Next.js che devono essere raggiungibili da cloudflared
     DEVONO essere su questa rete (fix del 21/04/2026)

2. **`automation_automation_network`** (RETE SECONDARIA — DA NON USARE NEI NUOVI PROGETTI)
   - Creata per errore in passato (prefisso doppio da Docker Compose)
   - Ancora presente per compatibilita' con container esistenti
   - NON usarla nei nuovi docker-compose.yml — usare sempre automation_network

**REGOLA CRITICA — docker-compose.yml del progetto automation:**
```yaml
# [OK] CORRETTO — automation deve dichiarare la rete come external
networks:
  automation_network:
    external: true

# [ERRORE] SBAGLIATO — NON usare driver: bridge in automation
# Causa: Docker Compose aggiungerebbe il prefisso "automation_"
# e ricreerebbe la rete come automation_automation_network
# Al riavvio i container finirebbero sulla rete sbagliata
networks:
  automation_network:
    driver: bridge
```

**Problemi verificati:**

20/04/2026 — n8n si e' riavviato ed e' finito su automation_automation_network
invece di automation_network, perdendo la visibilita' verso servizi_postgres.
Errore: getaddrinfo EAI_AGAIN servizi_postgres nei workflow n8n.
Fix: docker network connect automation_network n8n

21/04/2026 — cantinetta_nextjs e spese_nextjs non raggiungibili da cloudflared
(errore: dial tcp: lookup cantinetta_nextjs ... server misbehaving).
Causa: docker-compose.yml di cantinetta usava automation_automation_network
invece di automation_network. Fix permanente: corretto docker-compose.yml
di cantinetta con automation_network; collegato spese_nextjs manualmente
(manca docker-compose.yml trovabile — da risolvere).
Fix applicato: docker network connect automation_network cantinetta_nextjs
              docker network connect automation_network spese_nextjs

**REGOLA D'ORO PER NUOVI PROGETTI:**
```yaml
# [OK] CORRETTO - Usa SEMPRE automation_network nei docker-compose.yml
# Vale per TUTTI i container Next.js che devono essere raggiungibili
# da cloudflared O da n8n O da servizi_postgres
networks:
  automation_network:
    external: true

# [ERRORE] SBAGLIATO - NON usare automation_automation_network
# E' una rete creata per errore, non e' la rete principale
networks:
  automation_automation_network:
    external: true
```

**Come verificare su quale rete e' un container:**
```bash
docker inspect NOME_CONTAINER | grep -A 5 "Networks"
```

**Come verificare quali container sono su una rete:**
```bash
docker network inspect automation_network | grep -A 3 "Containers"
```

**Network custom progetto automation:**
```
Nome: automation_network
Driver: bridge
Subnet: 172.18.0.0/16 (auto-assegnato)
Gateway: 172.18.0.1
Container collegati:
  - n8n
  - waha_tel1
  - waha_tel2
  - cloudflared
  - servizi_postgres (PostgreSQL)
  - pgadmin
```

**Network custom progetto gestionale:**
```
Nome: gestionale_network
Driver: bridge
Subnet: 172.19.0.0/16 (auto-assegnato)
Gateway: 172.19.0.1
Container collegati:
  - gestionale-caterina
```

**Network custom progetto trasferte:**
```
Nome: trasferte_network
Driver: bridge
Container collegati:
  - trasferte-app
  - trasferte-db (PostgreSQL dedicato)
```

**MAPPA RETI DOCKER:**
```
+-----------------------------------------------------------+
| automation_network (172.18.0.0/16)                        |
|  +-----------+  +------------+  +------------+            |
|  |   n8n     |  | waha_tel1  |  | waha_tel2  |            |
|  |  :5678    |  |   :3000    |  |   :3001    |            |
|  +-----------+  +------------+  +------------+            |
|                                                            |
|  +------------+  +------------------+  +-----------+      |
|  | cloudflared|  | servizi_postgres  |  | pgadmin   |     |
|  |            |  |     :5432         |  |   :8080   |     |
|  +------------+  +------------------+  +-----------+      |
+-----------------------------------------------------------+

+-----------------------------------------------------------+
| gestionale_network (172.19.0.0/16)                        |
|  +----------------------+                                  |
|  | gestionale-caterina  |                                  |
|  |       :3002          |                                  |
|  +----------------------+                                  |
|          |                                                  |
|          +--- bridge ---> automation_network               |
|               (per accesso a servizi_postgres)             |
+-----------------------------------------------------------+

+-----------------------------------------------------------+
| trasferte_network                                          |
|  +----------------+  +----------------+                   |
|  | trasferte-app  |  | trasferte-db   |                   |
|  |    :3000       |  |    :5432       |                   |
|  +----------------+  +----------------+                   |
|          |                                                  |
|          +--- bridge ---> automation_network               |
|               (per accesso a cloudflared)                  |
+-----------------------------------------------------------+
```

---

## 6. CONTAINER ATTIVI

### 6.1 Portainer (Gestione Docker)

**Configurazione:**
```
Image: portainer/portainer-ce:latest
Container name: portainer
Restart policy: always
Ports:
  - 9000:9000 (HTTP)
  - 9443:9443 (HTTPS)
Volume: portainer_data
```

**Accesso:**
```
Locale:    http://192.168.1.50:9000
Tailscale: http://100.124.163.105:9000
```

**Credenziali:** [Password manager]

---

### 6.2 Dockge (Gestione Stack Docker Compose)

**Directory installazione:** `/opt/dockge`
**Directory stack:** `/opt/stacks`

**Configurazione:**
```
Image: louislam/dockge:1
Container name: dockge
Restart policy: unless-stopped
Ports:
  - 5001:5001
Volumes:
  - /var/run/docker.sock:/var/run/docker.sock
  - /opt/dockge/data:/app/data
  - /opt/stacks:/opt/stacks
Environment:
  - DOCKGE_STACKS_DIR=/opt/stacks
```

**Accesso:**
```
Locale:    http://192.168.1.50:5001
Tailscale: http://100.124.163.105:5001
```

**Note operative:**
- Dockge NON supporta connessione a Docker Engine remoto (no architettura agent/server)
- Installato direttamente sul miniPC, accesso via browser da Windows
- Gestisce esclusivamente stack Compose salvati in `/opt/stacks/`
- I progetti esistenti in `~/progetti/` restano gestiti tramite Portainer o CLI
- Per aggiungere un progetto esistente: spostare il docker-compose.yml in `/opt/stacks/[nome-stack]/`

**Differenza con Portainer:**
```
Portainer --> gestione completa container, immagini, volumi, reti
             funziona con qualsiasi container Docker

Dockge    --> focalizzato sulla gestione stack Compose
             interfaccia piu' semplice per file docker-compose.yml
             gli stack devono risiedere in /opt/stacks/
```

**Gestione directory:**
```
Proprieta': cesare:cesare
Comando verifica: ls -la /opt/
```

**Status:**
```
Installato: 12 Marzo 2026
Container: Running [OK]
Accesso web: Funzionante [OK]
```

---

### 6.3 n8n Automation Platform

**Directory progetto:** `~/progetti/automation`

**Configurazione:**
```
Image: n8nio/n8n:latest
Container name: n8n
Restart policy: always
Ports:
  - 5678:5678
Volume: ./n8n/data:/home/node/.n8n
Network: automation_network
```

**Variabili ambiente:**
```
N8N_HOST=n8n.studiorizzo.it
N8N_PROTOCOL=https
WEBHOOK_URL=https://n8n.studiorizzo.it/
N8N_PORT=5678
```

**URL accesso:**
```
Pubblico HTTPS:    https://n8n.studiorizzo.it
                   --> Cloudflare Access (email OTP)
                   --> OAuth Google callbacks pubblici

Privato Tailscale: http://100.124.163.105:5678
Locale LAN:        http://192.168.1.50:5678
```

**OAuth Google configurato:**
```
Progetto: n8n-minipc-automation
Client ID: 348579134234-vi9p0d5ddlfh76ncpb6oh31j1tm5c981
Redirect URI: https://n8n.studiorizzo.it/rest/oauth2-credential/callback
Consent Screen: In production (refresh token permanenti)

API abilitate:
  [OK] Google Calendar API
  [OK] Google People API (Contacts)
  [OK] Google Drive API

Credenziali n8n attive: 3 (Calendar, Contacts, Drive)
```

---

### 6.4 WAHA WhatsApp HTTP API

**Container Tel1:**
```
Image: devlikeapro/waha:latest
Container name: waha_tel1
Restart policy: always
Ports:
  - 3000:3000
Volume: ./waha/sessioni_tel1:/app/.sessions
Network: automation_network
Environment:
  - WAHA_API_KEY=pass123
```

**Container Tel2:**
```
Image: devlikeapro/waha:latest
Container name: waha_tel2
Restart policy: always
Ports:
  - 3001:3000
Volume: ./waha/sessioni_tel2:/app/.sessions
Network: automation_network
Environment:
  - WAHA_API_KEY=pass123
```

**Accesso dashboard:**
```
Tel1: http://192.168.1.50:3000  /  http://100.124.163.105:3000
Tel2: http://192.168.1.50:3001  /  http://100.124.163.105:3001

Credenziali:
  Username: admin
  Password: pass123
  API Key:  pass123
```

**Status:**
```
Tel1: [OK] Collegato e operativo
Tel2: Container attivo, in attesa secondo telefono
```

**Note WAHA:**
```
Versione: Core (gratuita)
Limitazione: 1 sessione "default" per container
Soluzione: Container separati per numeri multipli
Sessioni persistenti: QR code richiesto solo prima volta
```

---

### 6.5 Cloudflared Tunnel

**Configurazione:**
```
Image: cloudflare/cloudflared:latest
Container name: cloudflared
Restart policy: always
Command: tunnel --no-autoupdate run --token [ENCRYPTED]
Network: automation_network
```

**Funzione:**
```
Espone n8n pubblicamente su HTTPS
Certificato SSL automatico (Cloudflare)
Nessuna porta router esposta
Traffico outbound-only (sicurezza)
```

---

### 6.6 Gestionale Caterina (Next.js)

**Directory progetto:** `~/progetti/Gestionale_Caterina/webapp`

**Configurazione:**
```
Image: webapp-webapp (build locale)
Container name: gestionale-caterina
Restart policy: always
Ports:
  - 3002:3000
Volume: ./app (bind mount codice)
Networks:
  - gestionale_network
  - automation_network (external - per PostgreSQL)
```

**Variabili ambiente:**
```
NODE_ENV=production
DATABASE_URL=postgresql://admin:***@servizi_postgres:5432/pagamenti_caterina
NEXTAUTH_URL=https://gestionale-caterina.studiorizzo.it
NEXTAUTH_SECRET=*** (JWT signing secret)
```

**URL accesso:**
```
Locale LAN:        http://192.168.1.50:3002
Tailscale VPN:     http://100.124.163.105:3002
Pubblico HTTPS:    https://gestionale-caterina.studiorizzo.it
                   --> Cloudflare Tunnel (nessuna porta router esposta)
                   --> Protezione: Nessuna (opzionale Cloudflare Access)
                   --> Status: [OK] ATTIVO dal 14 Febbraio 2026
```

**Stack tecnologico:**
```
Framework: Next.js 15.5.12 (App Router)
Linguaggio: TypeScript 5.7.2
Database ORM: Prisma 6.19.2
Autenticazione: NextAuth.js 5.0 beta
Styling: Tailwind CSS 3.4.17
Runtime: Node.js 22.22.0
```

**Database:**
```
Database: pagamenti_caterina (PostgreSQL)
Tabelle:
  - anagrafica  (clienti da Google Contacts)
  - calendario  (calendari da Google Calendar)
  - pagamenti   (transazioni + date avvisi calcolate)
  - utenti      (autenticazione web app)
```

**Status:**
```
Installato: 14 Febbraio 2026
Container: Running [OK]
Accesso web: Funzionante [OK]
Cloudflare Tunnel: Attivo [OK]
Database: Connesso [OK]
```

---

### 6.7 Gestione Trasferte (Next.js)

**Directory progetto:** `~/progetti/trasferte`

**Configurazione:**
```
Image: build locale (Dockerfile multi-stage node:22-alpine)
Container name: trasferte-app
Restart policy: unless-stopped
Ports:
  - 3006:3000
Networks:
  - trasferte_network
  - automation_network (external - per cloudflared)
```

**Database dedicato:**
```
Container name: trasferte-db
Image: postgres:16-alpine
Restart policy: unless-stopped
Ports:
  - 192.168.1.50:5435:5432 (solo accesso locale)
Volume: trasferte_postgres_data
Network: trasferte_network
```

**Variabili ambiente (.env):**
```
DATABASE_URL=postgresql://trasferte_user:***@trasferte-db:5432/trasferte_db
NEXTAUTH_SECRET=*** (JWT signing secret)
NEXTAUTH_URL=https://trasferte.studiorizzo.it
POSTGRES_PASSWORD=***
NODE_ENV=production
HOSTNAME=0.0.0.0
```

**URL accesso:**
```
Locale LAN:        http://192.168.1.50:3006
Tailscale VPN:     http://100.124.163.105:3006
Pubblico HTTPS:    https://trasferte.studiorizzo.it
                   --> Cloudflare Tunnel (nessuna porta router esposta)
                   --> Protezione: Login applicativo (NextAuth)
                   --> Status: ATTIVO dal 15 Marzo 2026
```

**Credenziali SUPER_ADMIN iniziali:**
```
Email:    admin@studiorizzo.it
Password: Admin2026!
[ATTENZIONE] Cambiare dopo il primo accesso
```

**Stack tecnologico:**
```
Framework: Next.js 15 (App Router)
Linguaggio: TypeScript
Database ORM: Prisma 5.22.0
Autenticazione: NextAuth.js 5.0 beta
Styling: Tailwind CSS v4
Runtime: Node.js 22 (Alpine)
PDF: @react-pdf/renderer
```

**Database:**
```
Database: trasferte_db (PostgreSQL 16 - container dedicato)
Principali tabelle:
  - ditta         (aziende)
  - dipendente    (anagrafica dipendenti + veicoli)
  - trasferta     (missioni con regime fiscale)
  - spesa         (spese con categoria/sottocategoria)
  - indennita_giornaliera (indennita forfettarie)
  - regola_fiscale (43 regole calcolo fiscale italiano)
  - chiusura_mensile (rendiconti mensili)
```

**Seed iniziale:**
```
Eseguito una tantum dopo il primo avvio:
  docker compose exec trasferte-app npx tsx prisma/seed.ts
  oppure: docker compose run --rm -e DATABASE_URL=... node-seed npx tsx prisma/seed.ts
Crea: categorie spesa, regole fiscali, SUPER_ADMIN
```

**Status:**
```
Installato: 14 Marzo 2026
Container: Running [OK]
Accesso web: Funzionante [OK]
Cloudflare Tunnel: Attivo [OK]
Database: Connesso [OK]
```

---

### 6.9 Cantinetta — Wine Cellar Manager (Next.js)

**Directory progetto:** `~/progetti/cantinetta`

**Configurazione:**
```
Image: build locale (Dockerfile multi-stage node:22-alpine)
Container Next.js:  cantinetta_nextjs
Container PG:       cantinetta_postgres
Restart policy: unless-stopped
Ports:
  - 3007:3000   (Next.js)
  - 192.168.1.50:5436:5432  (PostgreSQL — solo accesso locale)
Networks (cantinetta_nextjs):
  - cantinetta_cantinetta_network (rete privata app)
  - automation_network (external — per cloudflared) [corretto il 21/04/2026]
```

**Variabili ambiente (.env — produzione):**
```
POSTGRES_PASSWORD=*** (password manager)
NEXTAUTH_SECRET=*** (openssl rand -base64 32)
OPENAI_API_KEY=*** (da configurare per Fase 3)
```

**URL accesso:**
```
Locale LAN:        http://192.168.1.50:3007
Tailscale VPN:     http://100.124.163.105:3007
Pubblico HTTPS:    https://cantinetta.studiorizzo.it
                   --> Cloudflare Tunnel (nessuna porta router esposta)
                   --> Protezione: Login applicativo (NextAuth.js 5)
                   --> Status: ATTIVO dal 06 Aprile 2026
```

**Stack tecnologico:**
```
Framework: Next.js 15 (App Router, output: standalone)
Linguaggio: TypeScript 5.x (strict mode)
Database ORM: Prisma 5.22.0 (NON aggiornare a v7)
Autenticazione: NextAuth.js 5.0 beta (JWT + Credentials)
Styling: Tailwind CSS v4
Animazioni: Framer Motion
Runtime: Node.js 22 (Alpine)
```

**Database:**
```
Database: cantinetta_db (PostgreSQL 16 — container dedicato)
Tabelle:
  - users      (ADMIN/MEMBRO, bcryptjs password hash)
  - posizioni  (110 posizioni: A1-F17 GRIGLIA + V1-V8 RIPIANO_VERTICALE)
  - bottiglie  (inventario con tipologia, annata, denominazione, ecc.)
  - prezzi_mercato (storico quotazioni Wine-Searcher/manuale)
```

**Seed iniziale (110 posizioni — idempotente, rieseguibile):**
```bash
# Dall'host con .env.local carico (NON dal container)
source ~/.nvm/nvm.sh && nvm use 22
export $(grep -v '^#' .env.local | xargs)
./node_modules/.bin/prisma db push
npm run prisma:seed
```

**Note critiche:**
```
[!] trustHost: true obbligatorio in auth.ts E auth.edge.ts (UntrustedHost con Cloudflare)
[!] bcryptjs, NON bcrypt nativo (non compila su Alpine)
[!] Prisma 5.22.0 fissa — NON aggiornare a v7
[!] Prisma CLI non disponibile nel container standalone — usare sempre dall'host
[!] NODE_ENV non va in .env.local — rompe il build
```

**Status:**
```
Installato: 06 Aprile 2026
Container: Running [OK]
Accesso web: Funzionante [OK]
Cloudflare Tunnel: Attivo [OK]
Database: Connesso [OK]
Prossima fase: Riconoscimento foto (GPT-4o Vision) + quotazione Wine-Searcher
```

---

### 6.8 pgAdmin (Gestione Database PostgreSQL)

**Directory progetto:** `~/progetti/pgadmin`

**Configurazione:**
```
Image: dpage/pgadmin4:latest
Container name: pgadmin
Restart policy: always
Ports:
  - 8080:80
Volume: pgadmin_data
Network: automation_network
```

**URL accesso:**
```
Locale LAN:    http://192.168.1.50:8080
Tailscale VPN: http://100.124.163.105:8080
```

**Credenziali login:**
```
Email:    cesare.rizzo.vi@gmail.com
Password: AdminPgPass2024!
```

**Server PostgreSQL configurato:**
```
Nome server: PostgreSQL Caterina
Host: servizi_postgres
Porta: 5432
Database: postgres (maintenance)
Username: admin
Password: [password manager]
```

**[ATTENZIONE] Problema rete frequente:**
```
ERRORE:    Usare automation_automation_network invece di automation_network
SINTOMO:   "failed to resolve host 'servizi_postgres'"
CAUSA:     pgAdmin e PostgreSQL su reti diverse
SOLUZIONE: Verificare che pgAdmin sia su automation_network

Verifica:
  docker inspect pgadmin | grep -A 5 "Networks"
  docker inspect servizi_postgres | grep -A 5 "Networks"
  Entrambi devono mostrare "automation_network"
```

**Status:**
```
Installato: 13 Febbraio 2026
Container: Running [OK]
Connessione PostgreSQL: Attiva [OK]
Rete: automation_network [OK]
```

---

## 7. BACKUP SYSTEM

### 7.1 Architettura Backup Dual-Repository

**Strategia:** Backup multi-livello con retention differenziata

**Repository 1 - NAS Locale (QNAP):**
```
Scopo: Restore veloce errori recenti
Frequenza: Ogni notte ore 2:00 AM
Retention: 7 giorni (7 snapshot)
Velocita' restore: 5-15 minuti (LAN Gigabit)
Protezione: RAID 1 (guasto disco)
Path: /mnt/qnap-backup/restic-repo
```

**Repository 2 - Cloud (Backblaze B2):**
```
Scopo: Disaster recovery + protezione ransomware
Frequenza: Ogni notte ore 2:30 AM (dopo NAS)
Retention: 30 giorni + 12 settimane + 12 mesi (~54 snapshot)
Velocita' restore: 1-3 ore (dipende banda internet)
Protezione: Object Lock compliance 30 giorni (immutabilita')
URL: b2:minipc-backup-automation:/
```

### 7.2 Software Backup: Restic

**Versione installata:**
```
Restic: 0.16.4
```

**Caratteristiche:**
```
Crittografia: AES-256 (cifrato client-side)
Compressione: Automatica
Deduplicazione: Chunk-level (risparmio spazio)
Verifiche integrita': Settimanali automatiche (domenica)
Incrementale: Solo delta backup successivi
```

**Password Restic:**
```
NAS:      ~/.restic-password    (600 permissions)
B2 Cloud: ~/.restic-password-b2 (600 permissions)

[ATTENZIONE] CRITICO: Password NON recuperabili. Backup multipli obbligatorio.
```

### 7.3 Repository Locale - NAS QNAP

**Mount NAS:**
```
Protocollo: SMB/CIFS
Server: 192.168.1.100
Share: backup-minipc
Mount point: /mnt/qnap-backup
Automount: /etc/fstab (systemd.automount)
Credenziali: /etc/.smbcredentials (600 permissions)
```

**Utente NAS:**
```
Username: backup-minipc
Permessi: Read/Write su /backup-minipc
Scopo: Segregazione accessi (sicurezza)
```

**Sicurezza NAS:**
```
Firewall QNAP attivo
Whitelist IP:
  - 192.168.1.50 (questo server)
  - 192.168.1.9 (PC amministrazione)
Tutti gli altri IP bloccati
```

### 7.4 Repository Cloud - Backblaze B2

**Account:**
```
Email: cesare.rizzo.vi@gmail.com
Piano: Pay-as-you-go
Storage gratuito: 10 GB
2FA: [OK] Abilitato (Google Authenticator)
```

**Bucket configurato:**
```
Nome: minipc-backup-automation
Tipo: Private
Region: EU Central (s3.eu-central-003.backblazeb2.com)
Object Lock: [OK] Compliance mode
Default retention: 30 giorni (immutabile)
```

**Application Key:**
```
Key Name: minipc-restic-backup
Key ID: 0030d73a5e726970000000001
Application Key: K003klcSmxGVhN42dbf8AdCRd56N8H4
Bucket access: minipc-backup-automation (Read/Write)
File: ~/.b2-credentials (600 permissions)
```

### 7.5 Script Backup Automatico

**Path:** `~/scripts/backup-automation.sh`
**Versione:** 3.0
**Permessi:** 755 (rwxr-xr-x)

**Cosa viene backuppato:**
```
Source: ~/progetti/ (intera directory)
|-- automation/
|   |-- docker-compose.yml
|   |-- n8n/data/ (workflow, credenziali OAuth)
|   |-- waha/sessioni_tel1/
|   +-- waha/sessioni_tel2/
|-- Gestionale_Caterina/
|   |-- webapp/docker-compose.yml
|   |-- webapp/app/Dockerfile
|   |-- webapp/app/.env.local  (SENSIBILE)
|   +-- webapp/app/            (codice applicazione Next.js)
+-- [tutti gli altri progetti in ~/progetti/]

Dump PostgreSQL (salvati in ~/progetti/db-backups/):
  - spese_abbonamenti_db
  - gestionale_studio_rizzo
  - pagamenti_caterina

Escluso da backup:
  - node_modules/  (ricostruibile)
  - .next/         (ricostruibile)
```

**Funzionamento script:**
```
1. Dump PostgreSQL di tutti i database
2. Backup su NAS locale:
   - Verifica mount NAS (email se fallisce)
   - Esegue backup Restic cifrato
   - Applica retention 7 giorni
3. Pausa 30 secondi
4. Backup su B2 cloud:
   - Carica credenziali B2 (source ~/.b2-credentials)
   - Esegue backup Restic su B2
   - Applica retention 30+12+12
5. Verifica integrita' (solo domenica):
   - Check repository NAS
   - Check repository B2
   - Email se errori critici
6. Salva log: ~/backup-logs/backup-automation-YYYYMMDD_HHMMSS.log
```

**Automazione Cron:**
```
Job: 0 2 * * * ~/scripts/backup-automation.sh
Frequenza: Ogni giorno ore 2:00 AM
Log: ~/backup-logs/cron.log
```

**Notifiche email:**
```
SMTP: Gmail (smtp.gmail.com:587)
Mittente: Mini PC Backup <cesare.rizzo.vi@gmail.com>
Destinatario: cesare.rizzo.vi@gmail.com
Trigger: Solo su errori (nessuna email = tutto OK)

Email inviate per:
  - NAS non montato
  - Backup NAS fallito
  - Backup B2 fallito
  - Retention policy fallita
  - Verifica integrita' fallita (domenica)
```

### 7.6 Retention Policy Differenziata

**NAS - 7 giorni (restore veloce):**
```
Daily: ultimi 7 giorni
Snapshot conservati: ~7
```

**B2 Cloud - Multi-livello (long-term):**
```
Daily:   ultimi 30 giorni  (30 snapshot)
Weekly:  ultimi 12 settimane (12 snapshot domenicali)
Monthly: ultimi 12 mesi    (12 snapshot primo del mese)
Totale snapshot conservati: ~54
```

---

## 8. RISORSE SISTEMA

### 8.1 Allocazione RAM (32 GB totali)

**Utilizzo attuale:**
```
Sistema Ubuntu:       ~2.0 GB
Docker engine:        ~0.5 GB
Portainer:            ~0.2 GB
Dockge:               ~0.1 GB
n8n:                  ~0.5 GB
WAHA Tel1:            ~0.5 GB
WAHA Tel2:            ~0.5 GB
cloudflared:          ~0.1 GB
servizi_postgres:     ~0.2 GB
pgadmin:              ~0.2 GB
gestionale-caterina:  ~0.2 GB
trasferte-app:        ~0.2 GB
trasferte-db:         ~0.2 GB
cantinetta_nextjs:    ~0.2 GB
cantinetta_postgres:  ~0.2 GB
-------------------------------
TOTALE USATO:         ~5.8 GB
DISPONIBILE:          ~26.2 GB (per nuovi progetti)
```

### 8.2 Storage (500 GB SSD)

**Utilizzo attuale:**
```
Sistema operativo:    ~4.0 GB
Docker images:        ~4.8 GB
Docker volumes:       ~2.3 GB
n8n data:             ~0.5 GB
WAHA sessions:        ~0.2 GB
Gestionale codice:    ~0.4 GB
Trasferte codice:     ~0.4 GB
Cantinetta codice:    ~0.4 GB
Backup logs:          ~0.5 GB
NAS backup (remoto):  ~6.5 GB
-------------------------------
TOTALE USATO:         ~20.0 GB
DISPONIBILE:          ~80.0 GB (partizione root)
LVM espandibile:      ~350 GB
```

### 8.3 Network Bandwidth

**Connessione internet:**
```
Download: ~100 Mbps
Upload: ~20 Mbps
IP pubblico: Dinamico (Cloudflare Tunnel gestisce)
```

**Utilizzo medio stimato:**
```
Backup B2 notturno:  ~2 GB/notte  --> ~15 minuti upload
Cloudflare Tunnel:   ~100 MB/giorno
WAHA WhatsApp:       ~50 MB/giorno
Totale:              <3 GB/giorno
```

---

## 9. SICUREZZA MULTI-LIVELLO

### 9.1 Stack Sicurezza n8n (4 layer)

**Layer 1 - Network (Cloudflare Tunnel):**
```
[OK] SSL/TLS automatico (certificato Cloudflare)
[OK] DDoS protection Cloudflare
[OK] Nessuna porta esposta su router
[OK] Traffico outbound-only dal server
```

**Layer 2 - Access (Cloudflare Access):**
```
[OK] Autenticazione email con OTP
[OK] Whitelist email (cesare.rizzo.vi@gmail.com)
[OK] Session duration 24 ore
[OK] Bypass pubblico solo per OAuth callbacks
```

**Layer 3 - Application (n8n login):**
```
[OK] Credenziali account owner n8n
[OK] Password forte (20+ caratteri)
```

**Layer 4 - Administration (Tailscale VPN):**
```
[OK] Accesso amministrazione via VPN cifrata
[OK] WireGuard end-to-end encryption
[OK] Dispositivi autorizzati limitati
```

### 9.2 Sicurezza Backup

**Encryption at rest:**
```
[OK] Restic AES-256 client-side encryption
[OK] Password Restic su file 600 permissions
[OK] NAS SMB credenziali in file protetto
[OK] B2 Application Key separata (non master key)
```

**Encryption in transit:**
```
[OK] NAS: SMB/CIFS cifrato
[OK] B2: HTTPS/TLS 1.2+
[OK] Tailscale: WireGuard encryption
```

**Protezione ransomware:**
```
[OK] Object Lock B2 compliance 30 giorni
[OK] NAS firewall whitelist IP
[OK] Repository Restic cifrati (illeggibili senza password)
[OK] Backup off-site (B2 cloud)
```

### 9.3 Credenziali e Password

**Gestione password:**
```
Password manager: [Bitwarden/1Password/KeePass]
Backup password: 3 copie (manager + USB cifrato + carta stampata)
Rotazione: Annuale per password critiche
```

**Password critiche:**
```
1.  Ubuntu user cesare
2.  Portainer admin
3.  Dockge admin
4.  n8n account owner
5.  WAHA API key
6.  NAS admin
7.  NAS user backup-minipc
8.  Restic password NAS  (NON RECUPERABILE)
9.  Restic password B2   (NON RECUPERABILE)
10. Backblaze B2 account
11. Cloudflare account
12. Google OAuth Client Secret
```

---

## 10. PORTE DISPONIBILI E UTILIZZATE

### 10.1 Porte Occupate

```
22    --> SSH (sistema)
3000  --> WAHA Tel1
3001  --> WAHA Tel2
3002  --> Gestionale Caterina Next.js
3006  --> Gestione Trasferte Next.js
3007  --> Cantinetta Wine Cellar Manager
5001  --> Dockge (gestione stack Docker Compose)
5432  --> PostgreSQL (servizi_postgres)
5435  --> PostgreSQL Trasferte (bind 192.168.1.50 - solo locale)
5436  --> PostgreSQL Cantinetta (bind 192.168.1.50 - solo locale)
5678  --> n8n
8080  --> pgAdmin
9000  --> Portainer HTTP
9443  --> Portainer HTTPS
```

### 10.2 Porte Suggerite per Nuovi Progetti

```
Range 3003-3999:  Applicazioni web aggiuntive
Range 5000-5432:  API e backend
Range 5433-5677:  Database aggiuntivi PostgreSQL
Range 6000-6999:  Database aggiuntivi (altri motori)
Range 7000-7999:  Servizi custom
Range 8001-8079:  Web dashboard/frontend
Range 8081-8500:  Web dashboard/frontend
Range 9001-9442:  Monitoring e admin tools
Range 10000+:     Servizi sperimentali
```

---

## 11. PROCEDURE OPERATIVE STANDARD

### 11.1 Accesso Server

**SSH da rete locale:**
```bash
ssh cesare@192.168.1.50
```

**SSH da remoto (Tailscale):**
```bash
ssh cesare@100.124.163.105
```

**Accesso tool di gestione (da browser Windows):**
```
Portainer: http://192.168.1.50:9000
Dockge:    http://192.168.1.50:5001
pgAdmin:   http://192.168.1.50:8080
```

### 11.2 Gestione Container Docker

**Comandi base:**
```bash
# Navigare a progetto
cd ~/progetti/automation

# Status container
docker compose ps

# Avviare tutti
docker compose up -d

# Fermare tutti
docker compose down

# Restart singolo container
docker compose restart n8n

# Log real-time
docker compose logs -f n8n

# Shell in container
docker compose exec n8n sh
```

### 11.3 Verifica Backup Giornaliero

**Check rapido:**
```bash
# 1. Verifica email - nessuna email = backup OK

# 2. Ultimo log backup
ls -lht ~/backup-logs/ | head -3

# 3. Leggi log
cat $(ls -t ~/backup-logs/backup-automation-*.log | head -1)

# 4. Snapshot NAS recente
restic snapshots --latest 1 \
  --repo /mnt/qnap-backup/restic-repo \
  --password-file ~/.restic-password

# 5. Snapshot B2 recente
source ~/.b2-credentials
restic snapshots --latest 1 \
  --repo b2:minipc-backup-automation:/ \
  --password-file ~/.restic-password-b2
```

### 11.4 Deploy Nuovo Progetto Docker

**Template workflow:**
```bash
# 1. Crea directory progetto
mkdir -p ~/progetti/[nome-progetto]
cd ~/progetti/[nome-progetto]

# 2. Crea docker-compose.yml
nano docker-compose.yml

# 3. Identifica porta disponibile (consulta sezione 10.2)
sudo ss -tlnp | grep [PORTA]

# 4. Apri porta nel firewall
sudo ufw allow [PORTA]/tcp comment '[NOME-SERVIZIO]'

# 5. Avvia container
docker compose up -d

# 6. Verifica funzionamento
docker compose ps
docker compose logs -f

# 7. Test accesso
curl http://192.168.1.50:[PORTA]

# 8. (Opzionale) Esponi pubblicamente via Cloudflare
# Dashboard Cloudflare --> Tunnel --> Add public hostname
```

### 11.5 Gestire uno Stack con Dockge

**Creare un nuovo stack via interfaccia Dockge:**
```
1. Aprire http://192.168.1.50:5001
2. Clicca "Compose" --> "+"
3. Inserire nome stack e contenuto docker-compose.yml
4. Dockge salva automaticamente in /opt/stacks/[nome-stack]/
```

**Importare un progetto esistente in Dockge:**
```bash
# 1. Crea directory in /opt/stacks/
sudo mkdir -p /opt/stacks/[nome-stack]
sudo chown cesare:cesare /opt/stacks/[nome-stack]

# 2. Copia il docker-compose.yml
cp ~/progetti/[nome-progetto]/docker-compose.yml \
   /opt/stacks/[nome-stack]/

# 3. Apri Dockge nel browser: il progetto appare automaticamente
```

### 11.6 Aggiungere un Nuovo Database al Backup

I progetti in `~/progetti/` sono inclusi automaticamente nel backup notturno.

Per includere il dump di un nuovo database PostgreSQL:
```bash
# 1. Edita script backup
nano ~/scripts/backup-automation.sh

# 2. Trova la sezione "dump PostgreSQL" e aggiungi:
docker exec [container_postgres] pg_dump -U [user] [db_name] \
  > ~/progetti/db-backups/[db_name].sql
```

---

## 12. INTEGRAZIONE OAUTH GOOGLE (TEMPLATE)

### 12.1 Prerequisiti OAuth

```
Account Google Cloud: cesare.rizzo.vi@gmail.com
Console: https://console.cloud.google.com
OAuth Consent Screen: In production (refresh token permanenti)
```

### 12.2 Configurazione OAuth per Nuova App

**Step 1 - Creare OAuth Client ID:**
```
1. Google Cloud Console --> APIs & Services --> Credentials
2. Create Credentials --> OAuth 2.0 Client ID
3. Application type: Web application
4. Authorized redirect URIs:
   https://[subdomain].studiorizzo.it/[callback-path]
5. Salva Client ID e Client Secret
```

**Step 2 - Abilitare API necessarie:**
```
Google Cloud Console --> APIs & Services --> Library
Cerca e abilita le API richieste dall'applicazione
```

**Step 3 - Esporre applicazione via Cloudflare:**
```
Cloudflare Dashboard --> Tunnel studiorizzo-services
Add public hostname:
  Subdomain: [subdomain]
  Domain: studiorizzo.it
  Service: http://[container-name]:[port]
```

**Step 4 - Cloudflare Access (opzionale):**
```
Zero Trust --> Access --> Applications
Add application --> Self-hosted
Policy 1: Admin Access (email whitelist)
Policy 2: Bypass callback path (OAuth pubblico)
```

---

## 13. LIMITI E QUOTE SISTEMA

### 13.1 Limiti Hardware

```
CPU massima utilizzabile: 12 core / 16 thread
RAM massima: 32 GB (espandibile a 64 GB)
Storage SSD: 500 GB (espandibile con SSD esterno)
NAS backup: 2.8 TB utilizzabili
```

### 13.2 Limiti Software/Servizi

**Cloudflare (piano Free):**
```
Bandwidth: Illimitato [OK]
Tunnel: Illimitati [OK]
Access users: 50 gratuiti [OK]
Access log retention: 24 ore
DNS queries: Illimitate [OK]
```

**Backblaze B2 (pay-as-you-go):**
```
Storage gratuito: 10 GB
Costo oltre limite:
  Storage:  0.005 EUR/GB/mese
  Download: 0.01 EUR/GB
```

**Tailscale (piano Free):**
```
Dispositivi: 100 gratuiti [OK]
Users: 1 gratuito
Subnet routers: Illimitati [OK]
```

---

## 14. TROUBLESHOOTING COMUNE

### 14.1 Container non si avvia

```bash
# Log errori
docker compose logs [container-name]

# Porta gia' occupata?
sudo ss -tlnp | grep [PORTA]

# Riavvia container
docker compose restart [container-name]

# Ricrea container
docker compose down && docker compose up -d
```

### 14.2 NAS non raggiungibile

```bash
# NAS acceso?
ping 192.168.1.100

# Mount attivo?
mountpoint /mnt/qnap-backup

# Rimonta
sudo umount /mnt/qnap-backup
sudo mount -a
```

### 14.3 Backup fallito

```bash
# Log errori backup
tail -100 ~/backup-logs/backup-automation-*.log

# Test backup manuale NAS
restic backup ~/progetti \
  --repo /mnt/qnap-backup/restic-repo \
  --password-file ~/.restic-password

# Test backup manuale B2
source ~/.b2-credentials
restic backup ~/progetti \
  --repo b2:minipc-backup-automation:/ \
  --password-file ~/.restic-password-b2
```

### 14.4 Cloudflare Tunnel disconnesso

```bash
# Status container cloudflared
docker compose ps | grep cloudflared

# Log errori
docker compose logs cloudflared | tail -50

# Riavvia tunnel
docker compose restart cloudflared

# Verifica connessioni (atteso: 4 connessioni "Registered")
docker compose logs cloudflared | grep "Registered"
```

### 14.5 Dockge non si avvia

```bash
# Log errori
docker logs dockge

# Verifica stato
docker ps | grep dockge

# Riavvia
cd /opt/dockge && sudo docker compose restart

# Verifica porta
sudo ss -tlnp | grep 5001

# Verifica firewall
sudo ufw status | grep 5001
```

---

## 15. ESPANSIONE E SCALABILITA'

### 15.1 Aggiungere RAM

```
1. Spegni server
2. Installa moduli RAM DDR4 3200MHz
3. Max supportato: 64 GB (2x32GB)
4. Riavvia e verifica: free -h
```

### 15.2 Espandere Storage

**Opzione 1 - Espandere partizione root (LVM):**
```bash
# Vedi spazio LVM disponibile
sudo vgs && sudo lvs

# Espandi logical volume (+50GB esempio)
sudo lvextend -L +50G /dev/ubuntu-vg/ubuntu-lv

# Espandi filesystem
sudo resize2fs /dev/ubuntu-vg/ubuntu-lv

# Verifica
df -h
```

**Opzione 2 - Aggiungere SSD esterno USB:**
```
1. Collega SSD USB (USB 3.2 per velocita')
2. Formatta: sudo mkfs.ext4 /dev/sdX
3. Mount: sudo mount /dev/sdX /mnt/storage-extra
4. Aggiungi a fstab per automount
5. Usa per Docker volumes o progetti
```

### 15.3 Aggiungere Servizi Cloudflare

**Template aggiunta servizio pubblico:**
```
1. Deploy container Docker con porta specifica
2. Cloudflare Tunnel --> Add public hostname
   Subdomain: [nome-servizio]
   Domain: studiorizzo.it
   Service: http://[container]:[port]
3. (Opzionale) Cloudflare Access per protezione
4. Test: https://[nome-servizio].studiorizzo.it
```

---

## 16. DOCUMENTAZIONE E RIFERIMENTI

### 16.1 File Documentazione Progetto

```
CONFIGURAZIONE_MINIPC.MD
  --> Questo documento (riferimento infrastruttura completa)

WORKFLOW_PROGETTI.MD
  --> Guida completa ciclo vita progetti (v1.1)

CONFIGURAZIONE_BACKUP_QNAP_NAS.md
  --> Guida completa backup dual-repository

CloudFlare_N8N.MD
  --> Guida configurazione Cloudflare Tunnel

CONFIGURAZIONE_OAUTH_COMPLETATA.md
  --> Documentazione OAuth Google

CONFIGURAZIONE_CLOUDFLARE_ACCESS_COMPLETATA.md
  --> Documentazione Cloudflare Access

README_AUTOMATION.md
  --> README progetto n8n + WAHA

GESTIONALE_CATERINA_DEPLOY.md
  --> Guida deploy Gestionale Caterina
```

### 16.2 Link Esterni Utili

```
Ubuntu Server:      https://ubuntu.com/server/docs
Docker:             https://docs.docker.com
Portainer:          https://docs.portainer.io
Dockge:             https://github.com/louislam/dockge
n8n:                https://docs.n8n.io
WAHA:               https://waha.devlike.pro
Cloudflare Tunnel:  https://developers.cloudflare.com/cloudflare-one/connections/connect-apps
Tailscale:          https://tailscale.com/kb
Restic:             https://restic.readthedocs.io
Backblaze B2:       https://www.backblaze.com/b2/docs
Google Cloud:       https://console.cloud.google.com
```

---

## 17. CONSIDERAZIONI PER NUOVI SVILUPPI

### 17.1 Requisiti Minimi Nuovo Progetto

**Checklist pre-sviluppo:**
```
[ ] RAM richiesta: _____ GB (disponibili: ~27 GB)
[ ] Storage richiesto: _____ GB (disponibili: ~81 GB root + 350 GB LVM)
[ ] Porta necessaria: _____ (verificare sezione 10.2)
[ ] Accesso pubblico: Si / No
    Se si: subdomain ________________.studiorizzo.it
[ ] OAuth richiesto: Si / No
    Se si: API Google da abilitare: _________________
[ ] Backup necessario: Si / No
    (default: incluso automaticamente in ~/progetti/)
[ ] Database necessario: Si / No
    Se si: tipo _________ (PostgreSQL/MySQL/MongoDB)
    Se si: aggiungere dump a backup-automation.sh
```

### 17.2 Best Practices Sviluppo

**Containerizzazione:**
```
[OK] SEMPRE usare Docker Compose
[OK] Network dedicata per progetto multi-container
[OK] Volume named per dati persistenti
[OK] restart: always per servizi production
[OK] Health checks quando possibile
```

**Sicurezza:**
```
[OK] Mai esporre database su 0.0.0.0 (solo rete Docker interna)
[OK] Credenziali in environment variables o secrets
[OK] File credenziali con permessi 600
[OK] Firewall UFW per porte necessarie
[OK] Se pubblico: sempre via Cloudflare Tunnel (no port forwarding router)
```

**Naming conventions:**
```
Container name: [progetto]-[servizio]   (es: gestionale-api)
Network name:   [progetto]_network      (es: gestionale_network)
Volume name:    [progetto]_[tipo]       (es: gestionale_postgres_data)
Directory:      ~/progetti/[nome-progetto]
```

**Convenzioni tecniche obbligatorie:**
```
Node.js:         versione 22 via nvm (sistema usa Node 18 - sovrascrivere sempre)
bcryptjs:        NON bcrypt (compatibilita' Alpine)
Prisma:          versione 5.22.0 (NON v7 - breaking API changes)
Prisma targets:  binaryTargets deve includere linux-musl-openssl-3.0.x
HOSTNAME:        0.0.0.0 in Dockerfile E docker-compose.yml
Next.js output:  standalone in next.config.ts
Rete esterna:    automation_network (external: true) per TUTTI i casi:
                 accesso a servizi_postgres, n8n, WAHA, cloudflared.
                 NON usare automation_automation_network nei nuovi progetti —
                 e' una rete creata per errore (prefisso doppio Docker Compose).
                 ATTENZIONE: il docker-compose.yml di ~/progetti/automation/ DEVE dichiarare
                 automation_network come external:true — mai come driver:bridge (causa riavvii
                 su rete sbagliata con perdita connettivita' verso postgres).
                 Fix del 21/04/2026: cantinetta e spese erano su automation_automation_network
                 e non venivano raggiunti da cloudflared (502 Bad Gateway).
trustHost:       aggiungere sempre trustHost:true in auth.ts E auth.edge.ts (NextAuth v5 beta)
NODE_ENV:        NON includere in .env.local — rompe il build di produzione Next.js
```

### 17.3 Template docker-compose.yml

```yaml
version: '3.8'

services:
  nome_servizio:
    image: nome_immagine:tag
    container_name: progetto_servizio
    restart: always
    ports:
      - "PORTA_HOST:PORTA_CONTAINER"
    volumes:
      - ./data:/data
    environment:
      - VAR1=value1
    networks:
      - progetto_network

networks:
  progetto_network:
    driver: bridge

volumes:
  volume_persistente:
    driver: local
```

### 17.4 Checklist Post-Deploy

```
[ ] Container attivo e stabile (docker compose ps)
[ ] Log senza errori (docker compose logs)
[ ] Porta aperta in firewall (sudo ufw status)
[ ] Accessibile localmente (curl/browser)
[ ] Accessibile via Tailscale
[ ] Se pubblico: hostname Cloudflare configurato
[ ] Se pubblico: Cloudflare Access configurato (se necessario)
[ ] Credenziali salvate in password manager
[ ] Documentazione README creata nella directory progetto
[ ] Aggiornato CONFIGURAZIONE_MINIPC.MD (sezioni 6, 8, 10)
```

---

## 18. LOG MODIFICHE DOCUMENTO

| Data       | Versione | Autore          | Modifiche |
|------------|----------|-----------------|-----------|
| 09/02/2026 | 2.0      | Cesare          | Documento completo configurazione infrastruttura |
| 13/02/2026 | 2.1      | Cesare + Claude | Aggiunto Gestionale Caterina, pgAdmin, reti Docker |
| 14/02/2026 | 2.2      | Cesare + Claude | Aggiornate risorse, deploy Gestionale Caterina, mappa reti |
| 14/02/2026 | 2.3      | Cesare + Claude | Consolidamento sezioni duplicate, pulizia struttura |
| 12/03/2026 | 2.4      | Cesare + Claude | Aggiunto Dockge (porta 5001), pulizia caratteri corrotti, backup esteso a ~/progetti/ intero, script rinominato backup-automation.sh, aggiornate porte UFW |
| 14/03/2026 | 2.5      | Cesare + Claude | Aggiunto progetto Gestione Trasferte (porta 3006, DB dedicato porta 5435), aggiornate sezioni 4.3, 4.4, 5.2, 6, 8, 10, corretta rete automation_network |
| 15/03/2026 | 2.6      | Cesare + Claude | Deploy Gestione Trasferte completato e verificato in produzione, corretta data attivazione |
| 07/04/2026 | 2.7      | Cesare + Claude | Aggiunto progetto Cantinetta (porta 3007, DB dedicato porta 5436); aggiornate sezioni 4.3, 4.4, 5.2, 6 (§6.9), 8, 10; corretta convenzione rete automation_automation_network |
| 21/04/2026 | 2.8      | Cesare + Claude | Fix critico reti Docker: n8n disconnesso da automation_network dopo riavvio durante sviluppo Segretario AI; corretta sezione 5.2 con regola external:true per docker-compose.yml automation; aggiornata sezione 17.2 convenzioni tecniche |
| 21/04/2026 | 2.9      | Cesare + Claude | Fix reti Docker esteso a tutti i progetti: cantinetta e spese in 502 Bad Gateway perche' su automation_automation_network invece di automation_network; corretto docker-compose.yml cantinetta; fix manuale spese_nextjs; aggiornate sezioni 5.2, 6.9, 17.2 |

---

## NOTE FINALI

**Quando aggiornare questo documento:**
- Aggiunta nuovo container Docker permanente
- Cambio configurazione rete (IP, firewall, Cloudflare)
- Upgrade hardware (RAM, storage, NAS)
- Modifica strategia backup
- Deploy servizio pubblico nuovo su Cloudflare
- Cambio credenziali critiche

**Per iniziare un nuovo progetto:**
1. Leggi sezione 17 (Considerazioni Nuovi Sviluppi)
2. Compila checklist requisiti (sezione 17.1)
3. Segui template docker-compose (sezione 17.3)
4. Deploy seguendo workflow standard (sezione 11.4)
5. Completa checklist post-deploy (sezione 17.4)
6. Aggiorna questo documento (sezioni 6, 8, 10, 18)

---

**FINE DOCUMENTO**

Ultimo aggiornamento: 21 Aprile 2026
Autore: Cesare + Claude AI
Versione: 2.9
Status: [OK] Infrastruttura operativa e documentata
