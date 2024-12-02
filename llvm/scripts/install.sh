#!/bin/bash

set -e

cd "$SUBPROJECT_ROOT"
python llvm/buildbot/compile.py -j8 -o "$LLVM_SYCL_BUILD_DIR"
cmake --build "$LLVM_SYCL_BUILD_DIR" -- -j8
cmake --build "$LLVM_SYCL_BUILD_DIR" --target install -- -j8

mkdir -p "$INSTALL_PREFIX"
cp -r "$SUBPROJECT_ROOT"/files/* "$INSTALL_PREFIX"
cp -r "$LLVM_SYCL_BUILD_DIR/install" "$INSTALL_PREFIX"

if [ -z "$NO_PATCHELF" ]; then
  NO_PATCHELF=0
fi

if [ "$NO_PATCHELF" != "1" ]; then
  bash "$SUBPROJECT_ROOT/scripts/patch_installed_rpaths.sh"
fi
