#!/bin/bash -e

rm -f Documentation/Acknowledgements.md
touch Documentation/Acknowledgements.md

printf "# Acknowledgements\n\n" >> Documentation/Acknowledgements.md

SUBMODULES=$(git submodule --quiet foreach git config --get remote.origin.url)

# CONTRIB_USERS=$(curl -s https://api.github.com/repos/wix/DetoxInstruments/contributors?access_token=${GITHUB_RELEASES_TOKEN} | jq -r .[].login)
while read -r line; do
  # echo $line
  
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
  
  printf "### $REPO_NAME - <https://github.com/$REPO_FULL_NAME>\n\n" >> Documentation/Acknowledgements.md
  printf "\`\`\`\n" >> Documentation/Acknowledgements.md
  echo "$LICENSE_CONTENT" >> Documentation/Acknowledgements.md
  printf "\n\`\`\`\n\n" >> Documentation/Acknowledgements.md
  
  # USER=$(curl -s https://api.github.com/users/${line}?access_token=${GITHUB_RELEASES_TOKEN})
  # echo $(echo $USER | jq -r .name) "("$(echo $USER | jq -r .company)")" >> Contributors.txt
done <<< "$SUBMODULES"