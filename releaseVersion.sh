#!/bin/bash -e

# This script is responsible for creating a release and getting all the gears in motion
# so that cask, appcast and GitHub releases are all updated with the new release.
# Prerequisites:
#	$GITHUB_RELEASES_TOKEN should be valid and include a GitHub OAuth 2 token with at least repo permission.
#		See https://help.github.com/articles/creating-a-personal-access-token-for-the-command-line/ and https://github.com/settings/tokens 
#	jq for json parsing and querying.
#		brew install jq

XCODEVERSION=$(xcodebuild -version | grep -oEi "([0-9]*\.[0-9]*)")
XCODENEWESTSUPPORTED="11.2.1"
if [ ${XCODEVERSION} != ${XCODENEWESTSUPPORTED} ] && [ "${XCODEVERSION}" = "`echo -e "${XCODEVERSION}\n${XCODENEWESTSUPPORTED}" | sort --version-sort -r | head -n1`" ]; then
  printf >&2 "\033[1;31mUnsupported Xcode, aborting\033[0m\n"
  exit 1;
fi

BRANCH=$(git rev-parse --abbrev-ref HEAD)

if [ ! "$BRANCH" = "master" ]; then
	printf >&2 "\033[1;31mNot on master branch, performing a dry run\033[0m\n"
	DRY_RUN="1"
else 
	if [ "$1" = "--dry" ]; then
		DRY_RUN=$1
	fi
fi

NO_DOCS="1"
if [ "$1" = "docs" ]; then
	NO_DOCS="0"
fi

if [ ! -z "$DRY_RUN" ]; then
	printf >&2 "\033[1;31mPerforming a dry run\033[0m\n"
fi

# if  [[ -n $(git status --porcelain) ]]; then
#   printf >&2 "\033[1;31mCannot release version because there are unstaged changes, aborting.\nChanges:\033[0m\n"
#   git status --short
#   exit -1
# fi

if [[ -n $(git log --branches --not --remotes) ]]; then
  echo -e "\033[1;34mPushing pending commits to git\033[0m"
  if [ -z "$DRY_RUN" ]; then
    git push
  fi
fi

echo -e "\033[1;34mCreating release notes\033[0m"

if [ -z "$DRY_RUN" ]; then
	RELEASE_NOTES_FILE=Distribution/_tmp_release_notes.md

	# rm -f "${RELEASE_NOTES_FILE}"
	touch "${RELEASE_NOTES_FILE}"
	open -Wn "${RELEASE_NOTES_FILE}"

	if ! [ -s "${RELEASE_NOTES_FILE}" ]; then
		echo -e >&2 "\033[1;31mNo release notes provided, aborting\033[0m"
		rm -f "${RELEASE_NOTES_FILE}"
		exit -1
	fi
fi

Scripts/updateCopyright.sh
Scripts/updateContributors.sh

if [ "$NO_DOCS" == "0" ]; then
	echo -e "\033[1;34mUpdating acknowledgements and Apple Help\033[0m"

	Scripts/updateAcknowledgements.sh
	Scripts/updateHelp.sh || :
fi

echo -e "\033[1;34mBuilding archive and exporting\033[0m"

ARCHIVE=Distribution/Archive.xcarchive
EXPORT_DIR=Distribution/Export

rm -fr Distribution/*.zip
rm -fr "${ARCHIVE}"
rm -fr "${EXPORT_DIR}"

export CODE_SIGNING_REQUIRED=NO && xcodebuild -project DetoxInstruments/DetoxInstruments.xcodeproj -scheme "Detox Instruments" -configuration release clean archive -archivePath "${ARCHIVE}" DTXBundleName="Detox Instruments" ASSETCATALOG_COMPILER_APPICON_NAME="AppIcon"
xcodebuild -project DetoxInstruments/DetoxInstruments.xcodeproj -exportArchive -archivePath "${ARCHIVE}" -exportOptionsPlist Distribution/exportOptions.plist -exportPath "${EXPORT_DIR}"

SHORT_VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "${EXPORT_DIR}"/*.app/Contents/Info.plist)
BUILD_NUMBER=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "${EXPORT_DIR}"/*.app/Contents/Info.plist)

VERSION="${SHORT_VERSION}"."${BUILD_NUMBER}"

ZIP_FILE=Distribution/DetoxInstruments-v"${SHORT_VERSION}".b"${BUILD_NUMBER}".zip

echo -e "\033[1;34mVersion is: $VERSION\033[0m"

echo -e "\033[1;34mCreating ZIP file\033[0m"

ditto -c -k --sequesterRsrc --keepParent "${EXPORT_DIR}"/*.app "${ZIP_FILE}" &> /dev/null

# https://developer.apple.com/documentation/security/notarizing_your_app_before_distribution/customizing_the_notarization_workflow

echo -e "\033[1;34mSubmitting to notarization service\033[0m"

NOTARIZATION_UUID=$(xcrun altool --notarize-app --primary-bundle-id "com.wix.DetoxInstruments" --username "lnatan@wix.com" --password "@keychain:notary_password" --file "$ZIP_FILE" 2>&1 | grep RequestUUID | awk '{print $3}')

echo -e "\033[1;34mAwaiting notarization success for ${NOTARIZATION_UUID}\033[0m"

NOTARIZATION_SUCCESS=0
for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do
    PROGRESS=$(xcrun altool --notarization-info "${NOTARIZATION_UUID}" --username "lnatan@wix.com" --password "@keychain:notary_password" 2>&1 )
    Echo "${PROGRESS}"
 
    if [ $? -ne 0 ] || [[ "${PROGRESS}" =~ "Invalid" ]] ; then
		echo -e >&2 "\033[1;31mNotarization failed\033[0m"
		exit -1
        break
    fi
 
    if [[ "${PROGRESS}" =~ "success" ]]; then
        NOTARIZATION_SUCCESS=1
        break
    fi
    sleep 30
done

if [ $NOTARIZATION_SUCCESS -ne 1 ] ; then
	echo -e >&2 "\033[1;31mNotarization timed out\033[0m"
	exit -1
fi

echo -e "\033[1;34mStapling notarization ticket\033[0m"

xcrun stapler staple "${EXPORT_DIR}/Detox Instruments.app"

echo -e "\033[1;34mCreating stapled ZIP file\033[0m"

rm "${ZIP_FILE}"
ditto -c -k --sequesterRsrc --keepParent "${EXPORT_DIR}"/*.app "${ZIP_FILE}" &> /dev/null

echo -e "\033[1;34mUpdating archive with submission\033[0m"

SUBMISSION_IN_ARCHIVE="${ARCHIVE}/Submissions/${NOTARIZATION_UUID}"

mkdir -p "${SUBMISSION_IN_ARCHIVE}"
cp -r "${EXPORT_DIR}/Detox Instruments.app" "${SUBMISSION_IN_ARCHIVE}/"

LOG_URL=$(xcrun altool --notarization-info "${NOTARIZATION_UUID}" --username "lnatan@wix.com" --password "@keychain:notary_password" 2>&1 | grep LogFileURL | awk '{print $2}')
curl -o "${SUBMISSION_IN_ARCHIVE}/audit.log" "${LOG_URL}" &> /dev/null

/usr/libexec/PlistBuddy -c "Add Distributions array" ${ARCHIVE}/Info.plist
/usr/libexec/PlistBuddy -c "Add Distributions:0 dict" ${ARCHIVE}/Info.plist
/usr/libexec/PlistBuddy -c "Add Distributions:0:destination string upload" ${ARCHIVE}/Info.plist
/usr/libexec/PlistBuddy -c "Add Distributions:0:identifier string ${NOTARIZATION_UUID}" ${ARCHIVE}/Info.plist
/usr/libexec/PlistBuddy -c "Add Distributions:0:task string distribute" ${ARCHIVE}/Info.plist
/usr/libexec/PlistBuddy -c "Add Distributions:0:teamID string S3GLW74Y8N" ${ARCHIVE}/Info.plist
/usr/libexec/PlistBuddy -c "Add Distributions:0:uploadDestination string 'Developer ID'" ${ARCHIVE}/Info.plist

/usr/libexec/PlistBuddy -c "Add Distributions:0:uploadEvent:shortTitle string Uploaded" ${ARCHIVE}/Info.plist
/usr/libexec/PlistBuddy -c "Add Distributions:0:uploadEvent:state string success" ${ARCHIVE}/Info.plist
/usr/libexec/PlistBuddy -c "Add Distributions:0:uploadEvent:title string 'Uploaded to Apple'" ${ARCHIVE}/Info.plist
/usr/libexec/PlistBuddy -c "Add Distributions:0:uploadEvent:date date $(date)" ${ARCHIVE}/Info.plist

/usr/libexec/PlistBuddy -c "Add Distributions:0:preparationEvent:shortTitle string Prepared" ${ARCHIVE}/Info.plist
/usr/libexec/PlistBuddy -c "Add Distributions:0:preparationEvent:state string success" ${ARCHIVE}/Info.plist
/usr/libexec/PlistBuddy -c "Add Distributions:0:preparationEvent:title string 'Prepared archive for uploading'" ${ARCHIVE}/Info.plist
/usr/libexec/PlistBuddy -c "Add Distributions:0:preparationEvent:date date $(date)" ${ARCHIVE}/Info.plist

/usr/libexec/PlistBuddy -c "Add Distributions:0:processingCompletedEvent:shortTitle string 'Ready to distribute'" ${ARCHIVE}/Info.plist
/usr/libexec/PlistBuddy -c "Add Distributions:0:processingCompletedEvent:state string success" ${ARCHIVE}/Info.plist
/usr/libexec/PlistBuddy -c "Add Distributions:0:processingCompletedEvent:title string 'Ready to distribute'" ${ARCHIVE}/Info.plist
/usr/libexec/PlistBuddy -c "Add Distributions:0:processingCompletedEvent:date date $(date)" ${ARCHIVE}/Info.plist

echo -e "\033[1;34mUpdating cask with latest release\033[0m"

if [ -z "$DRY_RUN" ]; then
	pushd . &> /dev/null
	cd Distribution/homebrew-brew/Casks/
	git checkout master
	git fetch
	git pull --rebase
	sed -i '' -e 's/url .*/url '"'https:\/\/github.com\/wix\/DetoxInstruments\/releases\/download\/${VERSION}\/$(basename ${ZIP_FILE})'"'/g' detox-instruments.rb
	git add -A
	git commit -m "Detox Instruments ${VERSION}" &> /dev/null
	git push
	popd &> /dev/null
fi

echo -e "\033[1;34mPushing updated versions\033[0m"

if [ -z "$DRY_RUN" ]; then
	git add -A &> /dev/null
	git commit -m "${VERSION}" &> /dev/null
	git push
fi

if [ -z "$DRY_RUN" ]; then
	#Escape user input in markdown to valid JSON string using PHP 🤦‍♂️ (https://stackoverflow.com/a/13466143/983912)
	RELEASENOTESCONTENTS=$(printf '%s' "$(<"${RELEASE_NOTES_FILE}")" | php -r 'echo json_encode(file_get_contents("php://stdin"));')
fi

echo -e "\033[1;34mCreating a GitHub release\033[0m"

if [ -z "$DRY_RUN" ]; then
	API_JSON=$(printf '{"tag_name": "%s","target_commitish": "master", "name": "v%s", "body": %s, "draft": false, "prerelease": false}' "$VERSION" "$VERSION" "$RELEASENOTESCONTENTS")
	RELEASE_ID=$(curl -s --data "$API_JSON" https://api.github.com/repos/wix/DetoxInstruments/releases?access_token=${GITHUB_RELEASES_TOKEN} | jq ".id")
fi

echo -e "\033[1;34mUploading ZIP attachment to release\033[0m"

if [ -z "$DRY_RUN" ]; then
	curl -s --data-binary @"${ZIP_FILE}" -H "Content-Type: application/octet-stream" "https://uploads.github.com/repos/wix/DetoxInstruments/releases/${RELEASE_ID}/assets?name=$(basename ${ZIP_FILE})&access_token=${GITHUB_RELEASES_TOKEN}" | jq "."
fi

echo -e "\033[1;34mTriggering gh-pages rebuild\033[0m"

if [ -z "$DRY_RUN" ]; then
	curl -H "Content-Type: application/json; charset=UTF-8" -X PUT -d '{"message": "Rebuild GH Pages", "committer": { "name": "PublishScript", "email": "somefakeaddress@wix.com" }, "content": "LnB1Ymxpc2gK", "sha": "3f949857e8ed4cb106f9744e40b638a7aabf647f", "branch": "gh-pages"}' https://api.github.com/repos/wix/DetoxInstruments/contents/.publish?access_token=${GITHUB_RELEASES_TOKEN} | jq "."
fi

echo -e "\033[1;34mCreating an NPM release\033[0m"

if [ -z "$DRY_RUN" ]; then
	pushd . &> /dev/null
	cd Distribution
	mv package package.json
	NPM_VERSION="${SHORT_VERSION}"
	if [[ $(echo ${NPM_VERSION} | grep -o "\." | grep -c "\.") == 1 ]]; then
		NPM_VERSION="${NPM_VERSION}."
	fi
	NPM_VERSION="${NPM_VERSION}${BUILD_NUMBER}"	
	npm version "${NPM_VERSION}" --allow-same-version &> /dev/null
	npm publish
	mv package.json package
	git checkout package
	popd &> /dev/null
fi

echo -e "\033[1;34mOpening archive in Xcode\033[0m"

if [ -z "$DRY_RUN" ]; then
	open "${ARCHIVE}"
	sleep 8
fi

echo -e "\033[1;34mCleaning up\033[0m"

if [ -z "$DRY_RUN" ]; then
	rm -f "${RELEASE_NOTES_FILE}"
fi
rm -f "${ZIP_FILE}"
rm -fr "${ARCHIVE}"
rm -fr "${EXPORT_DIR}"
