# E Corp (Evil Corp) Live Wallpaper [![Gitter](https://badges.gitter.im/sidneys/live-wallpaper-ecorp.svg)](https://gitter.im/sidneys/live-wallpaper-ecorp?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge) [![Issues](https://img.shields.io/github/issues/sidneys/live-wallpaper-ecorp.svg)](https://github.com/sidneys/live-wallpaper-ecorp/issues)   
[![badge](https://nodei.co/npm/live-wallpaper-ecorp.png?downloads=true)](https://www.npmjs.com/package/live-wallpaper-ecorp)
---
**live-wallpaper-ecorp** is a live (animated) wallpaper app showing the 'glitched' logo from the fictional [E Corp/Evil Corp](http://mrrobot.wikia.com/wiki/E_Corp) company, known from the [Mr. Robot](https://www.whoismrrobot.com) television show. Based on [Node.js](https://nodejs.org), [npm](https://www.npmjs.com) and [Electron](http://electron.atom.io).

*Not affiliated with USA Network, Anonymous Content, Universal Cable Productions or NBC Universal Television Distribution*.

## Demo

![macOS Screencast](https://github.com/sidneys/live-wallpaper-ecorp/raw/master/screenshots/screen-darwin-2.gif)   

## <a name="platforms"></a>Platforms

### macOS  
Tested on Sierra Developer Preview 2 (10.12), El Capitan (10.11), Yosemite (10.10)

### Linux 
Tested on Ubuntu Desktop 16.04, Ubuntu Desktop 14.04

## Installation

Download the latest version [here](https://github.com/sidneys/live-wallpaper-ecorp/releases).

### Linux

Install the *App Indicator Library* to enable Icon support:

```bash
sudo apt-get install libappindicator1
```

## Usage

To enable, simply launch the app.

To disable it, use the menu bar / system tray icons:

### macOS 
![macOS Tray](https://github.com/sidneys/live-wallpaper-ecorp/raw/master/screenshots/tray-darwin-1.gif)

### Linux
![Linux* Tray](https://github.com/sidneys/live-wallpaper-ecorp/raw/master/screenshots/tray-linux-1.gif)



## Developers

### Install the global npm package

```bash
npm install --global live-wallpaper-ecorp
```

### Run it via CLI

```bash
live-wallpaper-ecorp
```

## Roadmap

### Windows Version
At time of print, wallpaper apps - which are in essence Desktop applications claiming a special UI layer between the icon- and wallpaper space - are not readily implementable using the [Electron framework](http://electron.atom.io), due to current limitations of the [BrowserWindow](https://github.com/electron/electron/blob/master/docs/api/browser-window.md) API with regards to the Windows platform.

If this status quo changes, so will this application.


## <a name="author"></a>Author

[sidneys](http://sidneys.github.io)

## <a name="author"></a>The Show

<img data-canonical-src="https://upload.wikimedia.org/wikipedia/commons/4/4b/Mr._Robot_Logo.svg" src="https://upload.wikimedia.org/wikipedia/commons/4/4b/Mr._Robot_Logo.svg" width="200" />   
[whoismrrobot.com](https://www.whoismrrobot.com) 


