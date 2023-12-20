#!/usr/bin/env bash

for i in {0..6}; do
	build=$(( ($i * 7) + 3 ))
	minor=$(( ($build * 7) / 10 ))
	patch=$(( ($build * 7) % 10 ))
	major=$(( minor / 20 + 1 ))
	minor=$(( minor % 20 ))
	echo "$major.$minor.$patch b $build"

	 WORKFLOW_VERSION_NUMBER="${major}.${minor}.${patch}"
	 WORKFLOW_BUILD_NUMBER=$build

	 jq -n \
	 	--arg title "${WORKFLOW_VERSION_NUMBER}" \
	 	--arg link "https://he.ho.hum/myapps/downloads" \
	 	--arg version "${WORKFLOW_BUILD_NUMBER}" \
	 	--arg shortVersion "${WORKFLOW_VERSION_NUMBER}" \
	 	'{title: $title, link: $link, version: $version, shortVersionString: $shortVersion}' \
	 	> "myapp_${WORKFLOW_VERSION_NUMBER}.json"

	touch "myapp_${WORKFLOW_VERSION_NUMBER}.pkg"
done
