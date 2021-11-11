# Hydraquill
Hydraquill is a simple helper library preparing a selection of Noto fonts for
use with a library like Freetype. Our list only contains the regular-weight
variable-width sans-serif fonts, which results in 74MiB of raw data for
full unicode coverage.

The whole package however shrinks down to only 16MiB when compressed with zstd,
which is why an archive in this format will be prepared when building examples
(the library includes a zstd decoder and is able to unpack it at runtime).

The library also provides a way to confirm the existence of unpacked font files
and to verify their integrity using sha256 checksums.

## Dependencies
The following dependencies must be provided through callbacks:
 - zstd decoding
 - sha256 hashing

The example program includes them directly, using:
 - the single-file zstd decoder from the official zstd repo,
   found in `res/zstd/files/build/single_file_libs/zstddeclib.c`
 - the cifra sha256 implementation,
   found in `res/cifra/src`

## Cloning
As hinted above, this repo uses submodules, and should be cloned like this:
```
git clone --recurse-submodules https://github.com/nullgemm/hydraquill.git
```

If you already cloned it and don't have the submodules, run this:
```
git submodule sync
git submodule update --init --recursive --remote
```

## Compiling
Build releases using the scripts in `make/lib/release`,
or generate makefiles manually using those in `make/lib/gen`.
The latter can be automated by supplying the configuration options as arguments.
To build examples generate the makefiles with the scripts in `make/example/gen`.

## Testing
Generate makefiles for the example code using the scripts in `make/example/gen`.
They are similar to the other makefile generation scripts, and can be automated.
Build and run the examples like this (you must have built a hydraquill release):
```
make -f makefile_example_linux
make -f makefile_example_linux run
```
(some underlying scripts depend on bsdtar)

## Generating the font archive
The font pack is automatically generated when running the example code.
Please use this approach instead of manually running the necessary scripts:
it is the best way to make sure the fonts were downloaded and packed correctly.
If the example program did not print any error message, you can safely use the
`noto.bin.zst` pack found in your `bin` folder (the original is in `res/noto`).

## Emoji font
We do not use the Noto Emoji: instead, we bundle a TTF version of Twitter's
"Twemoji" set, converted from SVG by some amazing people at Mozilla.
Unlike the widespread OTF rendition, which only embeds the original SVG files,
Mozilla's TTF makes use of the COLR tables to provide real font outlines with
color information, and is thus Freetype-compatible.

## Distributing the font archive
Please make sure to distribute the required license files with the font pack.
They are found in `res/noto/licenses` (one is for Noto, the other for Twemoji).
