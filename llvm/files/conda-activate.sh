#!/bin/bash

set -e

install_dir=$(bash -c "cd -- $(dirname -- "${BASH_SOURCE[0]}") &>/dev/null && pwd")
cp -r "$install_dir/bin"/. "$PREFIX"/bin
find "$PREFIX"/bin -type f -exec chmod +x {} \;
cp -r "$install_dir/libexec"/. "$PREFIX"/libexec
find "$PREFIX"/libexec -type f -exec chmod +x {} \;

# soft link the rest
current_dir=$(pwd)
cd "$install_dir/lib"
find . -type d -exec mkdir -p "$PREFIX/lib/{}" \;
find . -type f -exec ln -s "$install_dir/lib/{}" "$PREFIX/lib/{}" \;
cd "$install_dir/include"
find . -type d -exec mkdir -p "$PREFIX/include/{}" \;
find . -type f -exec ln -s "$install_dir/include/{}" "$PREFIX/include/{}" \;
cd "$install_dir/share"
find . -type d -exec mkdir -p "$PREFIX/share/{}" \;
find . -type f -exec ln -s "$install_dir/share/{}" "$PREFIX/share/{}" \;

cd "$current_dir"

extra_flags="--sysroot=$CONDA_BUILD_SYSROOT"
echo "$extra_flags" >"$BUILD_PREFIX/bin/$CONDA_TOOLCHAIN_HOST-clang++.cfg"
echo "$extra_flags" >"$BUILD_PREFIX/bin/$CONDA_TOOLCHAIN_HOST-clang-cpp.cfg"
echo "$extra_flags" >"$BUILD_PREFIX/bin/$CONDA_TOOLCHAIN_HOST-clang.cfg"
