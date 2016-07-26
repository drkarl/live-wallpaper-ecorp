'use strict';


/**
 * Modules
 * Node
 */
const fs = require('fs'),
    path = require('path'),
    mkdirp = require('mkdirp');


/**
 * Modules
 * External
 */
const rimraf = require('rimraf'),
    ZipPaths = require('zip-paths'),
    filesize = require('filesize');


/**
 * Modules
 * Internal
 */
const appRoot = appRoot = path.join(__dirname, '..'),
    packageJson = require(path.join(appRoot, 'package.json')),
    platform = require(path.join(appRoot, 'lib', 'platform')),
    logger = require(path.join(appRoot, 'lib', 'logger'));


/**
 * Modules
 * Build & Package
 */
let packager = require('electron-packager'),
    darwinInstaller, windowsInstaller, linuxInstaller;

if (platform.isDarwin) {
    darwinInstaller = require('appdmg');
    windowsInstaller = require('electron-winstaller');
    linuxInstaller = require('electron-installer-debian');
}

if (platform.isWindows) {
    windowsInstaller = require('electron-winstaller');
}

if (platform.isLinux) {
    linuxInstaller = require('electron-installer-debian');
}


/**
 * Options for electron-packager
 */
let createBuildOptions = function(platformName) {

    let appFileName = function() {
            let name = packageJson.build.name || packageJson.name;
            return (name.replace(/_|-|\s+/g, '').toLowerCase());
        },
        appVersion = function() {
            return (packageJson.build.version || packageJson.version);
        },
        appBuildVersion = new Date().toJSON().replace(/T|Z|-|:|\./g, '');

    return {
        'dir': appRoot,
        'out': path.join(appRoot, packageJson.build.directoryStaging),
        'icon': path.join(appRoot, 'icons', platformName, 'icon-app' + platform.icon(platformName)),
        'iconUrl': packageJson.build.iconUrl,
        'platform': platformName,
        'arch': 'all',
        'prune': true,
        'asar': true,
        'overwrite': true,
        'name': appFileName(),
        'version': packageJson.build.electronVersion,
        'app-version': appVersion(),
        'build-version': appBuildVersion,
        'app-bundle-id': packageJson.build.id,
        'app-company': packageJson.build.company,
        'app-category-type': packageJson.build.category,
        'helper-bundle-id': packageJson.build.id + '.helper',
        'app-copyright': 'Copyright © ' + new Date().getFullYear(),
        'download': {
            'cache': path.join(appRoot, packageJson.build.directoryCache)
        },
        'description': packageJson.build.productDescription,
        'ignore': [
            path.relative(appRoot, path.join(appRoot, packageJson.build.directoryCache)) + '($|/)',
            path.relative(appRoot, path.join(appRoot, packageJson.build.directoryRelease)) + '($|/)',
            path.relative(appRoot, path.join(appRoot, packageJson.build.directoryStaging)) + '($|/)',
            platformName !== 'darwin' ? path.relative(appRoot, path.join(appRoot, 'icons', 'darwin')) + '($|/)' : null,
            platformName !== 'darwin' ? path.relative(appRoot, path.join(appRoot, 'icons', 'win32')) + '($|/)' : null,
            platformName !== 'darwin' ? path.relative(appRoot, path.join(appRoot, 'icons', 'linux')) + '($|/)' : null,
            path.relative(appRoot, path.join(appRoot, 'resources')) + '($|/)',
            path.relative(appRoot, path.join(appRoot, 'cache')) + '($|/)',
            '/\\.DS_Store($|/)', '/\\.idea($|/)', '/\\.editorconfig($|/)',
            '/\\.gitignore($|/)', '/\\.npmignore($|/)',
            '/\\.jscsrc($|/)', '/\\.jshintrc($|/)'
        ],
        'version-string': {
            CompanyName: packageJson.build.company,
            FileDescription: packageJson.build.productDescription,
            OriginalFilename: appFileName(),
            FileVersion: appVersion(),
            ProductVersion: appVersion(),
            ProductName: appFileName(),
            InternalName: appFileName()
        },
        'productName': packageJson.build.productName,
        'productDescription': packageJson.build.productDescription
    };
};


/**
 * Commandline platform override (default: build all platforms)
 * @example > npm run build darwin
 * @example > npm run build win32
 */
let platformListCli = function() {
    return process.argv.slice(3);
};


/**
 * Create files / folders
 * @param {...*} arguments - Filesystem paths
 */
let createOnFilesystem = function() {
    let args = Array.from(arguments);
    for (let value of args) {
        mkdirp.sync(path.resolve(value));
        logger.log('Creating', path.resolve(value));
    }
};


/**
 * Delete folders / files recursively
 * @param {...*} arguments - Filesystem paths
 */
let deleteFromFilesystem = function() {
    let args = Array.from(arguments);
    for (let value of args) {
        rimraf.sync(path.resolve(value) + '/**/*');
    }
};


/**
 * Zip folders
 * @param {String} sourceFilepath - Directory to compress
 * @param {String=} allowedExtension - Restrict inclusion to files with this extension (e.g. '.exe')
 * @param {String} platformName - Current Platform
 */
let moveFolderToPackage = function(sourceFilepath, allowedExtension, platformName) {

    let source = path.resolve(sourceFilepath),
        sourceBasepath = path.dirname(source),
        sourceGlob = fs.statSync(source).isDirectory() === true ? path.basename(source) + '/**/*' : path.basename(source),
        targetExtension = '.zip',
        outputFile = path.join(path.dirname(source), path.basename(source)) + targetExtension;

    let inputPattern = allowedExtension ? sourceGlob + '*' + allowedExtension : sourceGlob;

    // Packing a directory
    let zip = new ZipPaths(outputFile);

    zip.add(inputPattern,
        {
            cwd: sourceBasepath
        }, function(err) {
            if (err) {
                return logger.logErr('error (packaging)', err);
            }
            zip.compress(function(err, bytes) {
                if (err) {
                    return logger.logErr('error (compression)', err);
                }
                rimraf.sync(source);

                if (err) {
                    logger.logErr('error (text-to-speech)', err);
                }
                logger.log('package ready', platformName + ' (' + path.basename(outputFile) + ', ' + filesize(bytes, { base: 10 }) + ')');

            });
        });
};


/**
 * Platform Target List
 */
let platformList = function() {

    var platforms = packageJson.build.platforms || [];

    if ((platformListCli() !== 'undefined') && (platformListCli().length > 0)) {
        platforms = platformListCli();
    }

    if (platform.isWindows) {
        platforms = ['win32'];
    }
    if (platform.isLinux) {
        platforms = ['linux'];
    }

    return platforms;
};


/**
 * Darwin Deployment
 * @param {Array} buildArtifactList - Directory to compress
 * @param {Object} buildOptions - electron-packager options object
 * @param {String} platformName - Current Platform
 * @param {String} deployFolder - Deployment parent folder
 */
let deployDarwin = function(buildArtifactList, buildOptions, platformName, deployFolder) {

    buildArtifactList.forEach(function(buildArtifact) {

        // Deployment: Architecture
        let architectureName = path.basename(buildArtifact).indexOf('x64') > 1 ? 'x64' : 'ia32';

        // Deployment: Input folder
        let inputFolder = path.join(buildArtifact, buildOptions.name + '.app');

        // Deployment: Target folder
        let deploySubfolder = path.join(path.resolve(deployFolder), path.basename(buildArtifact).replace(/\s+/g, '_').toLowerCase() + '-v' + buildOptions['app-version']);

        // Deployment: Installer extension
        let deployExtension = '.dmg';

        // Deployment: Options
        let deployOptions = {
            arch: architectureName,
            target: path.join(deploySubfolder, path.basename(deploySubfolder) + deployExtension),
            basepath: '',
            specification: {
                'title': buildOptions['productName'],
                'window': {
                    'size': {
                        'width': 640,
                        'height': 240
                    }
                },
                'contents': [
                    { 'x': 608, 'y': 95, 'type': 'link', 'path': '/Applications' },
                    { 'x': 192, 'y': 95, 'type': 'file', 'path': inputFolder },
                    // Hiding invisible files
                    // https://github.com/LinusU/node-appdmg/issues/45
                    { 'x': 10000, 'y': 10000, 'type': 'position', 'path': '.background' },
                    { 'x': 10000, 'y': 10000, 'type': 'position', 'path': '.DS_Store' },
                    { 'x': 10000, 'y': 10000, 'type': 'position', 'path': '.Trashes' },
                    { 'x': 10000, 'y': 10000, 'type': 'position', 'path': '.VolumeIcon.icns' }
                ]
            }
        };

        // Platform Options
        // logger.log('deploy options', platformName, deployOptions);

        // Deployment: Subfolder
        deleteFromFilesystem(deploySubfolder);
        createOnFilesystem(deploySubfolder);

        // Deployment: Start
        let deployHelper = darwinInstaller(deployOptions);

        // Deployment: Result
        deployHelper.on('finish', function() {
            moveFolderToPackage(deploySubfolder, deployExtension, platformName);
        });
        deployHelper.on('error', function(err) {
            logger.log('Error (Deploy)', err);
            return process.exit(1);
        });
    });
};


/**
 * Windows Deployment
 * @param {Array} buildArtifactList - Directory to compress
 * @param {Object} buildOptions - electron-packager options object
 * @param {String} platformName - Current Platform type
 * @param {String} deployFolder - Deployment parent folder
 */
let deployWindows = function(buildArtifactList, buildOptions, platformName, deployFolder) {

    buildArtifactList.forEach(function(buildArtifact) {

        // Deployment: Architecture
        let architectureName = path.basename(buildArtifact).indexOf('x64') > 1 ? 'x64' : 'ia32';

        // Deployment: Input folder
        let inputFolder = path.join(buildArtifact);

        // Deployment: Target folder
        let deploySubfolder = path.join(path.resolve(deployFolder), path.basename(buildArtifact).replace(/\s+/g, '_').toLowerCase() + '-v' + buildOptions['app-version']);

        // Deployment: Installer extension
        let deployExtension = '.exe';

        // Deployment: Options
        let deployOptions = {
            arch: architectureName,
            version: buildOptions['app-version'],
            appDirectory: inputFolder,
            outputDirectory: deploySubfolder,
            setupExe: path.basename(buildArtifact) + deployExtension,
            exe: buildOptions['name'] + deployExtension,
            authors: buildOptions['app-company'],
            title: buildOptions['productName'],
            name: buildOptions['name'],
            iconUrl: buildOptions['iconUrl'],
            setupIcon: buildOptions['icon'],
            description: buildOptions['productDescription']
        };

        // Platform Options
        // logger.log('deploy options', platformName, deployOptions);

        // Deployment: Subfolder
        deleteFromFilesystem(deploySubfolder);
        createOnFilesystem(deploySubfolder);

        // Deployment: Start
        let deployHelper = windowsInstaller.createWindowsInstaller(deployOptions);

        // Deployment: Result
        deployHelper.then(function() {
            moveFolderToPackage(deploySubfolder, deployExtension, platformName);
        }, function(err) {
            logger.logErr('error (deploy)', err);
            return process.exit(1);
        });
    });
};


/**
 * Linux  Deployment
 * @param {Array} buildArtifactList - Directory to compress
 * @param {Object} buildOptions - electron-packager options object
 * @param {String} platformName - Current Platform type
 * @param {String} deployFolder - Deployment parent folder
 */
let deployLinux = function(buildArtifactList, buildOptions, platformName, deployFolder) {

    buildArtifactList.forEach(function(buildArtifact) {

        // Deployment: Architecture
        let architectureName = path.basename(buildArtifact).indexOf('x64') > 1 ? 'x64' : 'ia32';

        // Deployment: Input folder
        let inputFolder = path.join(buildArtifact);

        // Deployment: Target folder
        let deploySubfolder = path.join(path.resolve(deployFolder), path.basename(buildArtifact).replace(/\s+/g, '_').toLowerCase() + '-v' + buildOptions['app-version']);

        // Deployment: Installer extension
        let deployExtension = '.deb';

        // Deployment: Options
        let deployOptions = {
            arch: architectureName,
            src: inputFolder,
            dest: deploySubfolder,
            bin: buildOptions['name']
        };

        // Platform Options
        logger.log('deploy options', platformName, buildArtifact, deployOptions);

        // Deployment: Subfolder
        deleteFromFilesystem(deploySubfolder);
        createOnFilesystem(deploySubfolder);

        // Deployment: Start
        linuxInstaller(deployOptions, function(err) {
            if (!err) {
                return moveFolderToPackage(deploySubfolder, deployExtension, platformName);
            } else {
                logger.logErr('error (deploy)', err);
                return process.exit(1);
            }
        });
    });
};


/**
 * Start Building
 */
let build = function() {

    /**
     * Print Info
     */
    logger.log('Project', packageJson.build.productName, packageJson.build.version);
    logger.log('Target Platforms', platformList().join(', '));

    /**
     * Prepare Directories
     */
    deleteFromFilesystem(packageJson.build.directoryStaging, packageJson.build.directoryRelease);
    createOnFilesystem(packageJson.build.directoryStaging, packageJson.build.directoryRelease);

    /**
     * Building
     */
    platformList().forEach(function(target) {
        let options = createBuildOptions(target);

        // Build Options
        // logger.log('Options for ' + target, options);

        packager(options, function(err, result) {

            if (err) {
                logger.logErr('error (build)', err);
                return process.exit(1);
            }

            logger.log('build complete', target);

            /**
             * Trigger Deploy
             */
            if (target.startsWith('darwin')) {
                deployDarwin(result, options, target, packageJson.build.directoryRelease);
            } else if (target.startsWith('win')) {
                deployWindows(result, options, target, packageJson.build.directoryRelease);
            } else if (target.startsWith('linux')) {
                deployLinux(result, options, target, packageJson.build.directoryRelease);
            }
        });
    }, this);
};


/**
 * Initialize main process if called from CLI
 */
if (require.main === module) {
    build();
}


/**
 * exports
 */
module.exports = {
    build: build
};
