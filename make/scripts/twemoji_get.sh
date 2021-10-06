#!/bin/bash

# get into the right folder
cd "$(dirname "$0")" || exit
cd ../..

version="13.1.0"
fedora="1.fc35"

mkdir -p res/noto/files
cd res/noto || exit

curl -L "https://kojipkgs.fedoraproject.org/packages/twitter-twemoji-fonts/$version/$fedora/noarch/twitter-twemoji-fonts-$version-$fedora.noarch.rpm" \
	-o twemoji.rpm

mkdir -p tmp
cd tmp || exit
bsdtar -xf ../twemoji.rpm
mv usr/share/fonts/twemoji/Twemoji.ttf ../files/

cd ..
rm -rf tmp
