#!/bin/sh

# Copyright 2016 S. Bofah
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


## USAGE
# Provide the required deployment parameters for bintray.com:
#  $BINTRAY_USER, $BINTRAY_TOKEN, $CACHE_VERSION
# Bootstrap the script:
#  source ./scripts/ecd.sh
# Run it one of the following commands:
#  ecd_cache_pack, ecd_cache_put, ecd_cache_fetch, ecd_cache_install


# ENV
BINTRAY_USER="${BINTRAY_USER}"
BINTRAY_TOKEN="${BINTRAY_TOKEN}"

CACHE_VERSION="${CACHE_VERSION}"


# CACHE
CACHE_TITLE="homebrew"
CACHE_MODULES=( fontconfig freetype gd gnutls graphicsmagick jasper libgphoto2 libicns libtasn1 libusb libusb-compat little-cms2 mono nettle openssl sane-backends webp wine )


## CONSTANTS
DEBUG="${DEBUG:-0}"


## FILESYSTEM
# Initial
PATH_INITIAL="$(PWD)"
LOG_FILEPATH_ABSOLUTE="${PATH_INITIAL}"/"curl.log"

# Cache
CACHE_SOURCEPATH="$(brew --cellar)"
CACHE_FILE_PREFIX="cache-"
CACHE_FILE_EXTENSION="tar.gz"
CACHE_HOMEPAGE="http://gihub.io/sidneys/electron-cloud-deploy"
CACHE_LICENSE="MIT"
CACHE_FILE_NAME="${CACHE_FILE_PREFIX}""${CACHE_TITLE}"
CACHE_PATH="buildtools-cache"/"${CACHE_VERSION}"
CACHE_PATH_ABSOLUTE="${PATH_INITIAL}"/"${CACHE_PATH}"
CACHE_FILEPATH="${CACHE_PATH}"/"${CACHE_FILE_NAME}"."${CACHE_FILE_EXTENSION}"
CACHE_FILEPATH_ABSOLUTE="${PATH_INITIAL}"/"${CACHE_FILEPATH}"

## App
APP_PATH="${PATH_INITIAL}"
APP_JSON_PATH="package.json"
APP_JSON_PATH_ABSOLUTE="${APP_PATH}"/"${APP_JSON_PATH}"
APP_BUILD_NAME=$(node -e "try { var package=require('${APP_JSON_PATH_ABSOLUTE}'); console.log(package.build.name || package.name); } catch(e) {}")
APP_BUILD_VERSION=$(node -e "try { var package=require('${APP_JSON_PATH_ABSOLUTE}'); console.log(package.build.version || package.version); } catch(e) {}")
APP_BUILD_LICENSE=$(node -e "try { var package=require('${APP_JSON_PATH_ABSOLUTE}'); console.log(package.build.license || package.license); } catch(e) {}")
APP_BUILD_HOMEPAGE=$(node -e "try { var package=require('${APP_JSON_PATH_ABSOLUTE}'); console.log(package.build.homepage || package.homepage); } catch(e) {}")

## API (Bintray)
BASEURL_API="https://api.bintray.com"
BASEURL_DOWNLOAD="https://dl.bintray.com"

# Paths
RESOURCEPATH_CONTENT="content"
RESOURCEPATH_PACKAGES="packages"
RESOURCEPATH_REPOS="repos"

# Queries
QUERYPATH_PUBLISH="publish"
QUERYPATH_VERSIONS="versions"

# Endpoints
ENDPOINT_CONTENT="${BASEURL_API}"/"${RESOURCEPATH_CONTENT}"/"${BINTRAY_USER}"
ENDPOINT_REPOS="${BASEURL_API}"/"${RESOURCEPATH_REPOS}"/"${BINTRAY_USER}"
ENDPOINT_PACKAGES="${BASEURL_API}"/"${RESOURCEPATH_PACKAGES}"/"${BINTRAY_USER}"
ENDPOINT_DOWNLOAD="${BASEURL_DOWNLOAD}"/"${BINTRAY_USER}"


## DEBUG

function _check_variables {
  if [[ "$DEBUG" != 1 ]]; then return 0; fi
  echo "------------------------------------------------------------------------" | _log_assertive
  echo BINTRAY_TOKEN $BINTRAY_TOKEN | _log_assertive
  echo BINTRAY_USER $BINTRAY_USER | _log_assertive
  echo CACHE_FILEPATH $CACHE_FILEPATH | _log_assertive
  echo CACHE_FILEPATH_ABSOLUTE $CACHE_FILEPATH_ABSOLUTE | _log_assertive
  echo CACHE_FILE_EXTENSION $CACHE_FILE_EXTENSION | _log_assertive
  echo CACHE_FILE_NAME $CACHE_FILE_NAME | _log_assertive
  echo CACHE_SOURCEPATH $CACHE_SOURCEPATH | _log_assertive
  echo CACHE_MODULES ${CACHE_MODULES[@]} | _log_assertive
  echo CACHE_PATH $CACHE_PATH | _log_assertive
  echo CACHE_PATH_ABSOLUTE $CACHE_PATH_ABSOLUTE | _log_assertive
  echo CACHE_VERSION $CACHE_VERSION | _log_assertive
  echo DEBUG $DEBUG | _log_assertive
  echo ENDPOINT_CONTENT $ENDPOINT_CONTENT | _log_assertive
  echo ENDPOINT_DOWNLOAD $ENDPOINT_DOWNLOAD | _log_assertive
  echo ENDPOINT_PACKAGES $ENDPOINT_PACKAGES | _log_assertive
  echo ENDPOINT_REPOS $ENDPOINT_REPOS | _log_assertive
  echo APP_BUILD_HOMEPAGE $APP_BUILD_HOMEPAGE | _log_assertive
  echo APP_BUILD_LICENSE $APP_BUILD_LICENSE | _log_assertive
  echo APP_BUILD_NAME $APP_BUILD_NAME | _log_assertive
  echo APP_BUILD_VERSION $APP_BUILD_VERSION | _log_assertive
  echo APP_JSON_PATH $APP_JSON_PATH | _log_assertive
  echo APP_JSON_PATH_ABSOLUTE $APP_JSON_PATH_ABSOLUTE | _log_assertive
  echo APP_PATH $APP_PATH | _log_assertive
  echo PATH_INITIAL $PATH_INITIAL | _log_assertive
  echo QUERYPATH_PUBLISH $QUERYPATH_PUBLISH | _log_assertive
  echo QUERYPATH_VERSIONS $QUERYPATH_VERSIONS | _log_assertive
  echo RESOURCEPATH_CONTENT $RESOURCEPATH_CONTENT | _log_assertive
  echo RESOURCEPATH_PACKAGES $RESOURCEPATH_PACKAGES | _log_assertive
  echo "------------------------------------------------------------------------" | _log_assertive
}


## UTILITIES
# rawurlencode <string>
function rawurlencode {
  local string="${1}"
  local strlen=${#string}
  local encoded=""
  local pos c o

  for (( pos=0 ; pos<strlen ; pos++ )); do
     c=${string:$pos:1}
     case "$c" in
        [-_.~a-zA-Z0-9] ) o="${c}" ;;
        * )               printf -v o '%%%02x' "'$c"
     esac
     encoded+="${o}"
  done
  echo "${encoded}"    # You can either set a return variable (FASTER) 
  REPLY="${encoded}"   #+or echo the result (EASIER)... or both... :p
}
# Returns a string in which the sequences with percent (%) signs followed by
rawurldecode() {
  printf -v REPLY '%b' "${1//%/\\x}"
  echo "${REPLY}"
}

# Log
function _log {
  while read; do printf '\e[0;30m\e[46m%s\e[0m \e[1;36m%s\e[0m\n' "[ELECTRON-CLOUD-DEPLOY]" "$REPLY"; done
}

# Log Errors
function _log_assertive {
  while read; do printf '\e[0;30m\e[41m%s\e[0m \e[1;31m%s\e[0m\n' "[ELECTRON-CLOUD-DEPLOY]" "$REPLY"; done
}

# JSON
alias json="jq --raw-output --monochrome-output"

# Validate Cached Homebrew Modules
function _validate_cached_modules {
    echo "Cached Modules status:" | _log
    
    brew doctor; brew outdated
    fakeroot -v; tar --version; dpkg --version
}

# Install Minimum Toolset
function _install_tools {
    brew install jq || true
}

# Validate Bintray Credentials
function _validate_bintray_credentials {
    if [ -z "$BINTRAY_USER" ]; then echo "Bintray Username required. Aborting." | _log_assertive; return 1; fi
    if [ -z "$BINTRAY_TOKEN" ]; then echo "Bintray Token required (bintray.com/profile/edit). Aborting." | _log_assertive; return 1; fi
}

# Validate App Configuration
function _validate_app_configuration {
    if [ ! -f "${CACHE_FILEPATH_ABSOLUTE}" ]; then echo "${APP_JSON_PATH_ABSOLUTE} not found. Aborting." | _log_assertive; return 1; fi
    if [ -z "$APP_BUILD_HOMEPAGE" ]; then echo "${APP_JSON_PATH_ABSOLUTE}: 'homepage' missing. Aborting." | _log_assertive; return 1; fi
    if [ -z "$APP_BUILD_NAME" ]; then echo "${APP_JSON_PATH_ABSOLUTE}: 'name' missing. Aborting." | _log_assertive; return 1; fi
    if [ -z "$APP_BUILD_LICENSE" ]; then echo "${APP_JSON_PATH_ABSOLUTE}: 'license' missing. Aborting." | _log_assertive; return 1; fi
    if [ -z "$APP_BUILD_VERSION" ]; then echo "${APP_JSON_PATH_ABSOLUTE}: 'version' missing. Aborting." | _log_assertive; return 1; fi
}

# Validate Cache Configuration
function _validate_cache_configuration {
    if [ -z "$CACHE_HOMEPAGE" ]; then echo "CACHE: homepage missing. Aborting." | _log_assertive; return 1; fi
    if [ -z "$CACHE_LICENSE" ]; then echo "CACHE: license missing. Aborting." | _log_assertive; return 1; fi
}

## BINTRAY INTERFACE

# Upload Artifact
function _bintray_artifact_upload {
    REPO="$1"
    PACKAGE="$2"
    VERSION="$3"
    FILE_PATH="$4"
    
    FILE_NAME="$(basename ${FILE_PATH})"
    FILE_NAME_URLENCODED="$(rawurlencode ${FILE_NAME})"
    
    echo "Initiating upload: '$FILE_NAME'  -->  '$FILE_NAME_URLENCODED'" | _log
    
    if curl --fail --silent --output /dev/null --head "${ENDPOINT_DOWNLOAD}" > /dev/null ; then
      echo "Package already uploaded." | _log
    else
        if curl --progress-bar --upload-file "${FILE_PATH}" --user "${BINTRAY_USER}":"${BINTRAY_TOKEN}" "${ENDPOINT_CONTENT}"/"${REPO}"/"${PACKAGE}"/"${VERSION}"/"${FILE_NAME_URLENCODED}" | tee -a "${LOG_FILEPATH_ABSOLUTE}" | json '.message' | _log ; test ${PIPESTATUS[0]} -eq 0; then
        return 0
      else
        echo "Upload failed." | _log_assertive
        return 1
      fi
    fi
    return 0
}

# Download Artifact
function _bintray_artifact_download {
    REPO="$1"
    FILE_PATH="$2"
    DESTINATION="$3"
    
    FILE_NAME="$(basename ${FILE_PATH})"
    FILE_NAME_URLENCODED="$(rawurlencode ${FILE_NAME})"
    FILE_NAME_URLDECODED="$(rawurldecode ${FILE_NAME})"
    
    URL="${ENDPOINT_DOWNLOAD}"/"${REPO}"/"${FILE_NAME_URLENCODED}"
    OUTPUT="${DESTINATION}"/"${FILE_NAME}"

    if curl --fail --silent --output /dev/null --head "${URL}"; then
      echo "Downloading: '${URL}'" | _log
      echo "To: '${OUTPUT}'" | _log
      if curl --progress-bar --location --url "${URL}" --output "${OUTPUT}" | tee -a "${LOG_FILEPATH_ABSOLUTE}" | json '.message' | _log ; test ${PIPESTATUS[0]} -eq 0; then
        echo "Download successful: ${OUTPUT}" | _log
        return 0
        if ! tar -tf "${OUTPUT}" &>/dev/null; then
          rm "${OUTPUT}";
          echo "Package incomplete." | _log_assertive
          return 1
        fi
      else
        echo "Download failed." | _log_assertive
        return 1
      fi
    else 
      echo "Package not available: ${URL}" | _log_assertive
      return 1
    fi
}

# Publish Uploaded Artifact
function _bintray_artifact_publish_all {
    REPO="$1"
    PACKAGE="$2"
    VERSION="$3"
    
    echo "Publishing uploaded artifacts for: '${REPO}/${PACKAGE}/${VERSION}'" | _log
    
    if curl --silent -X POST --user "${BINTRAY_USER}":"${BINTRAY_TOKEN}" -H "Content-Type: application/json"  -d "{\"publish_wait_for_secs\":-1}" "${ENDPOINT_CONTENT}"/"${REPO}"/"${NAME}"/"${VERSION}"/"${QUERYPATH_PUBLISH}" | echo "Files: $(json '.files')" | _log; then
      echo "Publishing successful." | _log 
      return 0
    else
      echo "Publishing failed." | _log_assertive
      return 1
    fi
}

# Remove Uploaded Artifact
function _bintray_artifact_delete {
    REPO="$1"
    FILE_PATH="$2"
    
    FILE_NAME="$(basename ${FILE_PATH})"
    FILE_NAME_URLENCODED="$(rawurlencode ${FILE_NAME})"
    
    if curl --silent -X DELETE --user "${BINTRAY_USER}":"${BINTRAY_TOKEN}" "${ENDPOINT_CONTENT}"/"${REPO}"/"${FILE_NAME_URLENCODED}" | json '.message' | _log; then
      return 0
    else
      echo "Could not delete uploaded artifact." | _log_assertive
      return 1
    fi
}

# Add Version
function _bintray_version_add {
    REPO="$1"
    PACKAGE="$2"
    VERSION="$3"
    
    echo "Adding version: '${REPO}/${PACKAGE}/${VERSION}'" | _log
    
    if curl --silent -X POST --user "${BINTRAY_USER}":"${BINTRAY_TOKEN}"  -H "Content-Type: application/json"  -d "{\"name\":\"${VERSION}\",\"desc\":\"${VERSION}\"}" "${ENDPOINT_PACKAGES}"/"${REPO}"/"${PACKAGE}"/"${VERSION}"/"${QUERYPATH_VERSIONS}" | json '.message' | _log; then
      echo "Version created: '${VERSION}'" | _log 
      return 0
    else
      echo "Version could not be created." | _log_assertive
      return 1
    fi
}

# Add Package
function _bintray_package_add {
    NAME="$1"
    URL="$2"
    LICENSE="$3"
    
    if curl --silent -X POST --user "${BINTRAY_USER}":"${BINTRAY_TOKEN}"  -H "Content-Type: application/json" -d "{\"name\":\"${NAME}\",\"desc\":\"${NAME}\",\"vcs_url\":\"${URL}\",\"licenses\":[\"${LICENSE}\"]}" "${ENDPOINT_PACKAGES}"/"${NAME}" | json '.message' | _log; then
      echo "Package created: '${NAME}'" | _log 
      return 0
    else
      echo "Package could not be created." | _log_assertive
      return 1
    fi
}

# Add Repo
function _bintray_repo_add {
    NAME="$1"
    
    echo "Creating repository '${NAME}'" | _log 
    if curl --silent -X POST --user "${BINTRAY_USER}":"${BINTRAY_TOKEN}"  -H "Content-Type: application/json"  -d "{\"type\":\"generic\",\"private\":false,\"desc\":\"${NAME}\"}" "${ENDPOINT_REPOS}"/"${NAME}" | json '.message' | _log; then
      return 0
    else
      echo "Repo could not be created." | _log_assertive
      return 1
    fi
}


## CACHE

# Init Cache Folder
function _cache_folder_init {
    if [ ! -d "${CACHE_PATH_ABSOLUTE}" ]; then
      mkdir -p "${CACHE_PATH_ABSOLUTE}" && chmod -R 777 "${CACHE_PATH_ABSOLUTE}"
    fi
    if [ ! -d "${CACHE_PATH_ABSOLUTE}" ]; then
        echo "Cache folder not found." | _log
        return 1
    fi 
    echo "Using cache folder: '${CACHE_PATH_ABSOLUTE}'" | _log
    return 0
}

# List Cached Modules
function ecd_cache_list {
    _cache_folder_init || return 1

    echo "------------------------" | _log
    brew info "${CACHE_MODULES[@]}" --json=v1 | node -e "(JSON.parse(require('fs').readFileSync('/dev/stdin').toString())).forEach(function(f) { console.log(f.name + ' ' + f.installed[0].version) });" | _log
    echo "------------------------" | _log
}

# Tar Cached Modules
function ecd_cache_pack {
    _cache_folder_init || return 1

    echo "Packaging modules." | _log
    if [ -f "${CACHE_FILEPATH_ABSOLUTE}" ]; then
        rm "${CACHE_FILEPATH_ABSOLUTE}"
        echo "Removed existing cache package: '${CACHE_FILEPATH}'" | _log
    fi 
    if tar -czvf "${CACHE_FILEPATH_ABSOLUTE}" --directory "${CACHE_SOURCEPATH}" "${CACHE_MODULES[@]}"; then
      echo "Packaging complete." | _log && ecd_cache_list
      return 0
    fi
}

# Unpack & Install Cached Modules
function ecd_cache_install {
    _cache_folder_init || return 1

    PATH=${PATH}:/usr/local/bin:/opt/local/bin:/usr/bin:/bin:/usr/local/sbin:/opt/local/sbin:/usr/sbin:/sbin:~/bin
    export PATH
  
    tar -zxf "${CACHE_FILEPATH_ABSOLUTE}" --directory "${CACHE_SOURCEPATH}"
    brew link --overwrite "${CACHE_MODULES[@]}" && echo "Installed modules." | _log

    brew uninstall --force dpkg fakeroot gnu-tar pkg-config xz || true
    brew install --force dpkg fakeroot gnu-tar pkg-config xz || true
    
    _validate_cached_modules
}

# Uploads Cached Modules
function ecd_cache_put {  
    _cache_folder_init || return 1
    _validate_cache_configuration || return 1
    _validate_bintray_credentials || return 1
    
    _bintray_repo_add "${CACHE_FILE_NAME}"
    _bintray_package_add "${CACHE_FILE_NAME}" "${CACHE_HOMEPAGE}" "${CACHE_LICENSE}"   
    _bintray_version_add "${CACHE_FILE_NAME}" "${CACHE_FILE_NAME}" "${CACHE_VERSION}"
    
    _bintray_artifact_delete "${CACHE_FILE_NAME}" "${CACHE_FILEPATH_ABSOLUTE}"
    _bintray_artifact_upload "${CACHE_FILE_NAME}" "${CACHE_FILE_NAME}" "${CACHE_VERSION}" "${CACHE_FILEPATH_ABSOLUTE}"
    _bintray_artifact_publish_all "${CACHE_FILE_NAME}" "${CACHE_FILE_NAME}" "${CACHE_VERSION}"
    return 0
}

# Fetch Cached Modules
function ecd_cache_fetch {
    _cache_folder_init
    _bintray_artifact_download "${CACHE_FILE_NAME}" "${CACHE_FILE_NAME}.${CACHE_FILE_EXTENSION}" "${CACHE_PATH_ABSOLUTE}"
    return 0
}


## DEPLOY

# Upload Build
function ecd_build_deploy {
    _validate_app_configuration || return 1
    _validate_bintray_credentials || return 1

    APP_VERSION="${APP_BUILD_VERSION}"
    APP_NAME="${APP_BUILD_NAME}"
    APP_HOMEPAGE="${APP_BUILD_HOMEPAGE}"
    APP_LICENSE="${APP_BUILD_LICENSE}"
    APP_REPO="${APP_NAME}"
    
    _bintray_repo_add "${APP_NAME}"
    _bintray_package_add "${APP_NAME}" "${APP_HOMEPAGE}" "${APP_LICENSE}"
    _bintray_version_add "${APP_NAME}" "${APP_NAME}" "${APP_VERSION}"
    
    echo "${APP_NAME} ($# files)" | _log
    echo "Version: ${APP_VERSION}" | _log
    echo "License: ${APP_LICENSE}" | _log
    echo "Homepage: ${APP_HOMEPAGE}" | _log

    IFS=$'\n'
    for APP_FILE in "$@"; do
        echo "Deploying: '${APP_FILE}'." | _log
        _bintray_artifact_delete "${APP_NAME}" "${APP_FILE}"
        _bintray_artifact_upload "${APP_NAME}" "${APP_NAME}" "${APP_VERSION}" "${APP_FILE}"
    done
    unset IFS
    
    _bintray_artifact_publish_all "${APP_NAME}" "${APP_NAME}" "${APP_VERSION}"
    return 0
}


## MAIN
_install_tools
_check_variables
#ecd_cache_pack
#ecd_cache_put
#ecd_cache_fetch
#ecd_cache_install