const Database = require("better-sqlite3");
const path = require("path");
const { app } = require("electron");
const { MongoClient, ObjectId } = require("mongodb");
const bcrypt = require("bcryptjs");
require("dotenv").config({ path: path.join(__dirname, ".env") });

let mongoClient = null;
let mongoDb = null;

if (process.env.MONGODB_CLUSTER_URL) {
    mongoClient = new MongoClient(process.env.MONGODB_CLUSTER_URL);
    mongoClient.connect()
        .then(() => {
            mongoDb = mongoClient.db("timetracker");
            console.log("✔ Connected to MongoDB successfully");
        })
        .catch(err => console.error("❌ MongoDB connection failed:", err.message));
}

let dbPath;
try {
  dbPath = path.join(app.getPath("userData"), "punch_clock.db");
} catch (e) {
  dbPath = "punch_clock.db";
}

const db = new Database(dbPath);
db.pragma("journal_mode = WAL");

db.exec(`
  CREATE TABLE IF NOT EXISTS logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    uid TEXT,
    event_name TEXT,
    details TEXT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
  );

  CREATE TABLE IF NOT EXISTS session (
    key TEXT PRIMARY KEY,
    value TEXT
  );
`);

// Safely add uid column for existing users (will throw if it already exists, which is fine)
try {
  db.prepare("ALTER TABLE logs ADD COLUMN uid TEXT").run();
} catch (e) {
  // column exists
}

module.exports = {
  login: async (email, password) => {
      if (!mongoDb) return { success: false, error: "MongoDB not connected" };
      const user = await mongoDb.collection("users").findOne({ email });
      if (!user) return { success: false, error: "User not found" };
      
      const isMatch = await bcrypt.compare(password, user.password);
      if (!isMatch) return { success: false, error: "Invalid password" };
      
      return {
          success: true,
          userData: {
              uid: user._id.toString(),
              email: user.email,
              firstName: user.firstName,
              lastName: user.lastName
          }
      };
  },

  signup: async (email, password, firstName, lastName) => {
      if (!mongoDb) return { success: false, error: "MongoDB not connected" };
      
      const existing = await mongoDb.collection("users").findOne({ email });
      if (existing) return { success: false, error: "Email already exists" };
      
      const hashedPassword = await bcrypt.hash(password, 10);
      const result = await mongoDb.collection("users").insertOne({
          email,
          password: hashedPassword,
          firstName,
          lastName,
          createdAt: new Date()
      });
      
      return {
          success: true,
          userData: {
              uid: result.insertedId.toString(),
              email,
              firstName,
              lastName
          }
      };
  },

  addLog: async (name, details = "", uid = null) => {
    const isoTimestamp = new Date().toISOString();

    const stmt = db.prepare(
      "INSERT INTO logs (uid, event_name, details, timestamp) VALUES (?, ?, ?, ?)"
    );
    const info = stmt.run(uid, name, details, isoTimestamp);

    if (uid && mongoDb) {
      try {
        await mongoDb.collection("logs").insertOne({
            uid: uid,
            event_name: name,
            details: details,
            timestamp: new Date()
        });
        console.log("✔ Log synced to MongoDB");
      } catch (err) {
        console.error("❌ MongoDB sync failed:", err.message);
      }
    } else {
      console.warn("⚠ No UID or MongoDB not connected, sync skipped");
    }

    return { id: info.lastInsertRowid, timestamp: isoTimestamp };
  },

  getLogs: (uid) => {
    return db
      .prepare("SELECT * FROM logs WHERE uid = ? ORDER BY id DESC LIMIT 100")
      .all(uid);
  },

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

  clearSession: () => {
    db.prepare("DELETE FROM session").run();
  },
};
