#!/bin/bash -e

pushd .
cd Documentation/Resources
for PNG in *.png ;
do
	echo -e "\033[1;34mCrushing $PNG\033[0m"
	pngcrush -reduce -m 123 -ow "$PNG"
done ;
popd

HTMLDIR=DetoxInstruments/DetoxInstruments.help/Contents/Resources/English.lproj

rm -fr "${HTMLDIR}"/Documentation
mkdir -p "${HTMLDIR}"/Documentation
cp -R Documentation/Resources "${HTMLDIR}"/Documentation/

pushd . > /dev/null
cd "${HTMLDIR}"/Documentation/Resources/
for PNG in *.png ;
do
	# convert "$PNG" -flatten -alpha off -resize 50% "$PNG"
	# pngcrush -reduce -m 123 -ow "$PNG"
	echo -e "\033[1;34mConverting $PNG\033[0m"
	convert "$PNG" -flatten -alpha off -resize 50% -quality 90 "$PNG".jpg
	mv -f "$PNG".jpg "$PNG"
done ;
popd > /dev/null

cp DetoxInstruments/DetoxInstruments/Assets.xcassets/AppIcon.appiconset/Icon-512@2x.png "${HTMLDIR}"/Documentation/Resources/icon_512x512@2x.png
cp DetoxInstruments/DetoxInstruments/Assets.xcassets/AppIcon.appiconset/Icon-512@2x.png "${HTMLDIR}"/../shrd/icon.png

function render_markdown {
  SOURCE_FILE="$1"
  TARGET_FILE="$2"
  METADATA_DIR="$3"

  echo '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">' > "${TARGET_FILE}"
  echo '<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">' >> "${TARGET_FILE}"
  echo '<head>' >> "${TARGET_FILE}"
  cat "$METADATA_DIR"/$(basename "$SOURCE_FILE").metadata >> "${TARGET_FILE}"
  echo '<meta name="viewport" content="width=device-width, initial-scale=1" />' >> "${TARGET_FILE}"
  echo '<meta name="supported-color-schemes" content="light">' >> "${TARGET_FILE}"
  echo '<meta http-equiv="Content-Type" content="text/html; charset=utf-8" /><meta name="copyright" content="Copyright © 2018" /><style type="text/css">' >> "${TARGET_FILE}"
  echo 'html {' >> "${TARGET_FILE}"
  echo 'overflow: auto;' >> "${TARGET_FILE}"
  echo '}' >> "${TARGET_FILE}"
  echo 'body {' >> "${TARGET_FILE}"
  echo 'position: absolute;' >> "${TARGET_FILE}"
  echo 'left: 0px;' >> "${TARGET_FILE}"
  echo 'right: 0px;' >> "${TARGET_FILE}"
  echo 'top: 0px;' >> "${TARGET_FILE}"
  echo 'bottom: 0px;' >> "${TARGET_FILE}"
  echo 'overflow-y: scroll;' >> "${TARGET_FILE}"
  echo 'overflow-x: hidden;' >> "${TARGET_FILE}"
  echo 'margin: 0px;' >> "${TARGET_FILE}"
  echo '}' >> "${TARGET_FILE}"
  echo '</style>' >> "${TARGET_FILE}"
  echo '<style type="text/css">body { font-family: -apple-system-font, -webkit-system-font, "HelveticaNeue", "Helvetica Neue", "Helvetica", sans-serif; font-size: 13px; padding: 0px 10px 20px 10px; }'  >> "${TARGET_FILE}"
  echo 'h1 { text-align: center; margin-left: -16px; margin-right: -16px; padding-bottom: 20px; background: linear-gradient(to bottom, #ffffff 0%,#f3f2f3 100%); }' >> "${TARGET_FILE}"
  echo 'img { max-width: 100%; height: auto; }'  >> "${TARGET_FILE}"
  echo 'pre { background-color: rgb(246, 248, 250); border-bottom-left-radius: 3px; border-bottom-right-radius: 3px; border-top-left-radius: 3px; border-top-right-radius: 3px; box-sizing: border-box; color: rgb(36, 41, 46); display: block; font-family: SFMono-Regular, Consolas, "Liberation Mono", Menlo, Courier, monospace; font-size: 13.600000381469727px; line-height: 19px; margin-bottom: 0px; margin-left: 0px; margin-right: 0px; margin-top: 0px; overflow-x: auto; overflow-y: auto; padding-bottom: 16px; padding-left: 16px; padding-right: 16px; padding-top: 16px; white-space: pre; word-break: normal; word-wrap: normal; }'  >> "${TARGET_FILE}"
  echo 'blockquote { border-left-color: rgb(245, 242, 240); border-left-style: solid; border-left-width: 4px; box-sizing: border-box; color: rgb(106, 115, 125); display: block; margin-bottom: 16px; margin-left: 0px; margin-right: 0px; margin-top: 0px; padding-bottom: 0px; padding-left: 16px; padding-right: 16px; padding-top: 0px; word-wrap: break-word; }' >> "${TARGET_FILE}"
  echo 'ul { padding-left: 1.3em; }'  >> "${TARGET_FILE}"
  echo '</style>' >> "${TARGET_FILE}"
  echo '<title>Detox Instruments Help</title></head><body>' >> "${TARGET_FILE}"

  CONTENTS=$(printf '%s' "$(<$SOURCE_FILE)" | php -r 'echo json_encode(file_get_contents("php://stdin"));')
  API_JSON=$(printf '{"text": %s}' "$CONTENTS")
  curl -s --data "$API_JSON" "https://api.github.com/markdown?access_token=${GITHUB_RELEASES_TOKEN}" >> "${TARGET_FILE}"

  echo '</body></html>' >> "${TARGET_FILE}"

  #remove "aria" attributes; sed doesn't support non-greedy lookup
  sed -E -i '' -e 's/\ ?aria-hidden=\"true\"//g' "${TARGET_FILE}"
  sed -E -i '' -e 's/\ ?aria-hidden=\"false\"//g' "${TARGET_FILE}"
  sed -E -i '' -e 's/\ rel=\"noopener noreferrer\"//g' "${TARGET_FILE}"
  #broken image tags
  sed -E -i '' -e 's/\<img(.*)>\<\/a\>/\<img\1 \/\>\<\/a\>/g' "${TARGET_FILE}"
  #anchor names
  sed -E -i '' -e 's/\<a id/\<a name/g' "${TARGET_FILE}"
  #add image to top h1
  if [ $SOURCE_FILE = "README.md" ]; then
    sed -E -i '' -e 's/\<h1\>/\<h1\>\<img src\=\"Documentation\/Resources\/icon_512x512\@2x\.png\" \alt\=\"Detox Instruments\" title\=\"Detox Instruments\" style\=\"max\-width\:120px\; padding\-bottom\:10px\" \/\>\<br \/\>/' "${TARGET_FILE}"
  fi

  sed -i '' 's/\.md/\.html/' "${TARGET_FILE}"
}

echo -e "\033[1;34mRendering README.html\033[0m"
render_markdown "README.md" "$HTMLDIR"/README.html Documentation/Metadata

for MD_FILE in Documentation/*.md; do
  NAME=$(basename "$MD_FILE" .md)
  echo -e "\033[1;34mRendering $NAME.html\033[0m"
  render_markdown "$MD_FILE" "$HTMLDIR"/Documentation/"$NAME".html Documentation/Metadata
done

echo -e "\033[1;34mRebuilding Apple Help index\033[0m"
hiutil -C --anchors -g -vvv -f DetoxInstruments/DetoxInstruments.help/Contents/Resources/English.lproj/Search.helpindex DetoxInstruments/DetoxInstruments.help -v
hiutil -F -A -vvv -f DetoxInstruments/DetoxInstruments.help/Contents/Resources/English.lproj/Search.helpindex