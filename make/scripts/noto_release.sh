#!/bin/bash

# get into the right folder
cd "$(dirname "$0")" || exit
cd ../..

# build the compressed font archive in the resources folder
cd res/noto || exit

cp -r licenses noto_pack
cp noto.bin.zst noto_pack/
tar -cvf noto_pack.tar noto_pack
rm -rf noto_pack
