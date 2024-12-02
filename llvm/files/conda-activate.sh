#!/bin/bash

set -e

install_dir=$(bash -c "cd -- $(dirname -- "${BASH_SOURCE[0]}") &>/dev/null && pwd")
find "$install_dir" -maxdepth 1 -exec cp -r {} "$BUILD_PREFIX" ";"

extra_flags="--sysroot=$CONDA_BUILD_SYSROOT --gcc-toolchain=$PREFIX --target=$CONDA_TOOLCHAIN_HOST -I$CONDA_BUILD_SYSROOT/usr/include"
echo "$extra_flags" >"$BUILD_PREFIX/bin/clang++.cfg"
echo "$extra_flags" >"$BUILD_PREFIX/bin/clang-cpp.cfg"
echo "$extra_flags" >"$BUILD_PREFIX/bin/clang.cfg"
