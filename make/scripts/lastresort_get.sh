#!/bin/bash

# get into the right folder
cd "$(dirname "$0")" || exit
cd ../..

version="13.001"

mkdir -p res/noto/files
mkdir -p res/noto/licenses
cd res/noto/files || exit

curl -L "https://github.com/unicode-org/last-resort-font/releases/download/$version/LastResortHE-Regular.ttf" \
	-o LastResortHE-Regular.ttf

cd ../licenses

curl -L "https://raw.githubusercontent.com/unicode-org/last-resort-font/main/LICENSE.md" \
	-o lastresort_license.txt
