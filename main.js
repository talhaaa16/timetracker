if (require('electron-squirrel-startup')) return;

const { app, BrowserWindow, ipcMain } = require('electron');
const path = require('path');
const db = require('./database.js');
const { updateElectronApp } = require('update-electron-app');

if (app.isPackaged) {
    updateElectronApp({
        updateInterval: '1 hour'
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

    ipcMain.handle('log-event', (event, name, details) => {
        return db.addLog(name, details);
    });

    ipcMain.handle('get-logs', () => {
        return db.getLogs();
    });

    ipcMain.handle('save-session', (event, key, val) => {
        db.setSession(key, val);
    });

    ipcMain.handle('get-session', (event, key) => {
        return db.getSession(key);
    });

    ipcMain.handle('clear-data', () => {
        return db.clearData();
    });
});

app.on('window-all-closed', () => {
    if (process.platform !== 'darwin') {
        app.quit();
    }
});