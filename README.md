# 🕒 Timetracker

A modern, multi-platform productivity suite for developers. Track your shift, manage breaks, and visualize your work patterns across **Desktop** and **Mobile**.

![Version](https://img.shields.io/badge/version-1.1.0-blue.svg)
![Desktop](https://img.shields.io/badge/platform-desktop%20(electron)-lightgrey.svg)
![Mobile](https://img.shields.io/badge/platform-mobile%20(flutter)-lightgrey.svg)
![API](https://img.shields.io/badge/platform-api%20(node.js)-lightgrey.svg)

---

## 💻 Desktop Application (Electron)

A sleek, professional dark-themed application designed for your primary workstation.

### ✨ Key Features
*   **Smart Timer:** Track work remaining based on configurable shifts (Full-Day/Half-Day).
*   **Precision Break Management:** Dedicated "Add" and "Reduce" controls to manually adjust break time on the fly.
*   **Automatic ETA:** Real-time calculation of exactly when your workday will end, including all break offsets.
*   **Dev Scratchpad:** Built-in notes area for snippets, todos, and daily logs (Auto-saved).
*   **Activity Logging:** Every punch-in, break, and adjustment is logged locally in SQLite and synced to MongoDB.
*   **Auto-Updates:** Seamless background updates delivered via GitHub Releases.

---

## 📱 Mobile Application (Flutter)

A modern Material 3 viewer to keep track of your activities on the go.

### ✨ Key Features
*   **Modern UI:** Beautiful gradient-based design with professional dark mode and Material You components.
*   **Date-Wise Filtering:** Navigate through your historical logs with a dedicated date picker and day-by-day navigation.
*   **Visual Analytics:** 7-day activity trend charts and event distribution statistics (Bar charts/Distribution maps).
*   **Real-time Sync:** Powered by a custom Node.js REST API to ensure your desktop logs are visible on your mobile device instantly.

---

## 🚀 Getting Started

### 1. Backend API (Node.js)
The mobile app and desktop app sync using this API.
1. **Prerequisites:** Node.js (v18+) and a MongoDB Cluster URL.
2. **Setup:** Create a `.env` file in the root directory with `MONGODB_CLUSTER_URL=your_url`.
3. **Run:**
   ```bash
   cd backend
   npm install
   npm start
   ```

### 2. Desktop App (Electron)
1. **Run:**
   ```bash
   npm install
   npm start
   ```

### 3. Mobile App (Flutter)
1. **Prerequisites:** Flutter SDK
2. **Run:**
   ```bash
   cd timetracker_mobile
   flutter pub get
   flutter run
   ```

---

## 🛠️ Built With
*   **Desktop:** Electron.js, SQLite, Vanilla JS.
*   **Mobile:** Flutter, Dart, Shared Preferences, http.
*   **Backend:** Node.js, Express, MongoDB, Mongoose.