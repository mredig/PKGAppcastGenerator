#!/usr/bin/env bash

output=$1

if [[ -z $output ]]; then
	echo "Require output! Usage: ./exename [destinationDirectoryNoBrackets]"
	exit 1
fi

function cleanup() {
	rm -rf "${output}/MyApp.app"
}

for i in {0..6}; do

	build=$(( ($i * 7) + 3 ))
	minor=$(( ($build * 7) / 10 ))
	patch=$(( ($build * 7) % 10 ))
	major=$(( minor / 20 + 1 ))
	minor=$(( minor % 20 ))
	echo "$major.$minor.$patch b $build"

	WORKFLOW_VERSION_NUMBER="${major}.${minor}.${patch}"
	WORKFLOW_BUILD_NUMBER=$build
	MIN_OS="12.${i}"

	mkdir -p "${output}/MyApp.app/Contents/MacOS"
	plistPath="${output}/MyApp.app/Contents/Info.plist"
	cp baseinfo.plist "$plistPath"
	/usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${WORKFLOW_BUILD_NUMBER}" "$plistPath"
	/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString ${WORKFLOW_VERSION_NUMBER}" "$plistPath"
	/usr/libexec/PlistBuddy -c "Set :LSMinimumSystemVersion ${MIN_OS}" "$plistPath"

	echo "#!/usr/bin/env bash" > "${output}/MyApp.app/Contents/MacOS/myapp"
	echo "echo Hello World!" >> "${output}/MyApp.app/Contents/MacOS/myapp"
	chmod +x "${output}/MyApp.app/Contents/MacOS/myapp"

	if [[ $(( i % 3 )) == 0 ]]; then
		zip -r "${output}/MyApp-${WORKFLOW_VERSION_NUMBER}.zip" "${output}/MyApp.app"
	else
		pushd "${output}"
		zip -r "MyApp-${WORKFLOW_VERSION_NUMBER}.zip" "MyApp.app"
		popd
	fi

	cleanup
done
