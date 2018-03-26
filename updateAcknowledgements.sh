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

rm -f DetoxInstruments/DetoxInstruments/Acknowledgements.html
touch DetoxInstruments/DetoxInstruments/Acknowledgements.html

ACKNOWLEDGEMENTSCONTENTS=$(printf '%s' "$(<Documentation/Acknowledgements.md)" | php -r 'echo json_encode(file_get_contents("php://stdin"));')
API_JSON=$(printf '{"text": %s}' "$ACKNOWLEDGEMENTSCONTENTS")

echo '<!DOCTYPE html>' >> DetoxInstruments/DetoxInstruments/Acknowledgements.html
echo '<html><head><meta charset="UTF-8" /><style>' >> DetoxInstruments/DetoxInstruments/Acknowledgements.html
curl -s 'https://gist.githubusercontent.com/andyferra/2554919/raw/2e66cabdafe1c9a7f354aa2ebf5bc38265e638e5/github.css' >> DetoxInstruments/DetoxInstruments/Acknowledgements.html
echo '</style></head><body>' >> DetoxInstruments/DetoxInstruments/Acknowledgements.html
curl -s --data "$API_JSON" "https://api.github.com/markdown?access_token=${GITHUB_RELEASES_TOKEN}" >> DetoxInstruments/DetoxInstruments/Acknowledgements.html
echo '</body></html>' >> DetoxInstruments/DetoxInstruments/Acknowledgements.html