#!/bin/bash -e

CURRENTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd ../../DetoxInstruments/DetoxInstruments/dtxicon.iconset
rm *.png
cp "${CURRENTDIR}"/16.png icon_16x16.png
cp "${CURRENTDIR}"/32.png icon_16x16@2x.png
cp "${CURRENTDIR}"/32.png icon_32x32.png
cp "${CURRENTDIR}"/64.png icon_32x32@2x.png
cp "${CURRENTDIR}"/128.png icon_128x128.png
cp "${CURRENTDIR}"/256.png icon_128x128@2x.png
cp "${CURRENTDIR}"/256.png icon_256x256.png
cp "${CURRENTDIR}"/512.png icon_256x256@2x.png
cp "${CURRENTDIR}"/512.png icon_512x512.png
cp "${CURRENTDIR}"/1024.png icon_512x512@2x.png