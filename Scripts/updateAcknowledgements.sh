#!/bin/bash -e

rm -f Documentation/Acknowledgements.md
touch Documentation/Acknowledgements.md

printf "# Acknowledgements\n\n" >> Documentation/Acknowledgements.md

SUBMODULES=$(git submodule --quiet foreach git config --get remote.origin.url)
# Append implicit dependency of Mozilla's source-map
SUBMODULES=$(printf "$SUBMODULES\nhttps://github.com/facebook/fishhook.git")
SUBMODULES=$(printf "$SUBMODULES\nhttps://github.com/mozilla/source-map.git")
SUBMODULES=$(printf "$SUBMODULES\nhttps://github.com/phranck/CCNPreferencesWindowController.git")
SUBMODULES=$(printf "$SUBMODULES\nhttps://github.com/nicklockwood/AutoCoding.git")
SUBMODULES=$(printf "$SUBMODULES\nhttps://github.com/pixelglow/ZipZap.git")
SUBMODULES=$(echo "$SUBMODULES" | sort --ignore-case)

while read -r line; do  
  REPO_FULL_NAME=`expr "$line" : '^https:\/\/github.com\/\(.*\).git'`
  REPO_NAME=`expr "$REPO_FULL_NAME" : '^.*\/\(.*\)'`

  if [[ $line = *"github.com/wix"* ]]; then
    PARENT=$(gh api repos/${REPO_FULL_NAME} | jq -r .parent.full_name)
    
    if [ "$PARENT" != "null" ]; then
      REPO_FULL_NAME="$PARENT"
    else
      # Skip Wix internal open sources
      continue
    fi
  fi

  LICENSE=$(gh api repos/${REPO_FULL_NAME}/license)
  LICENSE_CONTENT=$(echo "$LICENSE" | jq -r .content | base64 --decode)
  
  printf "### $REPO_NAME — <https://github.com/$REPO_FULL_NAME>\n\n" >> Documentation/Acknowledgements.md
  printf "\`\`\`\n" >> Documentation/Acknowledgements.md
  echo "$LICENSE_CONTENT" >> Documentation/Acknowledgements.md
  printf "\n\`\`\`\n\n" >> Documentation/Acknowledgements.md
done <<< "$SUBMODULES"

TARGET_FILE=DetoxInstruments/DetoxInstruments/Resources/Acknowledgements.html

echo '<!DOCTYPE html>' > "${TARGET_FILE}"
echo '<html><head><meta name="AppleTitle" content="Detox Instruments Help" /><meta name="copyright" content="Copyright © 2018" /><meta charset="UTF-8">' >> "${TARGET_FILE}"
echo '<style>body { font-family: -apple-system-font; word-break: normal; word-wrap: normal; }' >> "${TARGET_FILE}"
echo 'pre { padding-left: 2em; white-space: pre; }'  >> "${TARGET_FILE}"
echo 'ul { padding-left: 1.3em; }'  >> "${TARGET_FILE}"
echo '</style>' >> "${TARGET_FILE}"
echo '<title>Acknowledgements</title></head><body>' >> "${TARGET_FILE}"

CONTENTS=$(printf '%s' "$(<Documentation/Acknowledgements.md)" | php -r 'echo json_encode(file_get_contents("php://stdin"));')
API_JSON=$(printf '{"text": %s}' "$CONTENTS")
curl -H "Authorization: token ${GITHUB_RELEASES_TOKEN}" -s --data "$API_JSON" "https://api.github.com/markdown >> "${TARGET_FILE}"

echo '</body></html>' >> "${TARGET_FILE}"