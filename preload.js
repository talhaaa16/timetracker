const { contextBridge, ipcRenderer, clipboard } = require("electron");
const path = require("path");
require("dotenv").config({ path: path.join(__dirname, ".env") });

contextBridge.exposeInMainWorld("env", {
    FIREBASE_API_KEY: process.env.FIREBASE_API_KEY?.trim(),
    FIREBASE_AUTH_DOMAIN: process.env.FIREBASE_AUTH_DOMAIN?.trim(),
    FIREBASE_PROJECT_ID: process.env.FIREBASE_PROJECT_ID?.trim(),
    FIREBASE_STORAGE_BUCKET: process.env.FIREBASE_STORAGE_BUCKET?.trim(),
    FIREBASE_MESSAGING_SENDER_ID: process.env.FIREBASE_MESSAGING_SENDER_ID?.trim(),
    FIREBASE_APP_ID: process.env.FIREBASE_APP_ID?.trim(),
    FIREBASE_MEASUREMENT_ID: process.env.FIREBASE_MEASUREMENT_ID?.trim(),
});

contextBridge.exposeInMainWorld("electronAPI", {
    authSuccess: (data) => ipcRenderer.send("auth-success", data),
    invoke: (channel, ...args) => ipcRenderer.invoke(channel, ...args),
    send: (channel, ...args) => ipcRenderer.send(channel, ...args),
    on: (channel, callback) => ipcRenderer.on(channel, (event, ...args) => callback(...args)),
    copyText: (text) => clipboard.writeText(text)
});