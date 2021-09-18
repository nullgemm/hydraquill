#!/bin/bash

# get into the right folder
cd "$(dirname "$0")"
cd ../..

mkdir -p res/noto/files
cd res/noto
curl -L "https://noto-website-2.storage.googleapis.com/pkgs/Noto-hinted.zip" -o \
	noto_hinted.zip

mkdir tmp
cd tmp
unzip ../noto_hinted.zip
mv *Regular.* ../files

cd ..
rm -rf tmp
rm files/NotoMono*
rm files/NotoSerif*
rm files/NotoSansMono*
