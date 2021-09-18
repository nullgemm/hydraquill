#!/bin/bash

# get into the right folder
cd "$(dirname "$0")"
cd ../..

cd res/zstd/build/single_file_libs
./create_single_file_decoder.sh
