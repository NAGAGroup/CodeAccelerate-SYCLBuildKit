#!/bin/bash

set -e

cd "$SUBPROJECT_ROOT"
python llvm/buildbot/compile.py -o "$LLVM_SYCL_BUILD_DIR"
cmake --build "$LLVM_SYCL_BUILD_DIR"
cmake --build "$LLVM_SYCL_BUILD_DIR" --target install

mkdir -p "$INSTALL_PREFIX"
cp -r "$SUBPROJECT_ROOT"/files/* "$INSTALL_PREFIX"
find "$LLVM_SYCL_BUILD_DIR/install" -maxdepth 1 -exec cp -r {} "$INSTALL_PREFIX" ";"
find "$LLVM_SYCL_BUILD_DIR/bin" -maxdepth 1 -exec cp -r {} "$INSTALL_PREFIX/bin" ";"
find "$LLVM_SYCL_BUILD_DIR/lib" -maxdepth 1 -exec cp -r {} "$INSTALL_PREFIX/lib" ";"
find "$LLVM_SYCL_BUILD_DIR/include" -maxdepth 1 -exec cp -r {} "$INSTALL_PREFIX/include" ";"
find "$LLVM_SYCL_BUILD_DIR/share" -maxdepth 1 -exec cp -r {} "$INSTALL_PREFIX/share" ";"
find "$LLVM_SYCL_BUILD_DIR/libexec" -maxdepth 1 -exec cp -r {} "$INSTALL_PREFIX/libexec" ";"

if [ -z "$NO_PATCHELF" ]; then
  NO_PATCHELF=0
fi

if [ "$NO_PATCHELF" != "1" ]; then
  bash "$SUBPROJECT_ROOT/scripts/patch_installed_rpaths.sh"
fi
