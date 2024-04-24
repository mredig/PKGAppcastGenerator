#!/usr/bin/env bash

# imported env vars
### required env vars
# KEYCHAIN_NOTARIZATION_KEY_ID
# KEYCHAIN_NOTARIZATION_PRIVATE_KEY
# KEYCHAIN_NOTARIZATION_ISSUER_ID
# end imports

# exported env vars
# end exports

#### Notarization tbd

set -xeu
set -o pipefail

# load secrets and set basic env vars
if [ -f Support/envsecrets ]; then
	source Support/envsecrets
fi

APP_PATH=$1

if [[ -z $APP_PATH ]]; then
	echo "Provide a path to the app to notarize"
	exit 1
fi

function runNotarization() {
	echo "--Starting Notarization Process--"

	PRIVATE_KEY_PATH="private_keys/AuthKey_${KEYCHAIN_NOTARIZATION_KEY_ID}.p8"

	if [ ! -f $PRIVATE_KEY_PATH ]; then 
		set +x
		mkdir -p private_keys
		echo $KEYCHAIN_NOTARIZATION_PRIVATE_KEY | base64 -d > $PRIVATE_KEY_PATH
		set -x
	fi

	tzip="notary_temp_$(date +%s).zip"
	zip -ry "${tzip}" "${APP_PATH}"

	xcrun \
		notarytool \
		submit \
		-k ${PRIVATE_KEY_PATH} \
		-d ${KEYCHAIN_NOTARIZATION_KEY_ID} \
		-i ${KEYCHAIN_NOTARIZATION_ISSUER_ID} \
		--progress \
		--wait \
		"${tzip}"

	xcrun \
		stapler \
		staple \
		-v \
		"${APP_PATH}"

	rm ${tzip}
}

runNotarization