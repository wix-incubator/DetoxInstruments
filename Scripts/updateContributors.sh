#!/bin/bash -e

env

# GIT_FILE=./DetoxInstruments/DetoxInstruments/ContributionsGit.json
GH_FILE=./DetoxInstruments/DetoxInstruments/ContributionsGH.json

# git log --pretty=format:'{%n  "commit": "%H",%n  "abbreviated_commit": "%h",%n  "tree": "%T",%n  "abbreviated_tree": "%t",%n  "parent": "%P",%n  "abbreviated_parent": "%p",%n  "refs": "%D",%n  "encoding": "%e",%n  "sanitized_subject_line": "%f",%n  "commit_notes": "%N",%n  "verification_flag": "%G?",%n  "signer": "%GS",%n  "signer_key": "%GK",%n  "author": {%n    "name": "%aN",%n    "email": "%aE",%n    "date": "%aD"%n  },%n  "commiter": {%n    "name": "%cN",%n    "email": "%cE",%n    "date": "%cD"%n  }%n},' | sed "$ s/,$//" | sed ':a;N;$!ba;s/\r\n\([^{]\)/\\n\1/g'| awk 'BEGIN { print("[") } { print($0) } END { print("]") }' | jq -r "[.[].author] | group_by(.name) | sort_by(-length) | map({ \"name\":.[0].name, \"total_contributions\":length, \"emails\":(group_by(.email) | sort_by(-length) | map({\"key\":.[0].email, \"value\":length }) | from_entries) })" > "${GIT_FILE}"

contributors=$(curl -s "https://api.github.com/repos/wix/DetoxInstruments/stats/contributors?access_token=${GITHUB_RELEASES_TOKEN}" | jq -r "sort_by(-.total)")
contributor_count=$(echo $contributors | jq ". | length")
echo "[" > "${GH_FILE}"
for idx in $(seq 0 $((contributor_count - 1)))
do
  contributor=$(echo $contributors | jq ".[$idx]")
  total_contributions=$(echo $contributor | jq ".total")
  login_name=$(echo $contributor | jq -r ".author.login")
  user=$(curl -s "https://api.github.com/users/${login_name}?access_token=${GITHUB_RELEASES_TOKEN}")
  name=$(echo $user | jq -r ".name")
  if [ "$name" = "null" ]; then
    name=$login_name
  fi
  delim=","
  if [ "$idx" = "$((contributor_count - 1))" ]; then
    delim=""
  fi
  url=$(echo $user | jq -r ".html_url")
  avatar_url=$(echo $user | jq -r ".avatar_url")
  echo "{\"name\":\"${name}\", \"url\":\"${url}\", \"login\":\"${login_name}\", \"total_contributions\":${total_contributions}, \"avatar_url\":\"${avatar_url}\"}${delim}" >> "${GH_FILE}"
done
echo "]" >> "${GH_FILE}"