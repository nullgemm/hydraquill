#!/bin/bash

# get into the right folder
cd "$(dirname "$0")" || exit
cd ../../..

./make/lib/gen/gen_windows_mingw.sh release
make -f makefile_lib_windows clean
make -f makefile_lib_windows
