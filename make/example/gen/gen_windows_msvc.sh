#!/bin/bash

# get into the script's folder
cd "$(dirname "$0")" || exit
cd ../../..

build=$1

tag=$(git tag --sort v:refname | tail -n 1)

# versions
echo "getting latest Windows SDK version number from registry..."
ver_windows_sdk=$(powershell 'Get-ChildItem -Name "hklm:\SOFTWARE\Microsoft\Windows Kits\Installed Roots" | Select -Last 1')
ver_windows=$(echo "$ver_windows_sdk" | sed "s/\\..*//")
echo "searching for latest Visual Studio version number..."
ver_visual_studio=$(powershell '& "C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe" /all /latest /products Microsoft.VisualStudio.Product.BuildTools /property catalog_productLineVersion')
echo "searching for latest MSVC version number..."
ver_msvc=$(powershell 'Get-ChildItem -Name "C:\Program Files (x86)\Microsoft Visual Studio\'$ver_visual_studio'\BuildTools\VC\Tools\MSVC" | Select -Last 1')

# library makefile data
makefile="makefile_example_windows"
name="hydraquill_example_windows"
hydraquill="hydraquill_windows"

cc="\"/c/Program Files (x86)/Microsoft Visual Studio/\
$ver_visual_studio/BuildTools/VC/Tools/MSVC/\
$ver_msvc/bin/Hostx64/x64/cl.exe\""

lib="\"/c/Program Files (x86)/Microsoft Visual Studio/\
$ver_visual_studio/BuildTools/VC/Tools/MSVC/\
$ver_msvc/bin/Hostx64/x64/lib.exe\""

src+=("example/main.c")
src+=("res/cifra/src/sha256.c")
src+=("res/cifra/src/blockwise.c")
src+=("res/zstd/build/single_file_libs/zstddeclib.c")

flags+=("-Zc:inline")
flags+=("-Ihydraquill_bin_$tag/include")
flags+=("-Ires/cifra/src")
flags+=("-Ires/zstd/lib")
flags+=("-Iexample")
flags+=("-I\"/c/Program Files (x86)/Windows Kits/\
$ver_windows/Include/$ver_windows_sdk/ucrt\"")
flags+=("-I\"/c/Program Files (x86)/Windows Kits/\
$ver_windows/Include/$ver_windows_sdk/um\"")
flags+=("-I\"/c/Program Files (x86)/Windows Kits/\
$ver_windows/Include/$ver_windows_sdk/shared\"")
flags+=("-I\"/c/Program Files (x86)/Microsoft Visual Studio/\
$ver_visual_studio/BuildTools/VC/Tools/MSVC/$ver_msvc/include\"")

defines+=("-DHYDRAQUILL_PLATFORM_MSVC")
defines+=("-DUNICODE")
defines+=("-D_UNICODE")
defines+=("-DWINVER=0x0A00")
defines+=("-D_WIN32_WINNT=0x0A00")
defines+=("-DCINTERFACE")
defines+=("-DCOBJMACROS")

# generated linker arguments
ldflags+=("-SUBSYSTEM:windows")
ldflags+=("-LIBPATH:\"/c/Program Files (x86)/Windows Kits/\
$ver_windows/Lib/$ver_windows_sdk/um/x64\"")
ldflags+=("-LIBPATH:\"/c/Program Files (x86)/Microsoft Visual Studio/\
$ver_visual_studio/BuildTools/VC/Tools/MSVC/$ver_msvc/lib/spectre/x64\"")
ldflags+=("-LIBPATH:\"/c/Program Files (x86)/Windows Kits/\
$ver_windows/Lib/$ver_windows_sdk/ucrt/x64\"")

drmemory+=("-report_max -1")
drmemory+=("-report_leak_max -1")
drmemory+=("-batch")

# build type
if [ -z "$build" ]; then
	read -rp "select build type (development | release): " build
fi

case $build in
	development)
flags+=("-Z7")
ldflags+=("-DEBUG:FULL")
	;;

	release)
flags+=("-O2")
	;;

	*)
echo "invalid build type"
exit 1
	;;
esac

# link hydraquill
ldflags+=("-LIBPATH:\"hydraquill_bin_$tag/lib/hydraquill/windows\"")
ldlibs+=("$hydraquill""_msvc.lib")

# default target
cmd="./$name.exe"
default+=("bin/\$(NAME)")

# makefile start
{ \
echo ".POSIX:"; \
echo "NAME = $name"; \
echo "CMD = $cmd"; \
echo "CC = $cc"; \
echo "LIB = $lib"; \
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
	echo "OBJ+= $folder/$filename.obj" >> $makefile
done

echo "" >> $makefile
for prebuilt in "${obj[@]}"; do
	echo "OBJ_EXTRA+= $prebuilt" >> $makefile
done

# generate Dr.Memory flags
echo "" >> $makefile
for flag in "${drmemory[@]}"; do
	echo "DRMEMORY+= $flag" >> $makefile
done

# makefile default target
echo "" >> $makefile
echo "default:" "${default[@]}" >> $makefile

# makefile linux targets
echo "" >> $makefile
cat make/example/templates/targets_windows_msvc.make >> $makefile

# makefile object targets
echo "" >> $makefile
for file in "${src[@]}"; do
	x86_64-w64-mingw32-gcc "${defines[@]}" -MM -MG "$file" >> $makefile
done

# makefile extra targets
echo "" >> $makefile
cat make/example/templates/targets_extra.make >> $makefile
