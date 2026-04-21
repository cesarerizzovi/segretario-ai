-- =============================================================================
-- Segretario AI — Schema SQLite
-- File: 03_database/schema.sql
-- Versione: 1.0 — Aprile 2026
-- =============================================================================
-- Istruzioni deploy:
--   sqlite3 ~/progetti/segretario-ai/03_database/segretario.db < schema.sql
-- =============================================================================

PRAGMA journal_mode = WAL;       -- Write-Ahead Logging: migliori prestazioni in lettura
PRAGMA foreign_keys = ON;        -- Abilita vincoli FK (disabilitati di default in SQLite)
PRAGMA encoding = 'UTF-8';

-- =============================================================================
-- TABELLA: task
-- Scopo: gestione attività con solleciti proattivi ed escalation
-- =============================================================================
CREATE TABLE IF NOT EXISTS task (
    id                  INTEGER PRIMARY KEY AUTOINCREMENT,
    descrizione         TEXT    NOT NULL,
    scadenza            DATETIME,                               -- NULL = nessuna scadenza
    priorita            TEXT    NOT NULL DEFAULT 'media'
                            CHECK (priorita IN ('alta', 'media', 'bassa')),
    stato               TEXT    NOT NULL DEFAULT 'aperto'
                            CHECK (stato IN ('aperto', 'completato', 'posticipato', 'annullato')),
    reminder_count      INTEGER NOT NULL DEFAULT 0,            -- n. solleciti già inviati
    ultimo_sollecito    DATETIME,                              -- timestamp ultimo sollecito
    next_followup_at    DATETIME,                              -- prossimo sollecito programmato
    snooze_until        DATETIME,                              -- silenzia fino a questa data/ora
    source_message_id   TEXT,                                  -- signal_message_id che ha generato il task
    calendar_event_id   TEXT,                                  -- ID evento calendario collegato
    categoria           TEXT,                                  -- es. cliente, fiscale, personale
    creato_il           DATETIME NOT NULL DEFAULT (datetime('now')),
    updated_at          DATETIME NOT NULL DEFAULT (datetime('now')),
    completato_il       DATETIME                               -- NULL se non completato
);

-- Indici task
CREATE INDEX IF NOT EXISTS idx_task_stato         ON task (stato);
CREATE INDEX IF NOT EXISTS idx_task_scadenza      ON task (scadenza);
CREATE INDEX IF NOT EXISTS idx_task_next_followup ON task (next_followup_at);
CREATE INDEX IF NOT EXISTS idx_task_snooze        ON task (snooze_until);

-- Trigger: aggiorna updated_at automaticamente a ogni modifica
CREATE TRIGGER IF NOT EXISTS task_updated_at
    AFTER UPDATE ON task
    FOR EACH ROW
BEGIN
    UPDATE task SET updated_at = datetime('now') WHERE id = OLD.id;
END;

-- =============================================================================
-- TABELLA: messages_inbox
-- Scopo: persistenza di ogni messaggio ricevuto prima di qualsiasi elaborazione.
--        Serve per audit, retry, debug e deduplicazione.
-- =============================================================================
CREATE TABLE IF NOT EXISTS messages_inbox (
    id                  INTEGER PRIMARY KEY AUTOINCREMENT,
    signal_message_id   TEXT    NOT NULL UNIQUE,               -- chiave deduplicazione
    testo_originale     TEXT,                                  -- testo o trascrizione vocale
    tipo                TEXT    NOT NULL
                            CHECK (tipo IN ('testo', 'vocale')),
    audio_path          TEXT,                                  -- percorso file audio (se vocale)
    stato_elaborazione  TEXT    NOT NULL DEFAULT 'ricevuto'
                            CHECK (stato_elaborazione IN ('ricevuto', 'elaborato', 'errore')),
    errore_dettaglio    TEXT,                                  -- descrizione errore (se stato = errore)
    ricevuto_il         DATETIME NOT NULL DEFAULT (datetime('now'))
);

-- Indice per ricerche per stato (utile per retry dei messaggi in errore)
CREATE INDEX IF NOT EXISTS idx_inbox_stato ON messages_inbox (stato_elaborazione);
CREATE INDEX IF NOT EXISTS idx_inbox_ricevuto ON messages_inbox (ricevuto_il);

-- =============================================================================
-- TABELLA: messages_outbox
-- Scopo: tracciamento di ogni risposta inviata dal segretario.
--        Utile per diagnosi e per sapere cosa è già stato comunicato.
-- =============================================================================
CREATE TABLE IF NOT EXISTS messages_outbox (
    id                  INTEGER PRIMARY KEY AUTOINCREMENT,
    inbox_message_id    INTEGER REFERENCES messages_inbox (id) ON DELETE SET NULL,
    testo_risposta      TEXT    NOT NULL,
    tipo                TEXT    NOT NULL
                            CHECK (tipo IN ('testo', 'vocale')),
    azione_eseguita     TEXT,                                  -- intent eseguito (crea_appuntamento, crea_task, ecc.)
    inviato_il          DATETIME NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_outbox_inviato ON messages_outbox (inviato_il);

-- =============================================================================
-- TABELLA: system_settings
-- Scopo: configurazioni operative modificabili senza toccare il codice.
--        Usa il pattern chiave/valore per massima flessibilità.
-- =============================================================================
CREATE TABLE IF NOT EXISTS system_settings (
    chiave              TEXT PRIMARY KEY,
    valore              TEXT NOT NULL,
    descrizione         TEXT,                                  -- documentazione del parametro
    updated_at          DATETIME NOT NULL DEFAULT (datetime('now'))
);

CREATE TRIGGER IF NOT EXISTS settings_updated_at
    AFTER UPDATE ON system_settings
    FOR EACH ROW
BEGIN
    UPDATE system_settings SET updated_at = datetime('now') WHERE chiave = OLD.chiave;
END;

-- Valori di default
INSERT OR IGNORE INTO system_settings (chiave, valore, descrizione) VALUES
    ('orario_quiete_inizio', '21:00', 'Ora inizio silenzio solleciti (formato HH:MM)'),
    ('orario_quiete_fine',   '07:30', 'Ora fine silenzio solleciti (formato HH:MM)'),
    ('giorni_esclusi',       'domenica', 'Giorni senza solleciti (separati da virgola)'),
    ('briefing_orario',      '07:30', 'Ora del briefing mattutino (formato HH:MM)'),
    ('frequenza_solleciti_ore', '3', 'Intervallo tra solleciti in ore (intero)'),
    ('escalation_soglia_chiamata', '4', 'Numero di solleciti dopo cui attivare telefonata/Pushover');

-- =============================================================================
-- FINE SCHEMA
-- =============================================================================
