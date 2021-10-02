#!/bin/bash

# get into the right folder
cd "$(dirname "$0")" || exit
cd ../..

cp hydraquill_bin_*/lib/hydraquill/macos/lib"$1".dylib bin/libhydraquill.dylib
