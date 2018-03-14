#!/bin/bash -e

if  [[ -n $(git status --porcelain) ]]; then
	printf >&2 "\033[1;31mCannot release version because there are unstaged changes, aborting.\nChanges:\033[0m\n"
	git status --short
	exit -1
fi

if [[ -n $(git log --branches --not --remotes) ]]; then
	echo -e "\033[1;34mPushing pending commits to git\033[0m"
	git push &> /dev/null
fi

echo -e "\033[1;34mCreating release notes\033[0m"

RELEASE_NOTES_FILE=Distribution/_tmp_release_notes.md

rm -f "${RELEASE_NOTES_FILE}"
touch "${RELEASE_NOTES_FILE}"
open -Wn "${RELEASE_NOTES_FILE}"

if ! [ -s "${RELEASE_NOTES_FILE}" ]; then
  echo >&2 "\033[1;31mNo release notes provided, aborting.\033[0m"
  rm -f "${RELEASE_NOTES_FILE}"
  exit -1
fi

echo -e "\033[1;34mBuilding archive and exporting\033[0m"

ARCHIVE=Distribution/Archive.xcarchive
EXPORT_DIR=Distribution/Export

rm -fr "${ARCHIVE}"
rm -fr "${EXPORT_DIR}"

xcodebuild -project DetoxInstruments/DetoxInstruments.xcodeproj -scheme "Detox Instruments" archive -archivePath "${ARCHIVE}" | xcpretty >/dev/null 2>/dev/null
xcodebuild -project DetoxInstruments/DetoxInstruments.xcodeproj -exportArchive -archivePath "${ARCHIVE}" -exportOptionsPlist Distribution/exportOptions.plist -exportPath "${EXPORT_DIR}" | xcpretty >/dev/null 2>/dev/null

SHORT_VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "${EXPORT_DIR}"/*.app/Contents/Info.plist)
BUILD_NUMBER=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "${EXPORT_DIR}"/*.app/Contents/Info.plist)

VERSION="${SHORT_VERSION}"."${BUILD_NUMBER}"
ZIP_FILE=Distribution/DetoxInstruments-v"${SHORT_VERSION}".b"${BUILD_NUMBER}".zip

echo -e "\033[1;34mUpdating cask with latest release\033[0m"

pushd . &> /dev/null
cd Distribution/homebrew-brew/Casks/
git fetch &> /dev/null
git checkout master &> /dev/null
sed -i '' -e 's/url .*/url '"'https:\/\/github.com\/wix\/DetoxInstruments\/releases\/download\/${VERSION}\/$(basename ${ZIP_FILE})'"'/g' detox-instruments.rb
git add -A &> /dev/null
git commit -m "Detox Instruments ${VERSION}" &> /dev/null
git push &> /dev/null
popd &> /dev/null

echo -e "\033[1;34mPushing updated versions\033[0m"

git add -A &> /dev/null
git commit -m "${VERSION}" &> /dev/null
git push &> /dev/null

echo -e "\033[1;34mCreating ZIP file\033[0m"

ditto -c -k --sequesterRsrc --keepParent "${EXPORT_DIR}"/*.app "${ZIP_FILE}" &> /dev/null

#Escape user input in markdown to valid JSON string using PHP 🤦‍♂️ (https://stackoverflow.com/a/13466143/983912)
RELEASENOTESCONTENTS=$(printf '%s' "$(<"${RELEASE_NOTES_FILE}")" | php -r 'echo json_encode(file_get_contents("php://stdin"));')

echo -e "\033[1;34mCreating a GitHub release\033[0m"

API_JSON=$(printf '{"tag_name": "%s","target_commitish": "master", "name": "v%s", "body": %s, "draft": false, "prerelease": false}' "$VERSION" "$VERSION" "$RELEASENOTESCONTENTS")
RELEASE_ID=$(curl -s --data "$API_JSON" https://api.github.com/repos/wix/DetoxInstruments/releases?access_token=${GITHUB_RELEASES_TOKEN} | jq ".id")

echo -e "\033[1;34mUploading ZIP attachment to release\033[0m"

curl -s --data-binary @"${ZIP_FILE}" -H "Content-Type: application/octet-stream" "https://uploads.github.com/repos/wix/DetoxInstruments/releases/${RELEASE_ID}/assets?name=$(basename ${ZIP_FILE})&access_token=${GITHUB_RELEASES_TOKEN}" | jq "." &> /dev/null

echo -e "\033[1;34mTriggering gh-pages rebuild\033[0m"

curl -H "Content-Type: application/json; charset=UTF-8" -X PUT -d '{"message": "Rebuild GH Pages", "committer": { "name": "PublishScript", "email": "somefakeaddress@wix.com" }, "content": "LnB1Ymxpc2gK", "sha": "3f949857e8ed4cb106f9744e40b638a7aabf647f", "branch": "gh-pages"}' https://api.github.com/repos/wix/DetoxInstruments/contents/.publish?access_token=${GITHUB_RELEASES_TOKEN}

echo -e "\033[1;34mOpening archive in Xcode\033[0m"

open "${ARCHIVE}"
sleep 8

echo -e "\033[1;34mCleaning up\033[0m"

rm -f "${RELEASE_NOTES_FILE}"
rm -f "${ZIP_FILE}"
rm -fr "${ARCHIVE}"
rm -fr "${EXPORT_DIR}"