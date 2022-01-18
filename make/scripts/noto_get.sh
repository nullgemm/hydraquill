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

# remove Noto Color Emoji
rm files/NotoEmoji*

# remove unneeded font styles
rm files/NotoMono*
rm files/NotoSerif*
rm files/NotoSansMono*

# remove fonts with a UI variant
rm files/NotoSansDevanagari-Regular.ttf
rm files/NotoSansSinhala-Regular.ttf
rm files/NotoNaskhArabic-Regular.ttf
rm files/NotoSansMalayalam-Regular.ttf
rm files/NotoSansGujarati-Regular.ttf
rm files/NotoSansMyanmar-Regular.ttf
rm files/NotoSansArabic-Regular.ttf
rm files/NotoSansGurmukhi-Regular.ttf
rm files/NotoSansTamil-Regular.ttf
rm files/NotoSansBengali-Regular.ttf
rm files/NotoSansTelugu-Regular.ttf
rm files/NotoSansOriya-Regular.ttf
rm files/NotoSansKannada-Regular.ttf
rm files/NotoSansThai-Regular.ttf
rm files/NotoSansKhmer-Regular.ttf
rm files/NotoSansLao-Regular.ttf
