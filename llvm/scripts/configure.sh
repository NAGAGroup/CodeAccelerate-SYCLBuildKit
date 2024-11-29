#!/bin/bash

set -e

intel_urt="$SUBPROJECT_ROOT/intel-urt"
if [ -f "$LLVM_SYCL_SOURCE_DIR/llvm/CMakeLists.txt" ]; then
  find "$LLVM_SYCL_SOURCE_DIR" -name "CMakeCache.txt" -exec rm {} ";"
else
  rm -rf "$intel_urt"
  rm -rf "$LLVM_SYCL_SOURCE_DIR"
  git submodule update --init --recursive
  cp "$SUBPROJECT_ROOT/injected-files/urt-cuda.cmake" "$intel_urt/source/adapters/cuda/CMakeLists.txt"
fi

mkdir -p "$LLVM_SYCL_SOURCE_DIR/build/bin"
mkdir -p "$LLVM_SYCL_SOURCE_DIR/build/NATIVE/bin"
clangxx_flags="--sysroot=$CONDA_BUILD_SYSROOT --gcc-toolchain=$BUILD_PREFIX --target=$CONDA_TOOLCHAIN_HOST $CXXFLAGS"
clang_flags="--sysroot=$CONDA_BUILD_SYSROOT --gcc-toolchain=$BUILD_PREFIX --target=$CONDA_TOOLCHAIN_HOST $CFLAGS"
echo "$clangxx_flags" >"$LLVM_SYCL_SOURCE_DIR/build/NATIVE/bin/clang++.cfg"
echo "$LDFLAGS" >>"$LLVM_SYCL_SOURCE_DIR/build/NATIVE/bin/clang++.cfg"
echo "$clang_flags" >"$LLVM_SYCL_SOURCE_DIR/build/NATIVE/bin/clang.cfg"
echo "$LDFLAGS" >>"$LLVM_SYCL_SOURCE_DIR/build/NATIVE/bin/clang.cfg"
echo "$clangxx_flags" >"$LLVM_SYCL_SOURCE_DIR/build/bin/clang++.cfg"
echo "$LDFLAGS" >>"$LLVM_SYCL_SOURCE_DIR/build/bin/clang++.cfg"
echo "$clang_flags" >"$LLVM_SYCL_SOURCE_DIR/build/bin/clang.cfg"
echo "$LDFLAGS" >>"$LLVM_SYCL_SOURCE_DIR/build/bin/clang.cfg"

cmake_cmd="cmake -G Ninja ../llvm $CMAKE_ARGS \
  -DCMAKE_TOOLCHAIN_FILE='$PROJECT_ROOT/toolchains/linux.cmake' \
  -DLLVM_HOST_TRIPLE='$CONDA_TOOLCHAIN_HOST' \
  -DSYCL_UR_USE_FETCH_CONTENT=OFF \
  -DSYCL_UR_SOURCE_DIR='$intel_urt' \
  -DLLVM_LIBDIR_SUFFIX='' \
  -DLLVM_ENABLE_BACKTRACES=ON \
  -DLLVM_ENABLE_DUMP=ON \
  -DLLVM_ENABLE_LIBEDIT=OFF \
  -DLLVM_ENABLE_LIBXML2=FORCE_ON \
  -DLLVM_ENABLE_RTTI=ON \
  -DLLVM_ENABLE_ZLIB=FORCE_ON \
  -DLLVM_ENABLE_ZSTD=FORCE_ON \
  -DLLVM_USE_STATIC_ZSTD=FORCE_ON \
  -DLLVM_INCLUDE_UTILS=ON \
  -DLLVM_INSTALL_UTILS=ON \
  -DLLVM_ENABLE_ASSERTIONS=ON \
  -DLLVM_TARGETS_TO_BUILD='X86;NVPTX' \
  -DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD='SPIRV' \
  -DLLVM_EXTERNAL_PROJECTS='sycl;llvm-spirv;opencl;xpti;xptifw;libdevice;sycl-jit' \
  -DLLVM_EXTERNAL_OPENCL_SOURCE_DIR='$LLVM_SYCL_SOURCE_DIR/clang' \
  -DLLVM_EXTERNAL_SYCL_SOURCE_DIR='$LLVM_SYCL_SOURCE_DIR/sycl' \
  -DLLVM_EXTERNAL_LLVM_SPIRV_SOURCE_DIR='$LLVM_SYCL_SOURCE_DIR/llvm-spirv' \
  -DLLVM_EXTERNAL_OPENCL_SOURCE_DIR='$LLVM_SYCL_SOURCE_DIR/opencl' \
  -DLLVM_EXTERNAL_XPTI_SOURCE_DIR='$LLVM_SYCL_SOURCE_DIR/xpti' \
  -DXPTI_SOURCE_DIR='$LLVM_SYCL_SOURCE_DIR/xpti' \
  -DLLVM_ENABLE_PROJECTS='clang;clang-tools-extra;libclc;lld;sycl;llvm-spirv;opencl;xpti;xptifw;libdevice;sycl-jit;compiler-rt;openmp' \
  -DSYCL_BUILD_PI_HIP_PLATFORM='' \
  -DLLVM_BUILD_TOOLS=ON \
  -DSYCL_ENABLE_WERROR=OFF \
  -DCMAKE_INSTALL_PREFIX='$INSTALL_PREFIX' \
  -DSYCL_INCLUDE_TESTS=ON \
  -DLLVM_ENABLE_DOXYGEN=OFF \
  -DLLVM_ENABLE_SPHINX=FALSE \
  -DBUILD_SHARED_LIBS=OFF \
  -DSYCL_ENABLE_XPTI_TRACING=ON \
  -DLLVM_ENABLE_LLD=ON \
  -DXPTI_ENABLE_WERROR=OFF \
  -DSYCL_CLANG_EXTRA_FLAGS='$clangxx_flags' \
  -DSYCL_ENABLE_BACKENDS='opencl;native_cpu;level_zero;cuda' \
  -DSYCL_ENABLE_EXTENSION_JIT=ON \
  -DSYCL_ENABLE_MAJOR_RELEASE_PREVIEW_LIB=ON \
  -DLIBCLC_TARGETS_TO_BUILD='nvptx64--nvidiacl' \
  -DLIBCLC_GENERATE_REMANGLED_VARIANTS=ON \
  -DLIBCLC_NATIVECPU_HOST_TARGET=ON \
  -DLLVM_ENABLE_RTTI=ON"

cd "$LLVM_SYCL_SOURCE_DIR/build"

bash -c "$cmake_cmd"
