#!/bin/bash

set -e

if [[ ${CONDA_BUILD_CROSS_COMPILATION:-0} == "1" ]]; then
  echo "Cross-compilation is not supported at the moment."
  exit 1
fi

intel_urt="$SUBPROJECT_ROOT/intel-urt"
if [ -f "$LLVM_SYCL_SOURCE_DIR/llvm/CMakeLists.txt" ]; then
  mkdir -p "$LLVM_SYCL_BUILD_DIR"
  find "$LLVM_SYCL_BUILD_DIR" -name "CMakeCache.txt" -exec rm {} ";"
else
  rm -rf "$intel_urt"
  rm -rf "$LLVM_SYCL_SOURCE_DIR"
  git submodule update --init --recursive
fi

conda_extra_cflags="--gcc-install-dir=$GCC_INSTALL_DIR $CONDA_EXTRA_CFLAGS"
clang_ldflags="$LDFLAGS -Wl,-rpath,$LLVM_SYCL_BUILD_DIR/lib -Wl,-rpath-link,$LLVM_SYCL_BUILD_DIR/lib -L $LLVM_SYCL_BUILD_DIR/lib"

mkdir -p "$LLVM_SYCL_BUILD_DIR/bin"
echo "$conda_extra_cflags" >"$LLVM_SYCL_BUILD_DIR/bin/clang++.cfg"
echo "$conda_extra_cflags" >"$LLVM_SYCL_BUILD_DIR/bin/clang-cpp.cfg"
echo "$conda_extra_cflags" >"$LLVM_SYCL_BUILD_DIR/bin/clang.cfg"

echo "$clang_ldflags" >>"$LLVM_SYCL_BUILD_DIR/bin/clang++.cfg"
echo "$clang_ldflags" >>"$LLVM_SYCL_BUILD_DIR/bin/clang-cpp.cfg"
echo "$clang_ldflags" >>"$LLVM_SYCL_BUILD_DIR/bin/clang.cfg"

cd "$SUBPROJECT_ROOT"

cmake_args=(
  -DLLVM_UTILS_INSTALL_DIR=libexec
  -DSYCL_UR_USE_FETCH_CONTENT=OFF
  -DSYCL_UR_SOURCE_DIR="$intel_urt"
  -DLLVM_LIBDIR_SUFFIX=""
  -DCMAKE_TOOLCHAIN_FILE="$PROJECT_TOOLCHAIN_FILE")

# iterate through $CMAKE_ARGS and convert to --cmake-opt format
for arg in "${cmake_args[@]}"; do
  cmake_opt="--cmake-opt=$arg"
  cmake_opts="$cmake_opts $cmake_opt"
done

configure_cmd="python llvm/buildbot/configure.py --use-lld --cuda --native_cpu --cmake-gen=Ninja -o $LLVM_SYCL_BUILD_DIR $cmake_opts"

echo "Running: $configure_cmd"

$configure_cmd
