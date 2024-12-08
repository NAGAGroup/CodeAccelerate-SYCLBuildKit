#!/bin/bash

set -e

cd "$SUBPROJECT_ROOT"
python llvm/buildbot/compile.py -o "$LLVM_SYCL_BUILD_DIR"
cmake --build "$LLVM_SYCL_BUILD_DIR"
cmake --build "$LLVM_SYCL_BUILD_DIR" --target install

if [[ "${NO_PATCHELF:-0}" != 1 ]]; then
  bash "$SUBPROJECT_ROOT/scripts/patch_installed_rpaths.sh"
fi

if [[ "${CONDA_PROD_BUILD:-0}" != 1 ]]; then
  for file in "$SUBPROJECT_ROOT/files"/*; do cp -r "$file" "$INSTALL_PREFIX"; done
  for file in "$SUBPROJECT_ROOT/files"/.*; do cp -r "$file" "$INSTALL_PREFIX"; done
fi
