#!/bin/bash

# get into the script's folder
cd "$(dirname "$0")" || exit
cd ../../..

build=$1
library=$2

tag=$(git tag --sort v:refname | tail -n 1)

# library makefile data
makefile="makefile_example_windows"
name="hydraquill_example_windows"
hydraquill="hydraquill_windows"
cc="x86_64-w64-mingw32-gcc"

src+=("example/main.c")
src+=("res/cifra/src/sha256.c")
src+=("res/cifra/src/blockwise.c")
src+=("res/zstd/build/single_file_libs/zstddeclib.c")

flags+=("-std=c99" "-pedantic")
flags+=("-Wall" "-Wextra" "-Werror=vla" "-Werror")
flags+=("-Wno-address-of-packed-member")
flags+=("-Wno-unused-parameter")
flags+=("-Wno-implicit-fallthrough")
flags+=("-Wno-cast-function-type")
flags+=("-Wno-incompatible-pointer-types")
flags+=("-Ihydraquill_bin_$tag/include")
flags+=("-Ires/cifra/src")
flags+=("-Ires/zstd/lib")
flags+=("-Iexample")

defines+=("-DHYDRAQUILL_PLATFORM_MINGW")
defines+=("-DUNICODE")
defines+=("-D_UNICODE")
defines+=("-DWINVER=0x0A00")
defines+=("-D_WIN32_WINNT=0x0A00")
defines+=("-DCINTERFACE")
defines+=("-DCOBJMACROS")

# build type
if [ -z "$build" ]; then
	read -rp "select build type (development | release): " build
fi

case $build in
	development)
flags+=("-fPIC")
flags+=("-g")
	;;

	release)
flags+=("-D_FORTIFY_SOURCE=2")
flags+=("-fPIE")
flags+=("-fPIC")
flags+=("-O2")
	;;

	*)
echo "invalid build type"
exit 1
	;;
esac

# link type
if [ -z "$library" ]; then
	read -rp "select library type (static | shared): " library
fi

case $library in
	static)
obj+=("hydraquill_bin_$tag/lib/hydraquill/windows/""$hydraquill""_mingw.a")
cmd="wine ./$name.exe"
	;;

	shared)
obj+=("hydraquill_bin_$tag/lib/hydraquill/windows/""$hydraquill""_mingw.dll.a")
cmd="../make/scripts/dll_copy.sh ""$hydraquill""_mingw.dll && wine ./$name.exe"
	;;

	*)
echo "invalid library type"
exit 1
	;;
esac

# default target
default+=("bin/\$(NAME)")

# makefile start
{ \
echo ".POSIX:"; \
echo "NAME = $name"; \
echo "CMD = $cmd"; \
echo "CC = $cc"; \
} > $makefile

# makefile linking info
echo "" >> $makefile
for flag in "${ldflags[@]}"; do
	echo "LDFLAGS+= $flag" >> $makefile
done

echo "" >> $makefile
for flag in "${ldlibs[@]}"; do
	echo "LDLIBS+= $flag" >> $makefile
done

# makefile compiler flags
echo "" >> $makefile
for flag in "${flags[@]}"; do
	echo "CFLAGS+= $flag" >> $makefile
done

echo "" >> $makefile
for define in "${defines[@]}"; do
	echo "CFLAGS+= $define" >> $makefile
done

# makefile object list
echo "" >> $makefile
for file in "${src[@]}"; do
	folder=$(dirname "$file")
	filename=$(basename "$file" .c)
	echo "OBJ+= $folder/$filename.o" >> $makefile
done

echo "" >> $makefile
for prebuilt in "${obj[@]}"; do
	echo "OBJ_EXTRA+= $prebuilt" >> $makefile
done

# makefile default target
echo "" >> $makefile
echo "default:" "${default[@]}" >> $makefile

# makefile linux targets
echo "" >> $makefile
cat make/example/templates/targets_windows_mingw.make >> $makefile

# makefile object targets
echo "" >> $makefile
for file in "${src[@]}"; do
	$cc "${defines[@]}" -MM -MG "$file" >> $makefile
done

# makefile extra targets
echo "" >> $makefile
cat make/example/templates/targets_extra.make >> $makefile
