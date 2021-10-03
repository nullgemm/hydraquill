#!/bin/bash

# get into the script's folder
cd "$(dirname "$0")" || exit
cd ../../..

build=$1
toolchain=$2
current_toolchain=$3
library=$4

tag=$(git tag --sort v:refname | tail -n 1)

makefile="makefile_example_macos"
name="hydraquill_example_macos"
hydraquill="hydraquill_macos"

# library makefile data
src+=("example/main.c")
src+=("res/cifra/src/sha256.c")
src+=("res/cifra/src/blockwise.c")
src+=("res/zstd/build/single_file_libs/zstddeclib.c")

flags+=("-std=c99" "-pedantic")
flags+=("-Wall" "-Wextra" "-Werror=vla" "-Werror")
flags+=("-Wformat")
flags+=("-Wformat-security")
flags+=("-Wno-address-of-packed-member")
flags+=("-Wno-unused-parameter")
flags+=("-Ihydraquill_bin_$tag/include")
flags+=("-Ires/cifra/src")
flags+=("-Ires/zstd/lib")
flags+=("-Iexample")

defines+=("-DHYDRAQUILL_PLATFORM_MACOS")

if [ -z "$build" ]; then
	read -rp "select build type (development | release | sanitized): " build
fi

case $build in
	development)
flags+=("-g")
	;;

	release)
flags+=("-D_FORTIFY_SOURCE=2")
flags+=("-fstack-protector-strong")
flags+=("-fPIE")
flags+=("-O2")
	;;

	sanitized)
flags+=("-g")
flags+=("-fno-omit-frame-pointer")
flags+=("-fPIE")
flags+=("-O2")
flags+=("-fsanitize=undefined")
flags+=("-fsanitize=function")
ldflags+=("-fsanitize=undefined")
ldflags+=("-fsanitize=function")
	;;

	*)
echo "invalid build type"
exit 1
	;;
esac

# toolchain type
if [ -z "$toolchain" ]; then
	read -rp "select target toolchain type (osxcross | native): " toolchain
fi

case $toolchain in
	osxcross)
cc=o64-clang
objcopy="objcopy"
	;;

	native)
makefile+="_native"
name+="_native"
hydraquill+="_native"
cc=clang
objcopy="/usr/local/Cellar/binutils/*/bin/objcopy"
	;;

	*)
echo "invalid target toolchain type"
exit 1
	;;
esac

if [ -z "$current_toolchain" ]; then
	read -rp "select current toolchain type (osxcross | native): " current_toolchain
fi

case $current_toolchain in
	osxcross)
cch=o64-clang
	;;

	native)
cch=clang
	;;

	*)
echo "invalid current toolchain type"
exit 1
	;;
esac

# link type
if [ -z "$library" ]; then
	read -rp "select library type (static | shared): " library
fi

case $library in
	static)
obj+=("hydraquill_bin_$tag/lib/hydraquill/macos/$hydraquill.a")
cmd="./$name"
	;;

	shared)
ldflags+=("-Lhydraquill_bin_$tag/lib/hydraquill/macos")
ldlibs+=("-l$hydraquill")
cmd="../make/scripts/dylib_copy.sh $hydraquill && ./$name"
	;;

	*)
echo "invalid library type"
exit 1
	;;
esac

# default target
default+=("bin/\$(NAME).app")

# valgrind flags
valgrind+=("--show-error-list=yes")
valgrind+=("--show-leak-kinds=all")
valgrind+=("--track-origins=yes")
valgrind+=("--leak-check=full")
valgrind+=("--suppressions=../res/valgrind.supp")

# makefile start
{ \
echo ".POSIX:"; \
echo "NAME = $name"; \
echo "CMD = $cmd"; \
echo "OBJCOPY = $objcopy"; \
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

# generate valgrind flags
echo "" >> $makefile
for flag in "${valgrind[@]}"; do
	echo "VALGRIND+= $flag" >> $makefile
done

# makefile default target
echo "" >> $makefile
echo "default:" "${default[@]}" >> $makefile

# makefile linux targets
echo "" >> $makefile
cat make/example/templates/targets_macos.make >> $makefile

# makefile object targets
echo "" >> $makefile
for file in "${src[@]}"; do
	$cch "${defines[@]}" -MM -MG "$file" >> $makefile
done

# makefile extra targets
echo "" >> $makefile
cat make/example/templates/targets_extra.make >> $makefile
