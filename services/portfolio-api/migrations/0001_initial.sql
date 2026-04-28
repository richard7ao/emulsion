CREATE TABLE IF NOT EXISTS portfolios (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    bio TEXT NOT NULL,
    photo_path TEXT,
    summary TEXT NOT NULL,
    created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS experiences (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    portfolio_id INTEGER NOT NULL REFERENCES portfolios(id),
    company TEXT NOT NULL,
    role TEXT NOT NULL,
    dates TEXT NOT NULL,
    bullets TEXT NOT NULL DEFAULT '[]'
);

CREATE TABLE IF NOT EXISTS projects (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    portfolio_id INTEGER NOT NULL REFERENCES portfolios(id),
    title TEXT NOT NULL,
    role TEXT NOT NULL,
    writeup TEXT NOT NULL,
    screenshots TEXT NOT NULL DEFAULT '[]',
    view_count INTEGER NOT NULL DEFAULT 0,
    interested_count INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS skills (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    portfolio_id INTEGER NOT NULL REFERENCES portfolios(id),
    category TEXT NOT NULL,
    items TEXT NOT NULL DEFAULT '[]'
);

CREATE TABLE IF NOT EXISTS qa_pairs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    portfolio_id INTEGER NOT NULL REFERENCES portfolios(id),
    prompt TEXT NOT NULL,
    answer TEXT NOT NULL,
    is_canned INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE IF NOT EXISTS notes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    portfolio_id INTEGER NOT NULL REFERENCES portfolios(id),
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    message TEXT NOT NULL,
    created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS conversations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    portfolio_id INTEGER NOT NULL REFERENCES portfolios(id),
    participant_name TEXT NOT NULL,
    last_message TEXT NOT NULL,
    updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS messages (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    conversation_id INTEGER NOT NULL REFERENCES conversations(id),
    sender TEXT NOT NULL,
    body TEXT NOT NULL,
    created_at TEXT NOT NULL DEFAULT (datetime('now'))
);
