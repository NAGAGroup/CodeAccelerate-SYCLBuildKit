#!/bin/bash

set -e

install_dir=$(bash -c "cd -- $(dirname -- "${BASH_SOURCE[0]}") &>/dev/null && pwd")
find "$install_dir" -maxdepth 1 -exec cp -r {} "$BUILD_PREFIX" ";"
export CXXFLAGS="--sysroot=$CONDA_BUILD_SYSROOT --gcc-toolchain=$PREFIX --target=$CONDA_TOOLCHAIN_HOST $CXXFLAGS"
export CFLAGS="--sysroot=$CONDA_BUILD_SYSROOT --gcc-toolchain=$PREFIX --target=$CONDA_TOOLCHAIN_HOST $CFLAGS"
echo "$CXXFLAGS" >"$BUILD_PREFIX/bin/clang++.cfg"
echo "$LDFLAGS" >>"$BUILD_PREFIX/bin/clang++.cfg"
echo "$CFLAGS" >"$BUILD_PREFIX/bin/clang.cfg"
echo "$LDFLAGS" >>"$BUILD_PREFIX/bin/clang.cfg"
