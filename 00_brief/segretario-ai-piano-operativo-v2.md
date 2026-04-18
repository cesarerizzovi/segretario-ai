# SEGRETARIO AI
**Assistente Personale Intelligente**
*Piano operativo e architettura tecnica*

Versione 2.0 — Aprile 2026
Cesare Rizzo

---

## 1. Obiettivo del progetto

Realizzare un assistente AI personale con cui interagire in linguaggio naturale (voce e testo) tramite Signal, in grado di:

- Gestire appuntamenti su Outlook Calendar (lavoro) e Google Calendar (privato)
- Gestire attività e scadenze con solleciti proattivi e persistenti
- Pianificare la giornata con briefing mattutino vocale
- Rispondere a voce (messaggi vocali Signal)
- Inseguire i task arretrati con escalation progressiva

---

## 2. Decisioni architetturali

### 2.1 Canale di comunicazione: Signal

Scelto per la crittografia end-to-end, la natura open source e la compatibilità con Android. Il segretario è un contatto Signal con un numero dedicato (SIM prepagata). L'interazione avviene come una normale chat: messaggi testuali e vocali.

### 2.2 Motore AI: Claude API (cloud)

Scelto per la qualità superiore nella comprensione e generazione dell'italiano. Modello consigliato: Claude Sonnet (rapporto qualità/costo). Costo stimato: $3–10/mese.

### 2.3 Infrastruttura: miniPC Docker

Tutti i servizi girano sul miniPC (sempre acceso), già configurato con Docker e n8n. La GPU RTX 3060 è sul PC desktop e non è disponibile per il server.

### 2.4 Trascrizione vocale: Whisper API (cloud)

Il miniPC non ha GPU: la trascrizione dei messaggi vocali avviene tramite Whisper API di OpenAI ($0.006/minuto). Qualità eccellente in italiano, costo irrisorio per messaggi brevi.

### 2.5 Sintesi vocale: Edge TTS

Risposte vocali generate tramite Edge TTS (Microsoft), gratuito e con voce italiana naturale. Non richiede GPU. L'audio viene inviato come messaggio vocale Signal.

### 2.6 Calendari: doppia integrazione

Outlook Calendar (via Microsoft Graph API) per gli appuntamenti lavorativi. Google Calendar per gli appuntamenti privati. Il LLM determina la destinazione dal contesto; in caso di ambiguità, chiede conferma.

### 2.7 Task: SQLite locale

I task vengono memorizzati in un database SQLite sul miniPC, sostituendo progressivamente Todoist. Nessuna dipendenza esterna, backup semplice, controllo totale.

### 2.8 Principio operativo: AI propone, logica esegue

Claude interpreta il messaggio e restituisce un output JSON strutturato. Una logica deterministica in n8n valida il risultato e decide se eseguire, chiedere conferma o rifiutare.

- **Azione automatica:** tutti i dati essenziali sono presenti e non ambigui (data, ora, descrizione, calendario chiaro)
- **Azione con conferma:** manca un dato critico, oppure lo smistamento calendario è incerto
- **Nessuna azione:** testo troppo ambiguo — Claude chiede chiarimento all'utente

L'output JSON di Claude include un campo `needs_confirmation` (true/false) con motivo. È n8n che decide se procedere, non il modello.

---

## 3. Componenti tecnici

| Componente | Tecnologia | Dove gira | Costo | Note |
|---|---|---|---|---|
| Interfaccia | Signal (Android) | Smartphone | Gratuito | Chat + vocali |
| Gateway messaggi | signal-cli-rest-api | miniPC Docker | Gratuito | Serve SIM dedicata |
| Orchestratore | n8n | miniPC Docker | Gratuito | Già installato |
| LLM | Claude API (Sonnet) | Cloud Anthropic | $3–10/mese | Italiano fluente |
| STT (voce→testo) | Whisper API (OpenAI) | Cloud OpenAI | $0.006/min | Per vocali Signal |
| TTS (testo→voce) | Edge TTS (Microsoft) | miniPC | Gratuito | Voce italiana |
| Calendario lavoro | Microsoft Graph API | Cloud M365 | Incluso | Sync bidirezionale |
| Calendario privato | Google Calendar API | Cloud Google | Incluso | Nodo nativo n8n |
| Database | SQLite | miniPC | Gratuito | Task + log messaggi |
| Alert urgenti | CallMeBot / Pushover | Cloud | Gratuito/€5 | Fa squillare il tel. |

**Costo operativo totale stimato:** $5–15/mese (API Claude + Whisper). Tutto il resto è gratuito o già in dotazione.

---

## 4. Flussi operativi

### 4.1 Interazione standard (testo)

L'utente scrive un messaggio su Signal. signal-cli lo riceve e invia un webhook a n8n. Prima di qualsiasi elaborazione, n8n salva il messaggio grezzo nella tabella `messages_inbox` (testo originale, timestamp, id Signal, stato). Viene verificata l'idempotenza tramite `message_id` Signal per evitare duplicazioni.

n8n passa il testo a Claude API con il system prompt del segretario. Claude estrae l'intent e le entità, e restituisce un JSON strutturato con il campo `needs_confirmation`. n8n valida il risultato: se tutti i dati sono presenti e non ambigui, esegue l'azione; se `needs_confirmation` è true, chiede conferma all'utente prima di procedere. La risposta viene inviata via signal-cli su Signal e registrata nella tabella `messages_outbox`.

### 4.2 Interazione vocale

L'utente invia un messaggio vocale su Signal. signal-cli riceve il file audio e lo inoltra a n8n. n8n invia l'audio a Whisper API per la trascrizione. Il testo trascritto entra nel flusso standard (punto 4.1). La risposta di Claude viene convertita in audio tramite Edge TTS. L'audio viene inviato come messaggio vocale Signal.

### 4.3 Briefing mattutino (proattivo)

Ogni mattina alle 7:30 (configurabile tramite `system_settings`), un cron job in n8n si attiva. Interroga Outlook Calendar e Google Calendar per gli eventi del giorno. Interroga SQLite per i task in scadenza e quelli arretrati. Compone il contesto e lo passa a Claude per generare un riepilogo conversazionale. Converte il riepilogo in audio (Edge TTS) e lo invia su Signal come messaggio vocale.

### 4.4 Solleciti e inseguimento task

Lo scheduler gira ogni 3 ore durante l'orario lavorativo, rispettando le fasce orarie di quiete definite in `system_settings`. Il campo `next_followup_at` su ogni task determina quando è previsto il prossimo sollecito. Per ogni task aperto con scadenza raggiunta o superata:

- **Primo sollecito:** tono gentile, ricorda la scadenza
- **Secondo sollecito (dopo 3 ore):** chiede se farlo adesso o posticipare
- **Terzo sollecito (giorno dopo):** segnala l'arretrato, propone di pianificare uno slot
- **Quarto sollecito e oltre:** attiva la telefonata/Pushover (il telefono squilla)

I solleciti si fermano quando l'utente completa il task, lo posticipa esplicitamente, o dice "non ricordarmelo più oggi" (`snooze_until` viene impostato a fine giornata).

### 4.5 Smistamento calendario automatico

Claude analizza il contesto del messaggio e restituisce il `calendario_destinazione` nel JSON di risposta. n8n applica la decisione ma, se il campo `needs_confirmation` è true per lo smistamento, chiede conferma prima di creare l'evento.

- **Contesto lavorativo** (clienti, scadenze fiscali, riunioni studio, pratiche, colleghi) → Outlook Calendar
- **Contesto privato** (medico, famiglia, amici, sport, viaggi, casa) → Google Calendar
- **Contesto ambiguo** → il segretario chiede conferma

---

## 5. Schema database SQLite

### 5.1 Tabella `task`

| Campo | Tipo | Obbl. | Descrizione |
|---|---|---|---|
| id | INTEGER PK | Sì | Identificativo univoco auto-incrementale |
| descrizione | TEXT | Sì | Descrizione del task in linguaggio naturale |
| scadenza | DATETIME | No | Data e ora di scadenza (null = nessuna scadenza) |
| priorita | TEXT | No | alta / media / bassa (default: media) |
| stato | TEXT | Sì | aperto / completato / posticipato / annullato |
| reminder_count | INTEGER | Sì | Numero di solleciti già inviati (default: 0) |
| ultimo_sollecito | DATETIME | No | Timestamp dell'ultimo sollecito inviato |
| next_followup_at | DATETIME | No | Data/ora del prossimo sollecito previsto |
| snooze_until | DATETIME | No | Silenzia solleciti fino a questa data/ora |
| source_message_id | TEXT | No | ID del messaggio Signal che ha generato il task |
| calendar_event_id | TEXT | No | ID evento calendario collegato (se presente) |
| creato_il | DATETIME | Sì | Data di creazione del task |
| updated_at | DATETIME | Sì | Ultimo aggiornamento (trigger automatico) |
| completato_il | DATETIME | No | Data di completamento (null se aperto) |
| categoria | TEXT | No | Categoria libera (es. cliente, fiscale, personale) |

### 5.2 Tabella `messages_inbox`

Ogni messaggio ricevuto viene salvato prima di qualsiasi elaborazione. Serve per audit, retry, debug e deduplicazione.

| Campo | Tipo | Obbl. | Descrizione |
|---|---|---|---|
| id | INTEGER PK | Sì | Identificativo univoco |
| signal_message_id | TEXT UNIQUE | Sì | ID messaggio Signal (chiave deduplicazione) |
| testo_originale | TEXT | No | Testo del messaggio o trascrizione vocale |
| tipo | TEXT | Sì | testo / vocale |
| audio_path | TEXT | No | Percorso file audio (se vocale) |
| stato_elaborazione | TEXT | Sì | ricevuto / elaborato / errore |
| ricevuto_il | DATETIME | Sì | Timestamp di ricezione |

### 5.3 Tabella `messages_outbox`

Ogni risposta inviata dal segretario. Utile per tracciare cosa è stato comunicato e diagnosticare problemi.

| Campo | Tipo | Obbl. | Descrizione |
|---|---|---|---|
| id | INTEGER PK | Sì | Identificativo univoco |
| inbox_message_id | INTEGER FK | No | Riferimento al messaggio che ha generato la risposta |
| testo_risposta | TEXT | Sì | Testo della risposta inviata |
| tipo | TEXT | Sì | testo / vocale |
| azione_eseguita | TEXT | No | Intent eseguito (crea_appuntamento, crea_task, ecc.) |
| inviato_il | DATETIME | Sì | Timestamp di invio |

### 5.4 Tabella `system_settings`

Configurazioni operative del segretario, modificabili senza toccare il codice.

| Chiave | Tipo | Descrizione |
|---|---|---|
| orario_quiete_inizio | TEXT | Ora inizio silenzio solleciti (es. 21:00) |
| orario_quiete_fine | TEXT | Ora fine silenzio solleciti (es. 07:30) |
| giorni_esclusi | TEXT | Giorni senza solleciti (es. domenica) |
| briefing_orario | TEXT | Ora del briefing mattutino (default: 07:30) |
| frequenza_solleciti_ore | INTEGER | Intervallo tra solleciti in ore (default: 3) |

---

## 6. Nodo n8n per Signal

n8n non ha un nodo ufficiale per Signal. Esiste un community node dedicato:

- **Package:** `n8n-nodes-signal-cli-rest-api`
- **Autore:** ZBlaZe (GitHub)
- **Installazione:** Settings → Community Nodes → Install → `n8n-nodes-signal-cli-rest-api`

Il nodo include un trigger (ricezione messaggi) e azioni (invio messaggi, invio media, gestione gruppi). Richiede che `signal-cli-rest-api` sia in esecuzione e raggiungibile da n8n sulla stessa rete Docker.

Esiste inoltre un template di workflow n8n già pronto che implementa un assistente AI personale via Signal con LLM, da cui partire come base.

---

## 7. Infrastruttura Docker

Il `docker-compose` aggiunge `signal-cli-rest-api` alla configurazione esistente del miniPC (dove n8n è già in esecuzione):

- **signal-cli-rest-api:** container dedicato, modalità json-rpc, porta 8085, volume persistente per le chiavi Signal
- **SQLite:** file database montato come volume, accessibile da n8n
- **n8n:** già in esecuzione, si aggiunge il community node per Signal

Tutti i container condividono la stessa rete Docker interna per comunicare senza esporre porte all'esterno.

---

## 8. System prompt del segretario

Il system prompt di Claude definisce il ruolo, il comportamento e le regole operative del segretario. Elementi chiave:

- **Ruolo:** segretario personale di Cesare Rizzo, dottore commercialista
- **Lingua:** italiano, tono professionale ma cordiale, dare del tu
- **Intent recognition:** estrarre intent (`crea_appuntamento`, `crea_task`, `lista_giornata`, `completa_task`, `posticipa_task`, `snooze_oggi`, `domanda_generica`) ed entità (data, ora, descrizione, calendario_destinazione)
- **Output strutturato:** JSON per n8n con campi `intent`, entità, `needs_confirmation`, `motivo_conferma` + testo conversazionale per l'utente
- **Smistamento calendario:** lavoro → Outlook, privato → Google Calendar, ambiguo → `needs_confirmation: true`
- **Solleciti:** tono che scala con il ritardo (gentile → insistente → urgente)
- **Contesto:** riceve la lista impegni del giorno per risposte contestuali

---

## 9. Piano di implementazione

### Fase A — MVP funzionale

Obiettivo: segretario operativo con testo, calendari e task.

| # | Attività | Durata | Priorità | Dipendenze |
|---|---|---|---|---|
| 0 | Procurarsi SIM prepagata dedicata | 1 giorno | Bloccante | Nessuna |
| 1 | Deploy signal-cli-rest-api su Docker, registrazione numero, test invio/ricezione | 2–3 giorni | Alta | Fase 0 |
| 2 | Community node Signal in n8n. Workflow: webhook → salvataggio inbox → deduplicazione → Claude API → risposta Signal | 2–3 giorni | Alta | Fase 1 |
| 3 | Database SQLite: schema completo (task, messages_inbox, messages_outbox, system_settings) | 2 giorni | Alta | Fase 2 |
| 4 | System prompt Claude: ruolo segretario, intent extraction, output JSON con needs_confirmation | 2 giorni | Alta | Fase 2 |
| 5 | Integrazione Microsoft Graph API: OAuth, lettura/creazione eventi Outlook Calendar | 3–4 giorni | Alta | Fase 4 |
| 6 | Integrazione Google Calendar API: OAuth, lettura/creazione eventi, smistamento con conferma | 2–3 giorni | Alta | Fase 5 |

**Timeline MVP (Fase A):** circa 3 settimane

### Fase B — Proattività

| # | Attività | Durata | Priorità | Dipendenze |
|---|---|---|---|---|
| 7 | Briefing mattutino: cron job, aggregazione calendari + task, generazione riepilogo | 2–3 giorni | Media | Fase A |
| 8 | Solleciti task: scheduler con rispetto fasce di quiete, escalation progressiva, snooze | 2–3 giorni | Media | Fase A |

### Fase C — Voce

| # | Attività | Durata | Priorità | Dipendenze |
|---|---|---|---|---|
| 9 | Whisper API (STT) per ricezione vocali + Edge TTS per risposte vocali | 3–4 giorni | Media | Fase A |

### Fase D — Alert forti

| # | Attività | Durata | Priorità | Dipendenze |
|---|---|---|---|---|
| 10 | Integrazione CallMeBot o Pushover per far squillare il telefono | 1–2 giorni | Bassa | Fase B |

### Fase E — Rodaggio

| # | Attività | Durata | Priorità | Dipendenze |
|---|---|---|---|---|
| 11 | Test sul campo, raffinamento prompt, tuning frequenza solleciti | 2–4 settimane | Continua | Tutte |

**Timeline completa (Fasi A–D):** circa 5–6 settimane

---

## 10. Rischi e mitigazioni

| Rischio | Impatto | Mitigazione |
|---|---|---|
| signal-cli instabile o breaking changes | Alto | Pinning versione Docker image, healthcheck con restart automatico |
| SIM Signal richiede ri-verifica | Medio | SIM fisica in un vecchio telefono acceso, o verifica iniziale e poi la SIM non serve più |
| Downtime miniPC | Alto | UPS per il miniPC; fallback briefing via email se Signal non risponde |
| OAuth Microsoft/Google scade | Medio | Refresh token automatico in n8n; workflow di alert se il refresh fallisce |
| Latenza risposte Claude | Basso | System prompt snello, richieste stateless (no cronologia lunga) |
| Community node Signal non mantenuto | Medio | Fallback: HTTP Request node di n8n verso le REST API di signal-cli |
| Messaggi duplicati (webhook retry) | Medio | Deduplicazione per signal_message_id in messages_inbox |

---

## 11. Nota sulla riservatezza dei dati

La crittografia end-to-end di Signal protegge i messaggi fino al gateway (signal-cli). Dopo la decrittazione, il contenuto viene elaborato localmente su n8n e, per le funzionalità AI e STT, inviato alle API cloud di Anthropic e OpenAI.

- **Dati che restano locali:** database SQLite, file audio temporanei, log di n8n
- **Dati che transitano in cloud:** testo dei messaggi (verso Claude API), audio dei vocali (verso Whisper API)

Trattandosi di un sistema personale-professionale ad uso esclusivo, il livello di rischio è accettabile. Si raccomanda di non inviare al segretario dati sensibili di clienti (codici fiscali, IBAN, dati patrimoniali) tramite messaggi vocali o testuali.

---

## 12. Struttura del progetto

```
segretario-ai/
├── 00_brief/          → project-context.md (questo documento)
├── 01_infra/          → docker-compose.yml, signal-cli-config/
├── 02_n8n/
│   ├── workflows/     → signal-webhook.json, intent-router.json,
│   │                    calendar-sync.json, task-manager.json, scheduler.json
│   └── prompts/       → system-prompt.md
├── 03_database/       → schema.sql, segretario.db
├── 04_docs/           → setup-guide.md (guida passo passo)
└── 05_test/           → test-scenarios.md
```

---

## 13. Prossimi passi immediati

- Acquistare una SIM prepagata (ho. Mobile, Iliad, o simile) da dedicare al segretario
- Installare Signal sul proprio smartphone Android per familiarizzare con l'interfaccia
- Verificare che il miniPC abbia Docker Compose aggiornato e spazio disco sufficiente
- Preparare le credenziali Microsoft 365 (Azure AD app registration per Graph API)
- Preparare le credenziali Google Cloud (OAuth per Google Calendar API)
- Ottenere una API key Anthropic (Claude API)

---

## 14. Changelog

### v2.0 — Aprile 2026

Modifiche rispetto alla v1.0, integrate a seguito di revisione critica:

- **Aggiunto principio operativo 2.8:** AI propone, logica esegue. Claude restituisce `needs_confirmation` in JSON; n8n decide se procedere o chiedere conferma.
- **Flusso 4.1 rafforzato:** persistenza messaggio grezzo in `messages_inbox` prima di qualsiasi elaborazione; deduplicazione per `signal_message_id`.
- **Schema database ampliato:** aggiunti campi `next_followup_at`, `snooze_until`, `source_message_id`, `calendar_event_id`, `updated_at` alla tabella task. Aggiunte tabelle `messages_inbox`, `messages_outbox`, `system_settings`.
- **Fasce di quiete nel MVP:** orari di silenzio, giorni esclusi e comando "non ricordarmelo più oggi" presenti fin dalla prima versione operativa.
- **Piano di implementazione riorganizzato** in fasi funzionali (A–E) con MVP che include i calendari (senza calendari il sistema non ha valore differenziante).
- **Aggiunto rischio "messaggi duplicati"** con mitigazione tramite deduplicazione.
- **Aggiunta sezione 11:** nota sintetica sulla riservatezza dei dati (perimetro locale vs cloud).
- **Aggiunto intent `snooze_oggi`** nel system prompt per silenziare i solleciti fino a fine giornata.
