#!/bin/bash

# get into the right folder
cd "$(dirname "$0")" || exit
cd ../..

mkdir -p res/noto/files
mkdir -p res/noto/licenses
cd res/noto || exit
curl -L "https://noto-website-2.storage.googleapis.com/pkgs/Noto-hinted.zip" -o \
	noto_hinted.zip

mkdir -p tmp
cd tmp || exit
unzip ../noto_hinted.zip
mv ./*Regular.* ../files
mv ./LICENSE_OFL.txt ../licenses/noto_license.txt

cd ..
rm -rf tmp
rm files/NotoEmoji*
rm files/NotoMono*
rm files/NotoSerif*
rm files/NotoSansMono*
