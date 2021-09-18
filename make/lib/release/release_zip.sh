#!/bin/bash

# get into the right folder
cd "$(dirname "$0")"
cd ../../..

tag=$(git tag --sort v:refname | tail -n 1)
release=hydraquill_bin_$tag

cp license.md "$release/lib/"
chmod +x $release/lib/hydraquill/macos/*.dylib
chmod +x $release/lib/hydraquill/windows/*.dll
zip -r "$release.zip" "$release"
