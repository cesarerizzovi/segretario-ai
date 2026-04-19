CREATE TABLE IF NOT EXISTS task (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    descrizione TEXT NOT NULL,
    scadenza DATETIME,
    priorita TEXT DEFAULT 'media',
    stato TEXT NOT NULL DEFAULT 'aperto',
    reminder_count INTEGER NOT NULL DEFAULT 0,
    ultimo_sollecito DATETIME,
    next_followup_at DATETIME,
    snooze_until DATETIME,
    source_message_id TEXT,
    calendar_event_id TEXT,
    creato_il DATETIME NOT NULL DEFAULT (datetime('now')),
    updated_at DATETIME NOT NULL DEFAULT (datetime('now')),
    completato_il DATETIME,
    categoria TEXT
);

CREATE TABLE IF NOT EXISTS messages_inbox (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    signal_message_id TEXT UNIQUE NOT NULL,
    testo_originale TEXT,
    tipo TEXT NOT NULL DEFAULT 'testo',
    audio_path TEXT,
    stato_elaborazione TEXT NOT NULL DEFAULT 'ricevuto',
    ricevuto_il DATETIME NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS messages_outbox (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    inbox_message_id INTEGER,
    testo_risposta TEXT NOT NULL,
    tipo TEXT NOT NULL DEFAULT 'testo',
    azione_eseguita TEXT,
    inviato_il DATETIME NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS system_settings (
    chiave TEXT PRIMARY KEY,
    valore TEXT NOT NULL
);

INSERT OR IGNORE INTO system_settings (chiave, valore) VALUES
    ('orario_quiete_inizio', '21:00'),
    ('orario_quiete_fine', '07:30'),
    ('giorni_esclusi', 'domenica'),
    ('briefing_orario', '07:30'),
    ('frequenza_solleciti_ore', '3');

CREATE TRIGGER IF NOT EXISTS update_task_timestamp
AFTER UPDATE ON task
BEGIN
    UPDATE task SET updated_at = datetime('now') WHERE id = NEW.id;
END;
