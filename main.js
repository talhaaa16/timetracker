if (require('electron-squirrel-startup')) return;

const { app, BrowserWindow, ipcMain, autoUpdater, dialog } = require('electron');
const path = require('path');
const db = require('./database.js');

// --- AUTO UPDATER LOGIC ---
if (app.isPackaged) {
    const server = 'https://update.electronjs.org';
    const feed = `${server}/talhaaa16/timetracker/${process.platform}-${process.arch}/${app.getVersion()}`;

    autoUpdater.setFeedURL({ url: feed });

    // Check immediately on startup
    autoUpdater.checkForUpdates();

    // Re-check every 5 minutes
    setInterval(() => {
        autoUpdater.checkForUpdates();
    }, 5 * 60 * 1000);

    // This event fires ONLY when the update is fully downloaded and ready
    autoUpdater.on('update-downloaded', (event, releaseNotes, releaseName) => {
        BrowserWindow.getAllWindows().forEach(win => {
            // MATCH THIS STRING in your index.html ipcRenderer.on()
            win.webContents.send('update-available-ui');
        });
    });

    // Handle update errors (good for debugging those "Access Denied" issues)
    autoUpdater.on('error', (message) => {
        console.error('There was a problem updating the application');
        console.error(message);
    });
}

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

app.whenReady().then(() => {
    createWindow();

    ipcMain.handle('log-event', (event, name, details) => db.addLog(name, details));
    ipcMain.handle('get-logs', () => db.getLogs());
    ipcMain.handle('save-session', (event, key, val) => db.setSession(key, val));
    ipcMain.handle('get-session', (event, key) => db.getSession(key));
    ipcMain.handle('clear-data', () => db.clearData());

    // Triggered when user clicks "Restart & Update" button in UI
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