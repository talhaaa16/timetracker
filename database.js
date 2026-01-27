const Database = require('better-sqlite3');
const path = require('path');
const db = new Database('punch_clock.db');

// Create tables if they don't exist
db.exec(`
  CREATE TABLE IF NOT EXISTS logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    event_name TEXT,
    details TEXT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
  );
  CREATE TABLE IF NOT EXISTS session (
    key TEXT PRIMARY KEY,
    value TEXT
  );
`);

module.exports = {
  addLog: (name, details = '') => {
    const stmt = db.prepare("INSERT INTO logs (event_name, details, timestamp) VALUES (?, ?, ?)");
    const info = stmt.run(name, details, new Date().toISOString());
    return { id: info.lastInsertRowid, timestamp: new Date() };
  },
  getLogs: () => db.prepare("SELECT * FROM logs ORDER BY id DESC LIMIT 50").all(),
  setSession: (key, val) => db.prepare("INSERT OR REPLACE INTO session (key, value) VALUES (?, ?)").run(key, JSON.stringify(val)),
  getSession: (key) => {
    const row = db.prepare("SELECT value FROM session WHERE key = ?").get(key);
    return row ? JSON.parse(row.value) : null;
  },
  clearData: () => {
    db.prepare("DELETE FROM logs").run();
    db.prepare("DELETE FROM session").run();
  }
};