const { contextBridge, ipcRenderer, clipboard } = require("electron");

contextBridge.exposeInMainWorld("electronAPI", {
    authSuccess: (data) => ipcRenderer.send("auth-success", data),
    invoke: (channel, ...args) => ipcRenderer.invoke(channel, ...args),
    send: (channel, ...args) => ipcRenderer.send(channel, ...args),
    on: (channel, callback) => ipcRenderer.on(channel, (event, ...args) => callback(...args)),
    copyText: (text) => clipboard.writeText(text)
});