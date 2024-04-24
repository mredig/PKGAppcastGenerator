#!/usr/bin/env bash

set -x
set -o pipefail

WEBHOOK_URL=$1
value=$2

BODY=$(jq -n --arg val "$value" '{ "content": $val }')

CURLCOMMAND=("curl")
CURLCOMMAND+=("-X")
CURLCOMMAND+=("POST")
CURLCOMMAND+=("-H")
CURLCOMMAND+=("Content-type: application/json")
CURLCOMMAND+=("-d")
CURLCOMMAND+=("${BODY}")
CURLCOMMAND+=("${WEBHOOK_URL}")

"${CURLCOMMAND[@]}"
