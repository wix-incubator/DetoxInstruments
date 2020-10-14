#!/bin/bash -e

CURRENTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd ../../../DetoxInstruments/DetoxInstruments/Resources/Assets.xcassets/RecordingDocumentIcon.iconset
rm *.png
cp "${CURRENTDIR}"/*.png .