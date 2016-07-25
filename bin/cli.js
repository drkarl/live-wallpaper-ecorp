#!/usr/bin/env node


// Modules (Node)
var path = require('path'),
    childProcess = require('child_process');

// Modules (External)
var electronPath = require('electron-prebuilt');


var args = process.argv.slice(2);  
args.unshift( __dirname + '/../' );

// Run
childProcess.spawn(electronPath, args , {
    stdio: 'inherit'
});