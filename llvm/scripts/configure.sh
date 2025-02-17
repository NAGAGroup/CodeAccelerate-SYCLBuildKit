#!/bin/bash

set -e

if [[ ${CONDA_BUILD_CROSS_COMPILATION:-0} == "1" ]]; then
  echo "Cross-compilation is not supported at the moment."
  exit 1
fi

if [ -f "$DPCPP_HOME/repo/CMakeLists.txt" ]; then
  mkdir -p "$DPCPP_BIN_DIR"
  find "$DPCPP_BIN_DIR" -name "CMakeCache.txt" -exec rm {} ";"
else
  rm -rf "$DPCPP_HOME"
  git submodule update --init --recursive --depth=1
fi

conda_extra_cflags="--sysroot=$CONDA_BUILD_SYSROOT --gcc-install-dir=$GCC_INSTALL_DIR"
clang_ldflags="-Wl,-rpath,$PREFIX/lib -Wl,-rpath-link,$PREFIX/lib -L$PREFIX/lib -Wl,-rpath,$DPCPP_BIN_DIR/lib -Wl,-rpath-link,$DPCPP_BIN_DIR/lib -L$DPCPP_BIN_DIR/lib -L$CONDA_CUDA_ROOT/lib -L$CONDA_CUDA_ROOT/lib/stubs"

mkdir -p "$DPCPP_BIN_DIR/bin"
echo "$conda_extra_cflags" >"$DPCPP_BIN_DIR/bin/$CONDA_TOOLCHAIN_HOST-clang++.cfg"
echo "$conda_extra_cflags" >"$DPCPP_BIN_DIR/bin/$CONDA_TOOLCHAIN_HOST-clang-cpp.cfg"
echo "$conda_extra_cflags" >"$DPCPP_BIN_DIR/bin/$CONDA_TOOLCHAIN_HOST-clang.cfg"

echo "$clang_ldflags" >>"$DPCPP_BIN_DIR/bin/$CONDA_TOOLCHAIN_HOST-clang++.cfg"
echo "$clang_ldflags" >>"$DPCPP_BIN_DIR/bin/$CONDA_TOOLCHAIN_HOST-clang-cpp.cfg"
echo "$clang_ldflags" >>"$DPCPP_BIN_DIR/bin/$CONDA_TOOLCHAIN_HOST-clang.cfg"

cd "$SUBPROJECT_ROOT"

cmake_args=(
  -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX"
  -DCMAKE_C_COMPILER_LAUNCHER=ccache
  -DCMAKE_CXX_COMPILER_LAUNCHER=ccache
  -DLLVM_DEFAULT_TARGET_TRIPLE="$CONDA_TOOLCHAIN_HOST"
  -DLLVM_HOST_TRIPLE="$CONDA_TOOLCHAIN_HOST"
  -DLLVM_INSTALL_UTILS=ON
  -DLLVM_UTILS_INSTALL_DIR=libexec/llvm
  -DSYCL_UR_USE_FETCH_CONTENT=OFF
  -DSYCL_UR_SOURCE_DIR="$intel_urt"
  -DLLVM_LIBDIR_SUFFIX=""
  -DCMAKE_TOOLCHAIN_FILE="$PROJECT_TOOLCHAIN_FILE")

# iterate through $CMAKE_ARGS and convert to --cmake-opt format
for arg in "${cmake_args[@]}"; do
  cmake_opt="--cmake-opt=$arg"
  cmake_opts="$cmake_opts $cmake_opt"
done

configure_cmd="python llvm/buildbot/configure.py 
    --enable-all-llvm-targets 
    --shared-libs 
    --llvm-external-projects=clang-tools-extra 
    --use-lld 
    --cuda 
    --native_cpu 
    --cmake-gen=Ninja -o $DPCPP_BIN_DIR $cmake_opts"

echo "Running: $configure_cmd"

$configure_cmd
