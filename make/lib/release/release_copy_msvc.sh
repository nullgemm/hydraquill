#!/bin/bash

# get into the right folder
cd "$(dirname "$0")"
cd ../../..

tag=$(git tag --sort v:refname | tail -n 1)
release=hydraquill_bin_$tag

mkdir -p "$release/lib/hydraquill/windows"
mv bin/hydraquill.lib $release/lib/hydraquill/windows/hydraquill_windows_msvc.lib
mv bin/hydraquill.dll $release/lib/hydraquill/windows/hydraquill_windows_msvc.dll
