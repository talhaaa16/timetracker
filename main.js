if (require("electron-squirrel-startup")) {
    const { app } = require("electron");
    app.quit();
    process.exit(0);
}

const { app, BrowserWindow, ipcMain, autoUpdater } = require("electron");

// Disable Hardware Acceleration to prevent GPU crashes on startup
app.disableHardwareAcceleration();
app.commandLine.appendSwitch('disable-gpu');
app.commandLine.appendSwitch('disable-software-rasterizer');
app.commandLine.appendSwitch('disable-gpu-compositing');
app.commandLine.appendSwitch('disable-gpu-rasterization');
app.commandLine.appendSwitch('disable-gpu-sandbox');
app.commandLine.appendSwitch('disable-dev-shm-usage');

const path = require("path");

let mainWindow;
let db;
let currentUser = null;

function createWindow() {
    mainWindow = new BrowserWindow({
        width: 500,
        height: 750,
        resizable: true,
        icon: path.join(__dirname, "icon.ico"),
        webPreferences: {
            preload: path.join(__dirname, "preload.js"),
            nodeIntegration: false,
            contextIsolation: true,
            sandbox: false
        }
    });

    mainWindow.loadFile("login.html");
    mainWindow.setMenu(null);
}

ipcMain.on("auth-success", (_, userData) => {
    console.log("Main process received auth-success for:", userData.email);
    console.log("Authenticated UID:", userData.uid);

    currentUser = userData;

    mainWindow
        .loadFile(path.join(__dirname, "index.html"))
        .catch(err => console.error("Failed to load index.html:", err));
});


ipcMain.on("request-logout", () => {
    console.log("User logged out");
    currentUser = null;

    if (mainWindow) {
        mainWindow.loadFile("login.html");
    }
});

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

app.whenReady().then(() => {

    db = require("./database.js");

    createWindow();

    ipcMain.handle("get-user-profile", () => currentUser);

    ipcMain.handle("auth-login", async (_, email, password) => {
        return await db.login(email, password);
    });

    ipcMain.handle("auth-signup", async (_, email, password, firstName, lastName) => {
        return await db.signup(email, password, firstName, lastName);
    });

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
