#!/bin/bash

set -eoux -pipefile

source "$DPCPP_HOME/activation/llvm.sh"

cmake --build $DPCPP_HOME/build

cmake --build $DPCPP_HOME/build --target deploy-sycl-toolchain
cmake --build $DPCPP_HOME/build --target utils/FileCheck/install
cmake --build $DPCPP_HOME/build --target utils/count/install
cmake --build $DPCPP_HOME/build --target utils/not/install
cmake --build $DPCPP_HOME/build --target utils/lit/install
cmake --build $DPCPP_HOME/build --target utils/llvm-lit/install
cmake --build $DPCPP_HOME/build --target install-llvm-size
cmake --build $DPCPP_HOME/build --target install-llvm-cov
cmake --build $DPCPP_HOME/build --target install-llvm-profdata
cmake --build $DPCPP_HOME/build --target install-compiler-rt
cmake --build $DPCPP_HOME/build --target install

cp -rf $DPCPP_HOME/build/install/* "$INSTALL_PREFIX"
