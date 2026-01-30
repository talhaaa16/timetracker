if (require("electron-squirrel-startup")) {
    const { app } = require("electron");
    app.quit();
    process.exit(0);
}

const { app, BrowserWindow, ipcMain, autoUpdater } = require("electron");
const path = require("path");

let mainWindow;
let db;
let currentUser = null;

/* ============================
   CREATE WINDOW
   ============================ */
function createWindow() {
    mainWindow = new BrowserWindow({
        width: 500,
        height: 750,
        resizable: true,
        icon: path.join(__dirname, "icon.ico"),
        webPreferences: {
            preload: path.join(__dirname, "preload.js"),
            nodeIntegration: false,
            contextIsolation: true
        }
    });

    mainWindow.loadFile("login.html");
    mainWindow.setMenu(null);
}

/* ============================
   AUTH SUCCESS (FROM RENDERER)
   ============================ */
ipcMain.on("auth-success", (_, userData) => {
    console.log("Main process received auth-success for:", userData.email);
    console.log("Authenticated UID:", userData.uid);

    currentUser = userData;

    mainWindow
        .loadFile(path.join(__dirname, "index.html"))
        .catch(err => console.error("Failed to load index.html:", err));
});

/* ============================
   LOGOUT
   ============================ */
ipcMain.on("request-logout", () => {
    console.log("User logged out");
    currentUser = null;

    if (mainWindow) {
        mainWindow.loadFile("login.html");
    }
});

/* ============================
   AUTO UPDATE (PRODUCTION ONLY)
   ============================ */
if (app.isPackaged) {
    const server = "https://update.electronjs.org";
    const feed = `${server}/talhaaa16/timetracker/${process.platform}-${process.arch}/${app.getVersion()}`;

    autoUpdater.setFeedURL({ url: feed });

    app.on("ready", () => {
        setTimeout(() => autoUpdater.checkForUpdates(), 10000);
    });

    setInterval(() => autoUpdater.checkForUpdates(), 5 * 60 * 1000);

    autoUpdater.on("update-downloaded", () => {
        BrowserWindow.getAllWindows().forEach(win => {
            win.webContents.send("update-available-ui");
        });
    });

    autoUpdater.on("error", err =>
        console.error("AutoUpdater error:", err)
    );
}

/* ============================
   APP READY
   ============================ */
app.whenReady().then(() => {
    // 🔥 Database loads AFTER app is ready
    db = require("./database.js");

    createWindow();

    ipcMain.handle("get-user-profile", () => currentUser);

    ipcMain.handle("log-event", async (_, name, details) => {
        if (!currentUser || !currentUser.uid) {
            console.warn(
                "log-event called without authenticated user. Local only."
            );
            return db.addLog(name, details, null);
        }

        console.log(
            `Logging event "${name}" for UID: ${currentUser.uid}`
        );

        return db.addLog(name, details, currentUser.uid);
    });

    ipcMain.handle("get-logs", () => db.getLogs());

    ipcMain.handle("save-session", (_, key, val) =>
        db.setSession(key, val)
    );

    ipcMain.handle("get-session", (_, key) =>
        db.getSession(key)
    );

    ipcMain.handle("clear-data", () => db.clearData());

    ipcMain.on("restart-app", () => autoUpdater.quitAndInstall());
});


app.on("window-all-closed", () => {
    if (process.platform !== "darwin") {
        app.quit();
    }
});
