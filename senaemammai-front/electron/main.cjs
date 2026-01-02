const { app, BrowserWindow } = require('electron')
const path = require('path')

// Use port 3001 as configured in Nuxt
const PORT = 3001
const isDev = process.env.NODE_ENV === 'development'

function createWindow() {
    const win = new BrowserWindow({
        width: 1200,
        height: 800,
        webPreferences: {
            nodeIntegration: false,
            contextIsolation: true,
            preload: path.join(__dirname, 'preload.js'),
            webSecurity: false
        }
    })

    // Handle new windows (target="_blank")
    win.webContents.setWindowOpenHandler(({ url }) => {
        // Allow creating new Electron windows for local app URLs
        if (url.startsWith('http://localhost') || url.startsWith('file://')) {
            return {
                action: 'allow',
                overrideBrowserWindowOptions: {
                    autoHideMenuBar: true,
                    // width: 1200, height: 800 // Inherit or default
                }
            }
        }

        // Open external links in default browser
        if (url.startsWith('http:') || url.startsWith('https:')) {
            require('electron').shell.openExternal(url)
            return { action: 'deny' }
        }
        return { action: 'allow' }
    })

    // In dev mode, load the Nuxt dev server. In prod, load the index.html
    if (isDev) {
        win.loadURL(`http://localhost:${PORT}`)
        // Open DevTools in dev mode
        win.webContents.openDevTools()
    } else {
        // In production, we expect the .output/public directory (SSG) or similar
        // For a simple Electron wrapping Nuxt, SSG ('npm run generate') is often easiest
        win.loadFile(path.join(__dirname, '../.output/public/index.html'))
    }
}

app.whenReady().then(() => {
    createWindow()

    app.on('activate', () => {
        if (BrowserWindow.getAllWindows().length === 0) {
            createWindow()
        }
    })
})

app.on('window-all-closed', () => {
    if (process.platform !== 'darwin') {
        app.quit()
    }
})
