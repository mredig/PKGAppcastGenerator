#!/usr/bin/env bash

# import the following env vars:
# SPARKLE_KEY
# SPARKLE_DOWNLOAD_URL
# DIST_PATH_ZIP
# DIST_NAME_ZIP
# APPCAST_URL
# DOWNLOAD_URL_PREFIX
# DOWNLOADS_LINK
# end import

set -x
set -o pipefail

APPCAST_NAME=$1

if [[ -z "${APPCAST_NAME}" ]]; then
	echo "Need an appcast name"
	exit 1
fi

set +x
if [[ -z "$SPARKLE_KEY" ]]; then
	echo "Missing env var SPARKLE_KEY"
	exit 1
fi
if [[ -z "$SPARKLE_DOWNLOAD_URL" ]]; then
	echo "Missing env var SPARKLE_DOWNLOAD_URL"
	exit 1
fi
if [[ -z "$DIST_PATH_ZIP" ]]; then
	echo "Missing env var DIST_PATH_ZIP"
	exit 1
fi
if [[ -z "$DIST_NAME_ZIP" ]]; then
	echo "Missing env var DIST_NAME_ZIP"
	exit 1
fi
if [[ -z "$APPCAST_URL" ]]; then
	echo "Missing env var APPCAST_URL"
	exit 1
fi
if [[ -z "$DOWNLOAD_URL_PREFIX" ]]; then
	echo "Missing env var DOWNLOAD_URL_PREFIX"
	exit 1
fi
set -x

SPARKLE_KEY_PATH="$(pwd)/private_keys/sparkle.key"

function saveSparkleKey() {
	set +x
	mkdir -p private_keys
	echo -e "${SPARKLE_KEY}" > "${SPARKLE_KEY_PATH}"
	set -x
}

if [[ ! -f "${SPARKLE_KEY_PATH}" ]]; then
	saveSparkleKey
fi

function getFile() {
	url=$1
	filename=$2

	curl -L --output "${filename}" "${url}"
}

getFile "https://github.com/mredig/PKGAppcastGenerator/releases/download/0.2.3/PKGAppcastGenerator.zip" "PKGAppcastGenerator.zip"
unzip PKGAppcastGenerator.zip

getFile "${SPARKLE_DOWNLOAD_URL}" "Sparkle.zip"
unzip -d Sparkle Sparkle.zip

if [[ ! -e Sparkle/bin/sign_update ]]; then
	echo "Cannot find sparke's sign_update binary"
	exit 1
fi

mkdir -p AppcastStaging
function generateAppcast() {
	mv "${DIST_PATH_ZIP}" "AppcastStaging/"

	pushd AppcastStaging

	PKG_COMMAND=("../PKGAppcastGenerator")
	PKG_COMMAND+=("--existing-appcast-url")
	PKG_COMMAND+=("${APPCAST_URL}")
	PKG_COMMAND+=("--download-url-prefix")
	PKG_COMMAND+=("${DOWNLOAD_URL_PREFIX}")
	PKG_COMMAND+=("--sign-update-path")
	PKG_COMMAND+=("../Sparkle/bin/sign_update")
	PKG_COMMAND+=("--sign-update-key-file")
	PKG_COMMAND+=("${SPARKLE_KEY_PATH}")
	PKG_COMMAND+=("--output-path")
	PKG_COMMAND+=("${APPCAST_NAME}")
	PKG_COMMAND+=("--downloads-link")
	PKG_COMMAND+=("${DOWNLOADS_LINK}") # where to download manually
	PKG_COMMAND+=(".")

	"${PKG_COMMAND[@]}"

	mv "${DIST_NAME_ZIP}" "${DIST_PATH_ZIP}"

	echo "APPCAST_NAME=${APPCAST_NAME}" >> $CM_ENV
	echo "APPCAST_PATH=$(pwd)/${APPCAST_NAME}" >> $CM_ENV

	popd
}

generateAppcast