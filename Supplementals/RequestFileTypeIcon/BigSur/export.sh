#!/bin/bash -e

CURRENTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd ../../../DetoxInstruments/DetoxInstruments/Resources/Assets.xcassets/RequestDocumentIcon.iconset
rm *.png
cp "${CURRENTDIR}"/*.png .