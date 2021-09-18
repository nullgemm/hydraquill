# Hydraquill (WIP)
Hydraquill is a simple helper library preparing a selection of Noto fonts for
use with a library like Freetype. Our list only contains the regular-weight
variable-width sans-serif fonts, which results in 74MiB of raw data for
full unicode coverage.

The whole package however shrinks down to only 16MiB when compressed with zstd,
which is why an archive in this format will be prepared when building examples
(the library includes a zstd decoder and is able to unpack it at runtime).

The library also provides a way to confirm the existence of unpacked font files
and to verify their integrity using sha256 checksums.

# Dependencies
The following dependencies must be provided through callbacks:
 - zstd decoding
 - sha256 hashing

The example program includes them directly, using:
 - the single-file zstd decoder from the official zstd repo,
   found in `res/zstd/files/build/single_file_libs/zstddeclib.c`
 - the cifra sha256 implementation,
   found in `res/cifra/src`

# Cloning
As hinted above, this repo uses submodules, and should be cloned like this:
```
git clone --recurse-submodules https://github.com/nullgemm/hydraquill.git
```

If you already cloned it and don't have the submodules, run this:
```
git submodule sync
git submodule update --init --recursive --remote
```

# Compiling
Build releases using the scripts in `make/lib/release`,
or generate makefiles manually using those in `make/lib/gen`.
The latter can be automated by supplying the configuration options as arguments.
To build examples generate the makefiles with the scripts in `make/example/gen`.

# Known bugs
The following bugs are known and not fixed yet (feel free to open a PR):
 - the example for decompressing an archive embedded in the executable does not
   work under macOS and generates an error.
