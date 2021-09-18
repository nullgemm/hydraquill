#!/bin/bash

# get into the right folder
cd "$(dirname "$0")"
cd ../../..

./make/lib/gen/gen_windows_msvc.sh release
make -f makefile_lib_windows_native clean
make -f makefile_lib_windows_native
