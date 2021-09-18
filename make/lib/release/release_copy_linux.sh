#!/bin/bash

# get into the right folder
cd "$(dirname "$0")"
cd ../../..

tag=$(git tag --sort v:refname | tail -n 1)
release=hydraquill_bin_$tag

mkdir -p "$release/lib/hydraquill/linux"
mv bin/hydraquill.a $release/lib/hydraquill/linux/hydraquill_linux.a
mv bin/hydraquill.so $release/lib/hydraquill/linux/hydraquill_linux.so
