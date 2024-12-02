#!/bin/bash

set -e

LD_LIBRARY_PATH="$LLVM_SYCL_BUILD_DIR/lib:$PREFIX/lib:$LD_LIBRARY_PATH" python llvm/buildbot/check.py -o "$LLVM_SYCL_BUILD_DIR"
