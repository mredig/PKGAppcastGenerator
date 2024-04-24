#!/usr/bin/env bash

# imported env vars
### optional env vars
# WORK_PATH
# BUILD_DIR
# RESULT_PATH
# ARCHIVE_PATH
# DERIVED_DATA_PATH
# BUILD_NUMBER
# ARCHIVE_EXPORT_PATH
# ARCHIVED_APP_BUNDLE_PATH

### required env vars
# SCHEME
# CONFIGURATION
# PROJECT
# TARGET_NAME
# end imports

# exported env vars
# BUILD_DIR
# ARCHIVED_APP_BUNDLE_PATH
# end exports


set -xeu
set -o pipefail

export WORK_PATH="${WORK_PATH:-$(pwd)}"

# app building vars
BUILD_DIR="${BUILD_DIR:-"${WORK_PATH}/.build"}"
ARTIFACT_PATH=${RESULT_PATH:-"${BUILD_DIR}/Artifacts"}
RESULT_BUNDLE_PATH="${ARTIFACT_PATH}/${SCHEME}.xcresult"
ARCHIVE_PATH=${ARCHIVE_PATH:-"${BUILD_DIR}/Archives/${SCHEME}.xcarchive"}
DERIVED_DATA_PATH=${DERIVED_DATA_PATH:-"${BUILD_DIR}/DerivedData"}
CURRENT_PROJECT_VERSION=${BUILD_NUMBER:-"0"}
EXPORT_OPTIONS_FILE="${WORK_PATH}/CICD_Support/ExportOptions.plist"
ARCHIVE_EXPORT_PATH="${ARCHIVE_EXPORT_PATH:-"${BUILD_DIR}"}"
ARCHIVED_APP_BUNDLE_PATH="${ARCHIVED_APP_BUNDLE_PATH:-"${ARCHIVE_EXPORT_PATH}/${TARGET_NAME}"}"

ENTITLEMENTS_PLIST_PATH="${WORK_PATH}/CICD_Support/entitlements.mac.plist"

# load secrets and set basic env vars
if [ -f Support/envsecrets ]; then
	source Support/envsecrets
fi

# xcode setup
function buildProject() {
	cd "${WORK_PATH}"

	rm -rf "${RESULT_BUNDLE_PATH}"
	RESOLVE_COMMAND=("xcrun")
	RESOLVE_COMMAND+=("xcodebuild")
	RESOLVE_COMMAND+=("-resolvePackageDependencies")
	RESOLVE_COMMAND+=("-project")
	RESOLVE_COMMAND+=("${PROJECT}")
	RESOLVE_COMMAND+=("-scmProvider")
	RESOLVE_COMMAND+=("system")

	"${RESOLVE_COMMAND[@]}"

	echo "--Building Mac App--"
	BUILD_COMMAND=("xcrun")
	BUILD_COMMAND+=("xcodebuild")
	BUILD_COMMAND+=("-project")
	BUILD_COMMAND+=("${PROJECT}")
	BUILD_COMMAND+=("-scheme")
	BUILD_COMMAND+=("${SCHEME}")
	BUILD_COMMAND+=("-configuration")
	BUILD_COMMAND+=("${CONFIGURATION}")
	BUILD_COMMAND+=("-disablePackageRepositoryCache")
	BUILD_COMMAND+=("-showBuildTimingSummary")
	BUILD_COMMAND+=("-skipMacroValidation")
	BUILD_COMMAND+=("-parallelizeTargets")
	BUILD_COMMAND+=("-scmProvider")
	BUILD_COMMAND+=("system")
	BUILD_COMMAND+=("-derivedDataPath")
	BUILD_COMMAND+=("${DERIVED_DATA_PATH}")
	BUILD_COMMAND+=("-archivePath")
	BUILD_COMMAND+=("${ARCHIVE_PATH}")
	BUILD_COMMAND+=("-resultBundlePath")
	BUILD_COMMAND+=("${RESULT_BUNDLE_PATH}")
	BUILD_COMMAND+=(CURRENT_PROJECT_VERSION="${CURRENT_PROJECT_VERSION}")
	BUILD_COMMAND+=("archive")
	# BUILD_COMMAND+=("-showdestinations")
	# -showBuildSettings
	"${BUILD_COMMAND[@]}"

	echo "--Exporting Archive Build Artifact--"
	if [ -e "${ARCHIVE_EXPORT_PATH}/${TARGET_NAME}" ]; then 
		rm -rf "${ARCHIVE_EXPORT_PATH}/${TARGET_NAME}"
	fi
	mkdir -p "${ARCHIVE_EXPORT_PATH}"
	
	EXPORT_COMMAND=("xcrun")
	EXPORT_COMMAND+=("xcodebuild")
    EXPORT_COMMAND+=(-exportArchive)
    EXPORT_COMMAND+=(-exportOptionsPlist)
    EXPORT_COMMAND+=( "${EXPORT_OPTIONS_FILE}")
    EXPORT_COMMAND+=(-archivePath)
    EXPORT_COMMAND+=( "${ARCHIVE_PATH}")
    EXPORT_COMMAND+=(-exportPath)
    EXPORT_COMMAND+=( "${ARCHIVE_EXPORT_PATH}")

	"${EXPORT_COMMAND[@]}"


	# mv "${ARCHIVE_PATH}/Products/Applications/${TARGET_NAME}" "${ARCHIVE_EXPORT_PATH}"

	# SIGNING_CERTIFICATE_TITLE=${SIGNING_CERTIFICATE_TITLE:-"${APPLE_TEAM_ID}"}

	# codesign \
	# 	--force \
	# 	--sign "${SIGNING_CERTIFICATE_TITLE}" \
	# 	--entitlements "${ENTITLEMENTS_PLIST_PATH}" \
	# 	--timestamp \
	# 	--options runtime \
	# 	"${ARCHIVED_APP_BUNDLE_PATH}"

	# get version info from archived app
	INFO_PLIST_PATH="${ARCHIVED_APP_BUNDLE_PATH}/Contents/Info.plist"
	BUILD_NUMBER=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "$INFO_PLIST_PATH")
	VERSION_NUMBER=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$INFO_PLIST_PATH")
	echo $VERSION_NUMBER > .build/version_number
	echo $BUILD_NUMBER > .build/build_number
	echo "VERSION_NUMBER=${VERSION_NUMBER}" >> "$CM_ENV"
	echo "BUILD_NUMBER=${BUILD_NUMBER}" >> "$CM_ENV"
	echo "WORKFLOW_VERSION_NUMBER=$VERSION_NUMBER" >> $CM_ENV
}

## useful for speeding up github workflows while troubleshooting
function fakeBuild() {
	# mkdir -p ".build/${TARGET_NAME}/Contents"
	# touch ".build/${TARGET_NAME}/Contents/foo"
	curl -O "https://web.resource.com/OnlineArtifact.tgz"
	tar -xvf OnlineArtifact.tgz
	mkdir .build
	cd OnlineArtifact
	mv "${TARGET_NAME}" ../.build/
	cd ..
	rm -rf OnlineArtifact

	echo "VERSION_NUMBER=1.0.0" >> "$CM_ENV"
	echo "BUILD_NUMBER=123" >> "$CM_ENV"
}

buildProject
# fakeBuild

echo "BUILD_DIR=${BUILD_DIR}" >> "$CM_ENV"
echo "ARCHIVED_APP_BUNDLE_PATH=${ARCHIVED_APP_BUNDLE_PATH}" >> "$CM_ENV"
