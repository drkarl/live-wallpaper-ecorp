'use strict';


/**
 * @global
 * @constant
 * @default
 */
var TARGET_DISPLAY_INDEX = 0;

/**
 * Modules: Electron
 * @global
 */
var electron = require('electron'),
    app = electron.app,
    BrowserWindow = electron.BrowserWindow,
    Tray = electron.Tray,
    Menu = electron.Menu;

/**
 * Modules: Node
 * @global
 */
var path = require('path');

/**
 * Modules: Internal
 * @global
 */
var appRoot = path.resolve('.'),
    packageJson = require(appRoot + '/package.json'),
    platform = require(appRoot + '/lib/platform');

/**
 * @global
 */
var mainWindow,
    mainPage,
    appTray;

/**
 * @global
 * @constant
 */
var appUrl = 'file://' + appRoot + '/app/index.html',
    appName = packageJson.name,
    appVersion = packageJson.version,
    appTrayIconDefault = path.join(appRoot, 'icons', platform.type, 'icon-tray' + platform.image(platform.type));


/**
 * Main
 */
app.on('ready', function() {
    // Create the browser window.
    var displays = electron.screen.getAllDisplays();
    var mainDisplay = displays[0];
    var targetDisplay = displays[TARGET_DISPLAY_INDEX] || mainDisplay;

    // Browser Window
    mainWindow = new BrowserWindow({
        show: false,
        hasShadow: false,
        movable: false,
        resizable: false,
        frame: false,
        type: 'desktop',
        x: targetDisplay.workArea.x,
        y: targetDisplay.workArea.y,
        width: targetDisplay.bounds.width,
        height: targetDisplay.bounds.height
    });

    // and load the index.html of the app.
    mainWindow.loadURL(appUrl);

    // Emitted when the window is closed.
    mainWindow.on('closed', function() {
        mainWindow = null;
    });

    // Web Contents
    mainPage = mainWindow.webContents;

    mainPage.on('dom-ready', () => {
        mainWindow.show();
        // Open the DevTools.
        // mainPage.openDevTools();
    });

    // Tray
    appTray = new Tray(appTrayIconDefault);
    appTray.setImage(appTrayIconDefault);
    appTray.setToolTip(appName);
    appTray.setContextMenu(Menu.buildFromTemplate([
        {
            label: appName + ' ' + appVersion, enabled: false
        },
        {
            type: 'separator'
        },
        {
            label: 'Quit', click() { app.quit(); }
        }
    ]));

    // Dock
    if (platform.isOSX) {
        app.dock.hide();
    }
});
