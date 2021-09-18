#!/bin/bash

# get into the right folder
cd "$(dirname "$0")"
cd ../../..

tag=$(git tag --sort v:refname | tail -n 1)
release=hydraquill_bin_$tag

mkdir -p "$release/lib/hydraquill/windows"
mv bin/libhydraquill.a $release/lib/hydraquill/windows/hydraquill_windows_mingw.a
mv bin/hydraquill.dll $release/lib/hydraquill/windows/hydraquill_windows_mingw.dll
