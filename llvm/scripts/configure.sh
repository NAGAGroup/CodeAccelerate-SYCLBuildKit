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
  rm -rf "$LLVM_SYCL_SOURCE_DIR"
  rm -rf "$intel_urt"
  git clone -b latest --depth 1 https://github.com/NAGAGroup/intel-llvm.git "$LLVM_SYCL_SOURCE_DIR"
  git clone -b https://github.com/oneapi-src/unified-runtime.git "$intel_urt"
  cd "$intel_urt"
  git reset --hard 3db3a5e2d935630f2ffddd93a72ae0aa9af89acbfi
  cd "$LLVM_SYCL_SOURCE_DIR/.."
fi

conda_extra_cflags="--sysroot=$CONDA_BUILD_SYSROOT --gcc-install-dir=$GCC_INSTALL_DIR"
clang_ldflags="-Wl,-rpath,$PREFIX/lib -Wl,-rpath-link,$PREFIX/lib -L$PREFIX/lib -Wl,-rpath,$LLVM_SYCL_BUILD_DIR/lib -Wl,-rpath-link,$LLVM_SYCL_BUILD_DIR/lib -L$LLVM_SYCL_BUILD_DIR/lib -L$CONDA_CUDA_ROOT/lib -L$CONDA_CUDA_ROOT/lib/stubs"

mkdir -p "$LLVM_SYCL_BUILD_DIR/bin"
echo "$conda_extra_cflags" >"$LLVM_SYCL_BUILD_DIR/bin/$CONDA_TOOLCHAIN_HOST-clang++.cfg"
echo "$conda_extra_cflags" >"$LLVM_SYCL_BUILD_DIR/bin/$CONDA_TOOLCHAIN_HOST-clang-cpp.cfg"
echo "$conda_extra_cflags" >"$LLVM_SYCL_BUILD_DIR/bin/$CONDA_TOOLCHAIN_HOST-clang.cfg"

echo "$clang_ldflags" >>"$LLVM_SYCL_BUILD_DIR/bin/$CONDA_TOOLCHAIN_HOST-clang++.cfg"
echo "$clang_ldflags" >>"$LLVM_SYCL_BUILD_DIR/bin/$CONDA_TOOLCHAIN_HOST-clang-cpp.cfg"
echo "$clang_ldflags" >>"$LLVM_SYCL_BUILD_DIR/bin/$CONDA_TOOLCHAIN_HOST-clang.cfg"

cd "$SUBPROJECT_ROOT"

cmake_args=(
  -DLLVM_DEFAULT_TARGET_TRIPLE="$CONDA_TOOLCHAIN_HOST"
  -DLLVM_HOST_TRIPLE="$CONDA_TOOLCHAIN_HOST"
  -DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD="SPIRV"
  -DLLVM_INSTALL_UTILS=ON
  -DNATIVECPU_USE_OCK=OFF
  -DLLVM_UTILS_INSTALL_DIR=libexec/llvm
  -DSYCL_UR_USE_FETCH_CONTENT=OFF
  -DSYCL_UR_SOURCE_DIR="$intel_urt"
  -DLLVM_LIBDIR_SUFFIX=""
  -DCMAKE_TOOLCHAIN_FILE="$PROJECT_TOOLCHAIN_FILE")

# iterate through $CMAKE_ARGS and convert to --cmake-opt format
for arg in $CMAKE_ARGS; do
  cmake_opt="--cmake-opt=$arg"
  cmake_opts="$cmake_opts $cmake_opt"
done

for arg in "${cmake_args[@]}"; do
  cmake_opt="--cmake-opt=$arg"
  cmake_opts="$cmake_opts $cmake_opt"
done

configure_cmd="python llvm/buildbot/configure.py --use-lld --cuda --native_cpu --cmake-gen=Ninja -o $LLVM_SYCL_BUILD_DIR $cmake_opts"

echo "Running: $configure_cmd"

$configure_cmd
