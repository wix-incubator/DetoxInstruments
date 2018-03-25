#!/bin/bash -e

rm -f Contributors.txt
touch Contributors.txt

CONTRIB_USERS=$(curl -s https://api.github.com/repos/wix/DetoxInstruments/contributors?access_token=${GITHUB_RELEASES_TOKEN} | jq -r .[].login)
while read -r line; do
  USER=$(curl -s https://api.github.com/users/${line}?access_token=${GITHUB_RELEASES_TOKEN})
  echo $(echo $USER | jq -r .name) "("$(echo $USER | jq -r .company)")" >> Contributors.txt
done <<< "$CONTRIB_USERS"