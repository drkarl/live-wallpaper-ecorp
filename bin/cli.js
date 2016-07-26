#!/usr/bin/env node


/**
 * Modules: Node
 * @global
 */
var path = require('path'),
    childProcess = require('child_process');

/**
 * Modules: External
 * @global
 */
var appRoot = require('app-root-path').path,
    electronPath = require('electron-prebuilt');

/**
 * Modules: Internal
 * @global
 */
var packageJson = require('../package.json');

/**
 * Path to Electron application
 * @global
 */
var appMain = path.join(appRoot, packageJson.main);


// Run
childProcess.spawn(electronPath, [ appMain ], {
    stdio: 'inherit'
});
