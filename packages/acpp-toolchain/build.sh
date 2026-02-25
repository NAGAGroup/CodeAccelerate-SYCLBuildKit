#!/usr/bin/env bash
# build.sh — LLVM 20 + AdaptiveCpp linked-into-LLVM build for conda
# Build compiler: gxx_linux-64 (conda-forge GCC, sysroot-aware)
set -euxo pipefail

# ── Compiler setup ────────────────────────────────────────────────────────
# Use conda's GCC toolchain to build LLVM/Clang.
# gxx_linux-64 sets CC/CXX/etc. via its own activation script, but we
# make them explicit here for clarity and robustness.
export CC="${CC:-${BUILD_PREFIX}/bin/x86_64-conda-linux-gnu-cc}"
export CXX="${CXX:-${BUILD_PREFIX}/bin/x86_64-conda-linux-gnu-c++}"
export AR="${AR:-${BUILD_PREFIX}/bin/x86_64-conda-linux-gnu-ar}"
export NM="${NM:-${BUILD_PREFIX}/bin/x86_64-conda-linux-gnu-nm}"
export RANLIB="${RANLIB:-${BUILD_PREFIX}/bin/x86_64-conda-linux-gnu-ranlib}"
export LD="${LD:-${BUILD_PREFIX}/bin/x86_64-conda-linux-gnu-ld}"

echo "Build compiler: $($CXX --version | head -1)"

# ── ccache setup ──────────────────────────────────────────────────────────
# ccache dir lives outside the isolated work dir so it persists across build
# attempts. rattler-build wipes $SRC_DIR on each invocation, so any cache
# inside the work dir is lost. Configurable via NAGA_ACPP_CCACHE_DIR for CI
# or shared cache scenarios.
export CCACHE_DIR="${RECIPE_DIR}/.ccache"
mkdir -p "${CCACHE_DIR}"
echo "ccache dir: ${CCACHE_DIR}"

# ── Source layout ─────────────────────────────────────────────────────────
LLVM_SRC="${SRC_DIR}/llvm-project"
ACPP_SRC="${SRC_DIR}/AdaptiveCpp"

# ── CUDA detection ────────────────────────────────────────────────────────
CUDA_ROOT=""
if [ -d "${PREFIX}/targets/x86_64-linux" ]; then
  CUDA_ROOT="${PREFIX}"
  echo "CUDA found at: ${CUDA_ROOT}"
elif [ -d "${BUILD_PREFIX}/targets/x86_64-linux" ]; then
  CUDA_ROOT="${BUILD_PREFIX}"
  echo "CUDA found at: ${CUDA_ROOT}"
else
  echo "WARNING: No conda CUDA toolkit found. NVPTX backend built without CUDA runtime."
fi

# ── Parallel link job calculation ─────────────────────────────────────────
# Each LLD link of libLLVM.so can consume ~4 GB RAM.
MEM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
MEM_GB=$((MEM_KB / 1024 / 1024))
LINK_JOBS=$((MEM_GB / 4))
LINK_JOBS=$((LINK_JOBS > 0 ? LINK_JOBS : 1))
LINK_JOBS=$((LINK_JOBS > CPU_COUNT ? CPU_COUNT : LINK_JOBS))
echo "Using ${LINK_JOBS} parallel link jobs (${MEM_GB} GB RAM detected)"

# ── Configure ─────────────────────────────────────────────────────────────
BUILD_DIR="${RECIPE_DIR}/build"
mkdir -p "${BUILD_DIR}"
cd "${BUILD_DIR}"

# ── LLVM pseudo-cross-compilation fix ────────────────────────────────────
# Using conda's gxx_linux-64 toolchain causes CMake to enter pseudo-cross-
# compilation mode (host triple != build triple from CMake's perspective).
# In this mode, LLVM's build system generates sub-invocations of CMake to
# configure compiler-rt, libomp, and other runtimes AFTER clang itself is
# compiled — but those sub-invocations can't find the freshly-built LLVM
# cmake configs sitting in the build directory because CMAKE_PREFIX_PATH
# doesn't include it. Prepending the build dir fixes the search path for
# these intermediate cmake calls without affecting the main build.
export CMAKE_PREFIX_PATH="${BUILD_DIR}${CMAKE_PREFIX_PATH:+:${CMAKE_PREFIX_PATH}}"

if [ -f "${BUILD_DIR}/install/bin/acpp" ]; then
  if [ -z "${INITIAL_CACHE_BUILD}" ]; then
    cp -r "${BUILD_DIR}"/install/* "${PREFIX}"
  fi
else
  # ── Skip configure+build if already completed (cache reuse across outputs) ─
  # rattler-build's experimental cache: section should handle this, but the
  # build script can be re-invoked for each output in practice. We guard the
  # expensive LLVM configure+build with a marker file(CMakeCache.txt)
  # so it only runs once. The install step always runs so each output gets files
  # copied to its own $PREFIX correctly.
  cmake "${LLVM_SRC}/llvm" -GNinja \
    -DCMAKE_BUILD_TYPE=Release \
    \
    `# ── ccache: wrap compiler via launcher so conda triple-prefixed names work ──` \
    -DCMAKE_C_COMPILER_LAUNCHER=ccache \
    -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
    \
    `# ── LLVM target and project selection ──` \
    -DLLVM_TARGETS_TO_BUILD="X86;NVPTX;AMDGPU" \
    -DLLVM_ENABLE_PROJECTS="clang;lld;openmp" \
    `# compiler-rt goes in ENABLE_RUNTIMES, not ENABLE_PROJECTS` \
    `# (ENABLE_PROJECTS is deprecated for compiler-rt in LLVM 20+)` \
    -DLLVM_ENABLE_RUNTIMES="compiler-rt" \
    \
    `# ── Shared libLLVM (required for SSCP JIT at runtime) ──` \
    -DLLVM_BUILD_LLVM_DYLIB=ON \
    -DLLVM_LINK_LLVM_DYLIB=ON \
    \
    `# ── RTTI + EH required for AdaptiveCpp plugin infrastructure ──` \
    -DLLVM_ENABLE_RTTI=ON \
    -DLLVM_ENABLE_EH=ON \
    \
    `# ── AdaptiveCpp as LLVM external project (linked-into-LLVM mode) ──` \
    -DLLVM_EXTERNAL_PROJECTS="AdaptiveCpp" \
    -DLLVM_EXTERNAL_ADAPTIVECPP_SOURCE_DIR="${ACPP_SRC}" \
    -DLLVM_ADAPTIVECPP_LINK_INTO_TOOLS=ON \
    \
    `# ── AdaptiveCpp backend configuration ──` \
    -DWITH_CUDA_BACKEND=ON \
    -DWITH_LEVEL_ZERO_BACKEND=ON \
    -DWITH_OPENCL_BACKEND=ON \
    -DWITH_CPU_BACKEND=ON \
    -DWITH_ACCELERATED_CPU=ON \
    -DACPP_COMPILER_FEATURE_PROFILE=full \
    \
    `# ── CUDA path ──` \
    ${CUDA_ROOT:+"-DCUDA_TOOLKIT_ROOT_DIR=${CUDA_ROOT}"} \
    \
    `# ── OpenMP: build libomp, skip GPU offloading (SSCP handles that) ──` \
    -DOPENMP_ENABLE_LIBOMPTARGET=OFF \
    \
    `# ── compiler-rt: builtins only, skip sanitizers/xray/etc ──` \
    -DCOMPILER_RT_BUILD_BUILTINS=ON \
    -DCOMPILER_RT_BUILD_SANITIZERS=OFF \
    -DCOMPILER_RT_BUILD_XRAY=OFF \
    -DCOMPILER_RT_BUILD_LIBFUZZER=OFF \
    -DCOMPILER_RT_BUILD_PROFILE=OFF \
    -DCOMPILER_RT_BUILD_MEMPROF=OFF \
    -DCOMPILER_RT_BUILD_ORC=OFF \
    \
    `# ── Build performance ──` \
    -DLLVM_PARALLEL_LINK_JOBS="${LINK_JOBS}" \
    -DLLVM_INCLUDE_BENCHMARKS=OFF \
    -DLLVM_INCLUDE_EXAMPLES=OFF \
    -DLLVM_INCLUDE_TESTS=OFF \
    \
    `# ── Conda host library integration ──` \
    -DLLVM_ENABLE_ZLIB=FORCE_ON \
    -DLLVM_ENABLE_ZSTD=FORCE_ON \
    -DLLVM_ENABLE_LIBXML2=FORCE_ON \
    \
    `# ── Disable unused optional deps ──` \
    -DLLVM_ENABLE_TERMINFO=OFF \
    -DLLVM_ENABLE_LIBEDIT=OFF \
    \
    `# ── Symbol versioning: prevents conflicts with system LLVM ──` \
    -DLLVM_DYLIB_SYMBOL_VERSIONING=ON \
    \
    `# ── RPATH: $ORIGIN-relative so install tree is relocatable ──` \
    -DCMAKE_INSTALL_RPATH="\$ORIGIN/../lib" \
    -DCMAKE_BUILD_RPATH="${BUILD_DIR}/lib" \
    \
    `# ── Target triple ──` \
    -DLLVM_HOST_TRIPLE="x86_64-conda-linux-gnu" \
    -DLLVM_DEFAULT_TARGET_TRIPLE="x86_64-conda-linux-gnu" \
    \
    `# ── pthread: explicit link required with --as-needed + LTO ──` \
    -DCMAKE_EXE_LINKER_FLAGS_INIT="-pthread" \
    -DCMAKE_SHARED_LINKER_FLAGS_INIT="-pthread" \
    -DCMAKE_MODULE_LINKER_FLAGS_INIT="-pthread"

  # ── Build ──────────────────────────────────────────────────────────────────
  ninja -j"${CPU_COUNT}"

  # ── Install ────────────────────────────────────────────────────────────────
  cmake --install . --prefix "${BUILD_DIR}/install"

  # ── No triple-named symlinks in the base package ─────────────────────────
  # conda-forge's base compiler packages do NOT install triple-prefixed symlinks.
  # Those belong entirely in acpp-toolchain-activation (the _linux-64 package).

  # ── ccache stats ──────────────────────────────────────────────────────────
  # Printed at end of build so hit rate is visible in rattler-build logs.
  ccache --show-stats

  echo "Build complete. Installed to ${BUILD_DIR}/install"
fi
