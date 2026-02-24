# 🕒 Dev Timetracker

A modern, multi-platform productivity suite for developers. Track your shift, manage breaks, and visualize your work patterns across **Desktop** and **Mobile**.

![Version](https://img.shields.io/badge/version-1.1.0-blue.svg)
![Desktop](https://img.shields.io/badge/platform-desktop%20(electron)-lightgrey.svg)
![Mobile](https://img.shields.io/badge/platform-mobile%20(flutter)-lightgrey.svg)

---

## 💻 Desktop Application (Electron)

A sleek, professional dark-themed application designed for your primary workstation.

### ✨ Key Features
*   **Smart Timer:** Track work remaining based on configurable shifts (Full-Day/Half-Day).
*   **Precision Break Management:** Dedicated "Add" and "Reduce" controls to manually adjust break time on the fly.
*   **Automatic ETA:** Real-time calculation of exactly when your workday will end, including all break offsets.
*   **Dev Scratchpad:** Built-in notes area for snippets, todos, and daily logs (Auto-saved).
*   **Activity Logging:** Every punch-in, break, and adjustment is logged locally for persistence.
*   **Auto-Updates:** Seamless background updates delivered via GitHub Releases.

---

## 📱 Mobile Application (Flutter)

A modern Material 3 viewer to keep track of your activities on the go.

### ✨ Key Features
*   **Modern UI:** Beautiful gradient-based design with professional dark mode and Material You components.
*   **Date-Wise Filtering:** Navigate through your historical logs with a dedicated date picker and day-by-day navigation.
*   **Visual Analytics:** 7-day activity trend charts and event distribution statistics (Bar charts/Distribution maps).
*   **Calendar View:** Full month overview with event markers and density indicators.
*   **Real-time Sync:** Powered by Firebase to ensure your desktop logs are visible on your mobile device instantly.

---

## 🚀 Getting Started

### Desktop (Renderer & Main)
1.  **Prerequisites:** Node.js (v16+)
2.  **Installation:**
    ```bash
    npm install
    npm start
    ```

### Mobile (Flutter)
1.  **Prerequisites:** Flutter SDK
2.  **Installation:**
    ```bash
    cd timetracker_mobile
    flutter pub get
    flutter run
    ```

---

## 🛠️ Built With
*   **Desktop:** Electron.js, SQLite, HTML5, CSS3 (Vanilla), JavaScript.
*   **Mobile:** Flutter, Dart, Firebase (Auth & Firestore), fl_chart.

---
Built by **Talha Shaikh**
