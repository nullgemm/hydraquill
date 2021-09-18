#!/bin/bash

# get into the right folder
cd "$(dirname "$0")"
cd ../..

cp hydraquill_bin_*/lib/hydraquill/windows/$1 bin/hydraquill.dll
