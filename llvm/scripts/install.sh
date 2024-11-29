#!/bin/bash

set -e

cd "$LLVM_SYCL_SOURCE_DIR/build"
cmake --build . -t install -- -j6

cp -r "$SUBPROJECT_ROOT/files/"* "$INSTALL_PREFIX"

if [ -z "$NO_PATCHELF" ]; then
  NO_PATCHELF=0
fi

if [ "$NO_PATCHELF" != "1" ]; then
  bash "$SUBPROJECT_ROOT/scripts/patch_installed_rpaths.sh"
fi
