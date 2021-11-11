#!/bin/bash

# get into the right folder
cd "$(dirname "$0")" || exit
cd ../..

version="0.6.0"
twemoji="13.1.0"

mkdir -p res/noto/files
mkdir -p res/noto/licenses
cd res/noto || exit

curl -L "https://github.com/mozilla/twemoji-colr/releases/download/v$version/TwemojiMozilla.ttf" \
	-o files/Twemoji.ttf

curl -L "https://github.com/twitter/twemoji/archive/refs/tags/v$twemoji.zip" \
	-o twemoji.zip

unzip twemoji.zip
mv twemoji-$twemoji twemoji
mv twemoji/LICENSE-GRAPHICS licenses/twemoji_license.txt
rm -rf twemoji
