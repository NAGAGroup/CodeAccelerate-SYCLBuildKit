#!/bin/bash

export LD_LIBRARY_PATH="$LLVM_SYCL_BUILD_DIR/lib:$PREFIX/lib:$LD_LIBRARY_PATH"
cmake --build "$LLVM_SYCL_BUILD_DIR" -t check-all
