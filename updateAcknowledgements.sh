#!/bin/bash -e

rm -f Documentation/Acknowledgements.md
touch Documentation/Acknowledgements.md

printf "# Acknowledgements\n\n" >> Documentation/Acknowledgements.md

SUBMODULES=$(git submodule --quiet foreach git config --get remote.origin.url)
# Append implicit dependency of Mozilla's source-map
SUBMODULES=$(printf "$SUBMODULES\nhttps://github.com/mozilla/source-map.git")
SUBMODULES=$(echo "$SUBMODULES" | sort --ignore-case)

while read -r line; do  
  REPO_FULL_NAME=`expr "$line" : '^https:\/\/github.com\/\(.*\).git'`
  REPO_NAME=`expr "$REPO_FULL_NAME" : '^.*\/\(.*\)'`

  if [[ $line = *"github.com/wix"* ]]; then
    PARENT=$(curl -s https://api.github.com/repos/${REPO_FULL_NAME}?access_token=${GITHUB_RELEASES_TOKEN} | jq -r .parent.full_name)
    
    if [ "$PARENT" != "null" ]; then
      REPO_FULL_NAME="$PARENT"
    else
      # Skip Wix internal open sources
      continue
    fi
  fi

  LICENSE=$(curl -s https://api.github.com/repos/${REPO_FULL_NAME}/license?access_token=${GITHUB_RELEASES_TOKEN})
  LICENSE_CONTENT=$(echo "$LICENSE" | jq -r .content | base64 --decode)
  
  printf "### $REPO_NAME — <https://github.com/$REPO_FULL_NAME>\n\n" >> Documentation/Acknowledgements.md
  printf "\`\`\`\n" >> Documentation/Acknowledgements.md
  echo "$LICENSE_CONTENT" >> Documentation/Acknowledgements.md
  printf "\n\`\`\`\n\n" >> Documentation/Acknowledgements.md
done <<< "$SUBMODULES"

TARGET_FILE=DetoxInstruments/DetoxInstruments/Acknowledgements.html

echo '<!DOCTYPE html>' > "${TARGET_FILE}"
echo '<html><head><meta name="AppleTitle" content="Detox Instruments Help" /><meta name="copyright" content="Copyright © 2018" /><meta charset="UTF-8"><style>' >> "${TARGET_FILE}"
# curl -s 'https://raw.githubusercontent.com/sindresorhus/github-markdown-css/gh-pages/github-markdown.css' >> "${TARGET_FILE}"
echo '</style>' >> "${TARGET_FILE}"
echo '<style>body { font-family: -apple-system-font, -webkit-system-font, "HelveticaNeue", "Helvetica Neue", "Helvetica", sans-serif; font-size: 16px; padding: 0px 10px 20px 10px; }'  >> "${TARGET_FILE}"
echo 'img { max-width: 100%; height: auto; }'  >> "${TARGET_FILE}"
echo 'pre { background-color: rgb(246, 248, 250); border-bottom-left-radius: 3px; border-bottom-right-radius: 3px; border-top-left-radius: 3px; border-top-right-radius: 3px; box-sizing: border-box; color: rgb(36, 41, 46); display: block; font-family: SFMono-Regular, Consolas, "Liberation Mono", Menlo, Courier, monospace; font-size: 13.600000381469727px; line-height: 19px; margin-bottom: 0px; margin-left: 0px; margin-right: 0px; margin-top: 0px; overflow-x: auto; overflow-y: auto; padding-bottom: 16px; padding-left: 16px; padding-right: 16px; padding-top: 16px; white-space: pre; word-break: normal; word-wrap: normal; }'  >> "${TARGET_FILE}"
echo 'blockquote { border-left-color: rgb(223, 226, 229); border-left-style: solid; border-left-width: 4px; box-sizing: border-box; color: rgb(106, 115, 125); display: block; margin-bottom: 16px; margin-left: 0px; margin-right: 0px; margin-top: 0px; padding-bottom: 0px; padding-left: 16px; padding-right: 16px; padding-top: 0px; word-wrap: break-word; }' >> "${TARGET_FILE}"
echo 'ul { padding-left: 1.3em; }'  >> "${TARGET_FILE}"
echo '</style>' >> "${TARGET_FILE}"
echo '<title>Acknowledgements</title></head><body>' >> "${TARGET_FILE}"

CONTENTS=$(printf '%s' "$(<Documentation/Acknowledgements.md)" | php -r 'echo json_encode(file_get_contents("php://stdin"));')
API_JSON=$(printf '{"text": %s}' "$CONTENTS")
curl -s --data "$API_JSON" "https://api.github.com/markdown?access_token=${GITHUB_RELEASES_TOKEN}" >> "${TARGET_FILE}"

echo '</body></html>' >> "${TARGET_FILE}"