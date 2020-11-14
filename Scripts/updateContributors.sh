#!/bin/bash -e

GH_FILE=./DetoxInstruments/DetoxInstruments/Resources/ContributionsGH.json

response_success=0
for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do
	response=$(gh api /repos/wix/DetoxInstruments/contributors\?anon=1)
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

contributors=$(echo "${response}" | jq -r "sort_by(-.contributions)")
contributor_count=$(echo $contributors | jq ". | length")
echo "[" > "${GH_FILE}"
for idx in $(seq 0 $((contributor_count - 1)))
do
  contributor=$(echo $contributors | jq ".[$idx]")
  
  contributor_type=$(echo $contributor | jq -r ".type")
  total_contributions=$(echo $contributor | jq -r ".contributions")
  delim=","
  if [ "$idx" = "$((contributor_count - 1))" ]; then
    delim=""
  fi
  
  if [ "$contributor_type" == "User" ]; then
	  login_name=$(echo $contributor | jq -r ".login")
	  user=$(gh api users/${login_name})
	  name=$(echo $user | jq -r ".name")
	  if [ "$name" == "null" ]; then
	    name=$login_name
	  fi
	  url=$(echo $user | jq -r ".html_url")
	  avatar_url=$(echo $user | jq -r ".avatar_url")
	  echo "{\"type\":\"${contributor_type}\", \"name\":\"${name}\", \"url\":\"${url}\", \"login\":\"${login_name}\", \"total_contributions\":${total_contributions}, \"avatar_url\":\"${avatar_url}\"}${delim}" >> "${GH_FILE}"
  else
	  name=$(echo $contributor | jq -r ".name")
	  email=$(echo $contributor | jq -r ".email")
	  echo "{\"type\":\"${contributor_type}\", \"name\":\"${name}\", \"email\":\"${email}\", \"total_contributions\":${total_contributions}}${delim}" >> "${GH_FILE}"
  fi
done
echo "]" >> "${GH_FILE}"