const { contextBridge, ipcRenderer } = require('electron')

contextBridge.exposeInMainWorld('electron', {
    // Add safe APIs here if needed
    // example: doSomething: () => ipcRenderer.invoke('do-something')
})
