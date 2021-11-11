#!/bin/bash

# get into the script's folder
cd "$(dirname "$0")" || exit
cd ../../..

build=$1

# library makefile data
name="hydraquill"
makefile="makefile_lib_windows_native"
echo "getting latest Windows SDK version number from registry..."
ver_windows_sdk=$(powershell 'Get-ChildItem -Name "hklm:\SOFTWARE\Microsoft\Windows Kits\Installed Roots" | Select -Last 1')
ver_windows=$(echo "$ver_windows_sdk" | sed "s/\\..*//")
echo "searching for latest Visual Studio version number..."
ver_visual_studio=$(powershell '& "C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe" /all /latest /products Microsoft.VisualStudio.Product.BuildTools /property catalog_productLineVersion')
echo "searching for latest MSVC version number..."
ver_msvc=$(powershell 'Get-ChildItem -Name "C:\Program Files (x86)\Microsoft Visual Studio\'$ver_visual_studio'\BuildTools\VC\Tools\MSVC" | Select -Last 1')

cc="\"/c/Program Files (x86)/Microsoft Visual Studio/\
$ver_visual_studio/BuildTools/VC/Tools/MSVC/\
$ver_msvc/bin/Hostx64/x64/cl.exe\""

lib="\"/c/Program Files (x86)/Microsoft Visual Studio/\
$ver_visual_studio/BuildTools/VC/Tools/MSVC/\
$ver_msvc/bin/Hostx64/x64/lib.exe\""

src+=("src/hydraquill.c")

flags+=("-Zc:inline")
flags+=("-Isrc")
flags+=("-I\"/c/Program Files (x86)/Windows Kits/\
$ver_windows/Include/$ver_windows_sdk/ucrt\"")
flags+=("-I\"/c/Program Files (x86)/Windows Kits/\
$ver_windows/Include/$ver_windows_sdk/um\"")
flags+=("-I\"/c/Program Files (x86)/Windows Kits/\
$ver_windows/Include/$ver_windows_sdk/shared\"")
flags+=("-I\"/c/Program Files (x86)/Microsoft Visual Studio/\
$ver_visual_studio/BuildTools/VC/Tools/MSVC/$ver_msvc/include\"")

# library platform
defines+=("-D_DEFAULT_SOURCE")
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

# add the libraries as default targets
default+=("bin/$name.lib")

# makefile start
{ \
echo ".POSIX:"; \
echo "NAME = $name"; \
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

# makefile default target
echo "" >> $makefile
echo "default:" "${default[@]}" >> $makefile

# makefile library targets
echo "" >> $makefile
cat make/lib/templates/targets_windows_msvc.make >> $makefile

# makefile object targets
echo "" >> $makefile
for file in "${src[@]}"; do
	x86_64-w64-mingw32-gcc "${defines[@]}" -MM -MG "$file" >> $makefile
done

# makefile extra targets
echo "" >> $makefile
cat make/lib/templates/targets_extra.make >> $makefile
