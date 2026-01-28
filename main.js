if (require('electron-squirrel-startup')) return;

const { app, BrowserWindow, ipcMain, autoUpdater, dialog } = require('electron');
const path = require('path');
const db = require('./database.js');

// --- AUTO UPDATER LOGIC ---
if (app.isPackaged) {
    const server = 'https://update.electronjs.org';
    const feed = `${server}/talhaaa16/timetracker/${process.platform}-${process.arch}/${app.getVersion()}`;

    autoUpdater.setFeedURL({ url: feed });
    autoUpdater.checkForUpdates();

    setInterval(() => {
        autoUpdater.checkForUpdates();
    }, 5 * 60 * 1000);

    autoUpdater.on('update-downloaded', () => {
        BrowserWindow.getAllWindows().forEach(win => {
            win.webContents.send('update-downloaded');
        });
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

    // Manual Update Trigger
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