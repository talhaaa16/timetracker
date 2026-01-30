const Database = require("better-sqlite3");
const path = require("path");
const { app } = require("electron");

/* ============================
   FIREBASE ADMIN SDK (DESKTOP)
   ============================ */
const admin = require("firebase-admin");

// 🔐 Load service account key
const serviceAccount = require(
  path.join(__dirname, "serviceAccountKey.json")
);

// Initialize Admin SDK (ONLY ONCE)
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
}

const firestore = admin.firestore();

/* ============================
   SQLITE SETUP
   ============================ */
let dbPath;
try {
  dbPath = path.join(app.getPath("userData"), "punch_clock.db");
} catch (e) {
  dbPath = "punch_clock.db";
}

const db = new Database(dbPath);
db.pragma("journal_mode = WAL");

/* ============================
   TABLES
   ============================ */
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
  /* ============================
     ADD LOG (LOCAL + FIRESTORE)
     ============================ */
  addLog: async (name, details = "", uid = null) => {
    const isoTimestamp = new Date().toISOString();

    // 1️⃣ Save locally (SQLite)
    const stmt = db.prepare(
      "INSERT INTO logs (event_name, details, timestamp) VALUES (?, ?, ?)"
    );
    const info = stmt.run(name, details, isoTimestamp);

    // 2️⃣ Save to Firestore (ADMIN SDK → bypass rules)
    if (uid) {
      try {
        await firestore
          .collection("users")
          .doc(uid)
          .collection("logs")
          .add({
            event_name: name,
            details: details,
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
          });

        console.log("✔ Log synced to Firestore");
      } catch (err) {
        console.error("❌ Firestore sync failed:", err.message);
      }
    } else {
      console.warn("⚠ No UID provided, Firestore sync skipped");
    }

    return { id: info.lastInsertRowid, timestamp: isoTimestamp };
  },

  /* ============================
     READ LOCAL LOGS
     ============================ */
  getLogs: () => {
    return db
      .prepare("SELECT * FROM logs ORDER BY id DESC LIMIT 100")
      .all();
  },

  /* ============================
     SESSION STORAGE
     ============================ */
  setSession: (key, val) => {
    return db
      .prepare("INSERT OR REPLACE INTO session (key, value) VALUES (?, ?)")
      .run(key, JSON.stringify(val));
  },

  getSession: (key) => {
    const row = db
      .prepare("SELECT value FROM session WHERE key = ?")
      .get(key);
    return row ? JSON.parse(row.value) : null;
  },

  clearData: () => {
    db.prepare("DELETE FROM logs").run();
    db.prepare("DELETE FROM session").run();
    db.prepare("VACUUM").run();
  },
};
