#!/bin/bash -e

# GIT_FILE=./DetoxInstruments/DetoxInstruments/Resources/ContributionsGit.json
GH_FILE=./DetoxInstruments/DetoxInstruments/Resources/ContributionsGH.json

# git log --pretty=format:'{%n  "commit": "%H",%n  "abbreviated_commit": "%h",%n  "tree": "%T",%n  "abbreviated_tree": "%t",%n  "parent": "%P",%n  "abbreviated_parent": "%p",%n  "refs": "%D",%n  "encoding": "%e",%n  "sanitized_subject_line": "%f",%n  "commit_notes": "%N",%n  "verification_flag": "%G?",%n  "signer": "%GS",%n  "signer_key": "%GK",%n  "author": {%n    "name": "%aN",%n    "email": "%aE",%n    "date": "%aD"%n  },%n  "commiter": {%n    "name": "%cN",%n    "email": "%cE",%n    "date": "%cD"%n  }%n},' | sed "$ s/,$//" | sed ':a;N;$!ba;s/\r\n\([^{]\)/\\n\1/g'| awk 'BEGIN { print("[") } { print($0) } END { print("]") }' | jq -r "[.[].author] | group_by(.name) | sort_by(-length) | map({ \"name\":.[0].name, \"total_contributions\":length, \"emails\":(group_by(.email) | sort_by(-length) | map({\"key\":.[0].email, \"value\":length }) | from_entries) })" > "${GIT_FILE}"

response_success=0
for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do
	response=$(curl -H "Authorization: token ${GITHUB_RELEASES_TOKEN}" -s "https://api.github.com/repos/wix/DetoxInstruments/stats/contributors")
	response_type=$(echo "${response}" | jq -r type)
	
	if [ "${response_type}" = "array" ]; then
		response_success=1
		break
	fi
	
	sleep 10
done

if [ $response_success -ne 1 ] ; then
	echo -e >&2 "\033[1;31mFailed to update contributors\033[0m"
	exit -1
fi

contributors=$(echo "${response}" | jq -r "sort_by(-.total)")
contributor_count=$(echo $contributors | jq ". | length")
echo "[" > "${GH_FILE}"
for idx in $(seq 0 $((contributor_count - 1)))
do
  contributor=$(echo $contributors | jq ".[$idx]")
  total_contributions=$(echo $contributor | jq ".total")
  login_name=$(echo $contributor | jq -r ".author.login")
  user=$(curl -H "Authorization: token ${GITHUB_RELEASES_TOKEN}" -s "https://api.github.com/users/${login_name}")
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