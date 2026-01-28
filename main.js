// 1. Handle Squirrel events immediately (CRITICAL)
// This MUST stay at the very top to prevent multiple instances during install/update
if (require('electron-squirrel-startup')) {
    const { app } = require('electron');
    app.quit();
    // Use process.exit to ensure the process terminates before DB logic starts
    process.exit(0);
}

const { app, BrowserWindow, ipcMain, autoUpdater } = require('electron');
const path = require('path');

// 2. DEFINE DB VARIABLE (Don't 'require' it yet)
let db;

function createWindow() {
    const win = new BrowserWindow({
        width: 500,
        height: 750,
        resizable: true,
        icon: path.join(__dirname, 'icon.ico'),
        webPreferences: {
            nodeIntegration: true,
            contextIsolation: false
        }
    });

    win.loadFile('index.html');
    win.setMenu(null);
}

// --- AUTO UPDATER LOGIC ---
if (app.isPackaged) {
    const server = 'https://update.electronjs.org';
    const feed = `${server}/talhaaa16/timetracker/${process.platform}-${process.arch}/${app.getVersion()}`;

    autoUpdater.setFeedURL({ url: feed });

    // Important: Wait 10 seconds before checking for updates on startup
    // This prevents Squirrel from locking the update file while we check
    app.on('ready', () => {
        setTimeout(() => {
            autoUpdater.checkForUpdates();
        }, 10000);
    });

    setInterval(() => {
        autoUpdater.checkForUpdates();
    }, 5 * 60 * 1000);

    autoUpdater.on('update-downloaded', (event, releaseNotes, releaseName) => {
        BrowserWindow.getAllWindows().forEach(win => {
            win.webContents.send('update-available-ui');
        });
    });

    autoUpdater.on('error', (message) => {
        console.error('Update Error:', message);
    });
}

// 3. START DATABASE ONLY WHEN APP IS READY
app.whenReady().then(() => {
    // Require your database logic here so it doesn't lock files during the Squirrel setup
    db = require('./database.js');

    createWindow();

    ipcMain.handle('log-event', (event, name, details) => db.addLog(name, details));
    ipcMain.handle('get-logs', () => db.getLogs());
    ipcMain.handle('save-session', (event, key, val) => db.setSession(key, val));
    ipcMain.handle('get-session', (event, key) => db.getSession(key));
    ipcMain.handle('clear-data', () => db.clearData());

    ipcMain.on('restart-app', () => {
        autoUpdater.quitAndInstall();
    });

    ipcMain.handle('check-for-updates', () => {
        if (app.isPackaged) {
            autoUpdater.checkForUpdates();
            return "Checking...";
        }
        return "Not packaged";
    });
});

app.on('window-all-closed', () => {
    if (process.platform !== 'darwin') app.quit();
});