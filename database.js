const Database = require('better-sqlite3');
const path = require('path');
const { app } = require('electron');

// Move the DB to the official AppData/Local folder to avoid permission issues
// Use try/catch because 'app' might be undefined during certain tests
let dbPath;
try {
  dbPath = path.join(app.getPath('userData'), 'punch_clock.db');
} catch (e) {
  dbPath = 'punch_clock.db';
}

const db = new Database(dbPath);

// Optimization: Enable Write-Ahead Logging for better performance
db.pragma('journal_mode = WAL');

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
    // Storing as ISO string is perfect for cross-platform apps
    const info = stmt.run(name, details, new Date().toISOString());
    return { id: info.lastInsertRowid, timestamp: new Date() };
  },

  // Increased limit slightly for the "Logs" view
  getLogs: () => db.prepare("SELECT * FROM logs ORDER BY id DESC LIMIT 100").all(),

  setSession: (key, val) => db.prepare("INSERT OR REPLACE INTO session (key, value) VALUES (?, ?)").run(key, JSON.stringify(val)),

  getSession: (key) => {
    const row = db.prepare("SELECT value FROM session WHERE key = ?").get(key);
    return row ? JSON.parse(row.value) : null;
  },

  clearData: () => {
    db.prepare("DELETE FROM logs").run();
    db.prepare("DELETE FROM session").run();
    // Vacuum cleans up the database file size after deletion
    db.prepare("VACUUM").run();
  }
};