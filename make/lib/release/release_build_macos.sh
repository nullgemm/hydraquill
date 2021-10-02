#!/bin/bash

# get into the right folder
cd "$(dirname "$0")" || exit
cd ../../..

./make/lib/gen/gen_macos.sh release native native
make -f makefile_lib_macos_native clean
make -f makefile_lib_macos_native
