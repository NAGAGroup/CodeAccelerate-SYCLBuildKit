#!/bin/bash

set -eoux -pipefile

if [[ ${CONDA_BUILD_CROSS_COMPILATION:-0} == "1" ]]; then
  echo "Cross-compilation is not supported at the moment."
  exit 1
fi

if [ -z "$PROJECT_ROOT" ]; then
  source "$DPCPP_HOME/activation/llvm.sh"
fi

conda_extra_cflags="--sysroot=$CONDA_BUILD_SYSROOT --gcc-install-dir=$GCC_INSTALL_DIR"
clang_ldflags="-Wl,-rpath,$PREFIX/lib -Wl,-rpath-link,$PREFIX/lib -L$PREFIX/lib -Wl,-rpath,$DPCPP_HOME/build/lib -Wl,-rpath-link,$DPCPP_HOME/build/lib -L$DPCPP_HOME/build/lib -L$CONDA_CUDA_ROOT/lib -L$CONDA_CUDA_ROOT/lib/stubs"

mkdir -p "$DPCPP_HOME/build/bin"
rm -f "$DPCPP_HOME/build/CMakeCache.txt"
cd "$DPCPP_HOME/build"

echo "$conda_extra_cflags" >"$DPCPP_HOME/build/bin/$CONDA_TOOLCHAIN_HOST-clang++.cfg"
echo "$conda_extra_cflags" >"$DPCPP_HOME/build/bin/$CONDA_TOOLCHAIN_HOST-clang-cpp.cfg"
echo "$conda_extra_cflags" >"$DPCPP_HOME/build/bin/$CONDA_TOOLCHAIN_HOST-clang.cfg"

echo "$clang_ldflags" >>"$DPCPP_HOME/build/bin/$CONDA_TOOLCHAIN_HOST-clang++.cfg"
echo "$clang_ldflags" >>"$DPCPP_HOME/build/bin/$CONDA_TOOLCHAIN_HOST-clang-cpp.cfg"
echo "$clang_ldflags" >>"$DPCPP_HOME/build/bin/$CONDA_TOOLCHAIN_HOST-clang.cfg"

cmake_args=(
  -DCMAKE_INSTALL_PREFIX="$DPCPP_HOME/build/install"
  -DCMAKE_C_COMPILER_LAUNCHER=ccache
  -DCMAKE_CXX_COMPILER_LAUNCHER=ccache
  -DLLVM_DEFAULT_TARGET_TRIPLE="$CONDA_TOOLCHAIN_HOST"
  -DLLVM_HOST_TRIPLE="$CONDA_TOOLCHAIN_HOST"
  -DLLVM_INSTALL_UTILS=ON
  -DLLVM_UTILS_INSTALL_DIR=libexec/llvm
  -DLLVM_LIBDIR_SUFFIX=""
  -DCMAKE_TOOLCHAIN_FILE="$PROJECT_TOOLCHAIN_FILE")

# iterate through $CMAKE_ARGS and convert to --cmake-opt format
for arg in "${cmake_args[@]}"; do
  cmake_opt="--cmake-opt=$arg"
  cmake_opts="$cmake_opts $cmake_opt"
done

configure_cmd="python $DPCPP_HOME/repo/buildbot/configure.py -w $DPCPP_HOME -s $DPCPP_HOME/repo -o $DPCPP_HOME/build 
    --enable-all-llvm-targets 
    --shared-libs 
    --llvm-external-projects=clang-tools-extra 
    --use-lld 
    --cuda 
    --native_cpu 
    --cmake-gen=Ninja -o $DPCPP_HOME/build $cmake_opts"

echo "Running: $configure_cmd"

$configure_cmd
