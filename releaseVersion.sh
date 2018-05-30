#!/bin/bash -e

# This script is responsible for creating a release and getting all the gears in motion
# so that cask, appcast and GitHub releases are all updated with the new release.
# Prerequisites:
#	$GITHUB_RELEASES_TOKEN should be valid and include a GitHub OAuth 2 token with at least repo permission.
#		See https://help.github.com/articles/creating-a-personal-access-token-for-the-command-line/ and https://github.com/settings/tokens 
#	jq for json parsing and querying.
#		brew install jq

BRANCH=$(git rev-parse --abbrev-ref HEAD)

if [ ! "$BRANCH" = "master" ]; then
  printf >&2 "\033[1;31mNot on master branch, performing a dry run.\033[0m\n"
else 
  if [ "$1" = "--dry" ]; then
    DRY_RUN=$1
  fi
fi

if [ ! -z "$DRY_RUN" ]; then
  printf >&2 "\033[1;31mPerforming a dry run.\033[0m\n"
fi

if  [[ -n $(git status --porcelain) ]]; then
	printf >&2 "\033[1;31mCannot release version because there are unstaged changes, aborting.\nChanges:\033[0m\n"
	git status --short
	exit -1
fi

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
  echo -e >&2 "\033[1;31mNo release notes provided, aborting.\033[0m"
  rm -f "${RELEASE_NOTES_FILE}"
  exit -1
fi
fi

echo -e "\033[1;34mUpdating acknowledgements and Apple Help\033[0m"

./updateAcknowledgements.sh
./updateHelp.sh

echo -e "\033[1;34mBuilding archive and exporting\033[0m"

ARCHIVE=Distribution/Archive.xcarchive
EXPORT_DIR=Distribution/Export

rm -fr "${ARCHIVE}"
rm -fr "${EXPORT_DIR}"

export CODE_SIGNING_REQUIRED=NO && xcodebuild -project DetoxInstruments/DetoxInstruments.xcodeproj -scheme "Detox Instruments" archive -archivePath "${ARCHIVE}" | xcpretty
xcodebuild -project DetoxInstruments/DetoxInstruments.xcodeproj -exportArchive -archivePath "${ARCHIVE}" -exportOptionsPlist Distribution/exportOptions.plist -exportPath "${EXPORT_DIR}" | xcpretty

SHORT_VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "${EXPORT_DIR}"/*.app/Contents/Info.plist)
BUILD_NUMBER=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "${EXPORT_DIR}"/*.app/Contents/Info.plist)

VERSION="${SHORT_VERSION}"."${BUILD_NUMBER}"
ZIP_FILE=Distribution/DetoxInstruments-v"${SHORT_VERSION}".b"${BUILD_NUMBER}".zip

echo -e "\033[1;34mVersion is: $VERSION\033[0m"

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

echo -e "\033[1;34mCreating ZIP file\033[0m"

ditto -c -k --sequesterRsrc --keepParent "${EXPORT_DIR}"/*.app "${ZIP_FILE}" &> /dev/null

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
curl -s --data-binary @"${ZIP_FILE}" -H "Content-Type: application/octet-stream" "https://uploads.github.com/repos/wix/DetoxInstruments/releases/${RELEASE_ID}/assets?name=$(basename ${ZIP_FILE})&access_token=${GITHUB_RELEASES_TOKEN}" | jq "." &> /dev/null
fi

echo -e "\033[1;34mTriggering gh-pages rebuild\033[0m"

if [ -z "$DRY_RUN" ]; then
curl -H "Content-Type: application/json; charset=UTF-8" -X PUT -d '{"message": "Rebuild GH Pages", "committer": { "name": "PublishScript", "email": "somefakeaddress@wix.com" }, "content": "LnB1Ymxpc2gK", "sha": "3f949857e8ed4cb106f9744e40b638a7aabf647f", "branch": "gh-pages"}' https://api.github.com/repos/wix/DetoxInstruments/contents/.publish?access_token=${GITHUB_RELEASES_TOKEN} | jq "." &> /dev/null
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
