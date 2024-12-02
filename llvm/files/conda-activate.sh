#!/bin/bash

set -e

install_dir=$(bash -c "cd -- $(dirname -- "${BASH_SOURCE[0]}") &>/dev/null && pwd")
find "$install_dir" -maxdepth 1 -exec cp -r {} "$BUILD_PREFIX" ";"

gcc_version=$(gcc -dumpversion)
gcc_install_dir="$PREFIX/lib/gcc/$CONDA_TOOLCHAIN_HOST/$gcc_version"
extra_flags="--sysroot=$CONDA_BUILD_SYSROOT --gcc-install-dir=$gcc_install_dir --target=$CONDA_TOOLCHAIN_HOST -I$CONDA_BUILD_SYSROOT/usr/include"
ldflags="-L $CONDA_BUILD_SYSROOT/usr/lib"
echo "$extra_flags" >"$BUILD_PREFIX/bin/clang++.cfg"
echo "$extra_flags" >"$BUILD_PREFIX/bin/clang-cpp.cfg"
echo "$extra_flags" >"$BUILD_PREFIX/bin/clang.cfg"

echo "$ldflags" >>"$BUILD_PREFIX/bin/clang++.cfg"
echo "$ldflags" >>"$BUILD_PREFIX/bin/clang-cpp.cfg"
echo "$ldflags" >>"$BUILD_PREFIX/bin/clang.cfg"
