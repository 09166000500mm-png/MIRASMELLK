CREATE TABLE IF NOT EXISTS calls (
 id INTEGER PRIMARY KEY AUTOINCREMENT,
 phone TEXT NOT NULL,
 status TEXT NOT NULL DEFAULT 'started',
 started_at TEXT NOT NULL,
 finished_at TEXT,
 property_type TEXT DEFAULT '',
 address TEXT DEFAULT '',
 area TEXT DEFAULT '',
 year_built TEXT DEFAULT '',
 floor TEXT DEFAULT '',
 units TEXT DEFAULT '',
 price TEXT DEFAULT '',
 notes TEXT DEFAULT ''
);