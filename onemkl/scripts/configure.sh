#!/bin/bash

set -e

cd "$PROJECT_ROOT" || exit
cd onemkl || exit
mkdir -p build
cd build || exit

rm -f CMakeCache.txt

cmake .. -G Ninja \
  -DCMAKE_CXX_COMPILER="$CXX_COMPILER" \
  -DCMAKE_C_COMPILER="$C_COMPILER" \
  -DENABLE_MKLCPU_BACKEND=True \
  -DENABLE_MKLGPU_BACKEND=True \
  -DENABLE_CUBLAS_BACKEND=True \
  -DENABLE_CUSOLVER_BACKEND=True \
  -DBUILD_FUNCTIONAL_TESTS=False \
  -DBUILD_EXAMPLES=False \
  -DTARGET_DOMAINS="blas lapack" \
  -DCMAKE_CXX_FLAGS="$CXXFLAGS" \
  -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX"
