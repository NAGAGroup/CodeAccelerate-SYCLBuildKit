#!/bin/bash

set -e

export CPATH="$GCC_INSTALL_DIR/include/c++:$GCC_INSTALL_DIR/include/c++/$CONDA_TOOLCHAIN_HOST:$PREFIX/include:$CONDA_CUDA_ROOT/include:$CONDA_BUILD_SYSROOT/usr/include"
export LD_LIBRARY_PATH="$LLVM_SYCL_BUILD_DIR/lib:$PREFIX/lib:$LD_LIBRARY_PATH"
python llvm/buildbot/check.py -o "$LLVM_SYCL_BUILD_DIR"
