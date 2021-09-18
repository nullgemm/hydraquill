#!/bin/bash

# get into the right folder
cd "$(dirname "$0")"
cd ../..

# build the compressed font archive in the resources folder
cd res/noto/files

# crawl the fonts to build a file info header
for f in *; do
    size=$(wc -c < "$f")
    checksum=$(shasum -a 256 -b < "$f" | head -c 64)
    # append font files info to the blob
    printf "%s\x00" "$f" >> ../noto.bin
    printf "%08x" "$size" | xxd -r -p >> ../noto.bin
    printf "%s" "$checksum" | xxd -r -p >> ../noto.bin
    # add the fonts to a temporary blob
    cat $f >> ../noto_data.bin
    # also print those in the terminal
    printf "%-64s %8s %-64s\n" "$f" "$size" "$checksum"
done

# mark the end of the list with NUL
cd ..
printf "\x00" >> noto.bin

# combine the blobs
cat noto_data.bin >> noto.bin
rm noto_data.bin

# compress the blob
zstd --ultra -22 noto.bin
