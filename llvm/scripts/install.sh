#!/bin/bash

set -e

cd "$SUBPROJECT_ROOT"
python llvm/buildbot/compile.py -o "$LLVM_SYCL_BUILD_DIR"
cmake --build "$LLVM_SYCL_BUILD_DIR"
cmake --build "$LLVM_SYCL_BUILD_DIR" --target install
cp -r "$SUBPROJECT_ROOT/files"/. "$INSTALL_PREFIX"

rm -rf "$INSTALL_PREFIX"
mkdir -p "$INSTALL_PREFIX"
cp -r "$LLVM_SYCL_BUILD_DIR"/install/. "$INSTALL_PREFIX"

if [[ "${NO_PATCHELF:-0}" != 1 ]]; then
  bash "$SUBPROJECT_ROOT/scripts/patch_installed_rpaths.sh"
fi
