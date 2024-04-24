#!/usr/bin/env bash

# import the following env vars:

# required
# REMOTE_PATH
# KEY
# SECRET
# FILE

# optional env vars
# ACL
# ENDPOINT
# REGION
# PROVIDER (defaults to 'AWS')
# end import

set -x
set -o pipefail

random=$(head -c 500 /dev/urandom | LC_ALL=C tr -dc 'A-Za-z0-9' | head -c 8)
mkdir -p ".$random"
confFile=".${random}/rclone.conf"

function createConf() {
	echo "[S3]" > "$confFile"
	echo "type = s3" >> "$confFile"
	if [[ $PROVIDER ]]; then
		echo "provider = ${PROVIDER}" >> "$confFile"
	else
		echo "provider = AWS" >> "$confFile"
	fi
	echo "access_key_id = ${KEY}" >> "$confFile"
	echo "secret_access_key = ${SECRET}" >> "$confFile"
	if [[ $REGION ]]; then
		echo "region = ${REGION}" >> "$confFile"
	fi
	if [[ $ENDPOINT ]]; then
		echo "endpoint = ${ENDPOINT}" >> "$confFile"
	fi
	if [[ $ACL ]]; then 
		echo "acl = ${ACL}" >> "$confFile"
	fi
}

set +x
createConf

set -x
rclone -P --config="${confFile}" --s3-no-check-bucket copy "${FILE}" "S3:/${REMOTE_PATH}"

rm -rf ".${random}"
