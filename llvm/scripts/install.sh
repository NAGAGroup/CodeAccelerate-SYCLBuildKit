#!/bin/bash

set -e

cd "$SUBPROJECT_ROOT"
python llvm/buildbot/compile.py -o "$LLVM_SYCL_BUILD_DIR"
cmake --build "$LLVM_SYCL_BUILD_DIR"
cmake --build "$LLVM_SYCL_BUILD_DIR" --target install

rm -rf "$INSTALL_PREFIX"
mkdir -p "$INSTALL_PREFIX"
cp -r "$SUBPROJECT_ROOT"/files/* "$INSTALL_PREFIX"
cp -r "$LLVM_SYCL_BUILD_DIR"/lib "$INSTALL_PREFIX"
cp -r "$LLVM_SYCL_BUILD_DIR"/include "$INSTALL_PREFIX"
cp -r "$LLVM_SYCL_BUILD_DIR"/bin "$INSTALL_PREFIX"
cp -r "$LLVM_SYCL_BUILD_DIR"/share "$INSTALL_PREFIX"
cp -r "$LLVM_SYCL_BUILD_DIR"/libexec "$INSTALL_PREFIX"

# merge "$LLVM_SYCL_BUILD_DIR"/install with "$INSTALL_PREFIX"
# including files prefixed with .
cp -r "$LLVM_SYCL_BUILD_DIR"/install/. "$INSTALL_PREFIX"

if [[ "${NO_PATCHELF:-0}" != 1 ]]; then
  bash "$SUBPROJECT_ROOT/scripts/patch_installed_rpaths.sh"
fi
