#!/bin/bash

# get into the right folder
cd "$(dirname "$0")"
cd ../../..

tag=$(git tag --sort v:refname | tail -n 1)
release=hydraquill_bin_$tag

mkdir -p "$release/lib/hydraquill/macos"
mv bin/hydraquill.a $release/lib/hydraquill/macos/hydraquill_macos.a
mv bin/libhydraquill.dylib $release/lib/hydraquill/macos/libhydraquill_macos.dylib
