#!/bin/bash
# Build script for SYCL Toolkit rattler-build recipe
# This script builds DIRECTLY in the repo directory for incremental builds
#
# Environment variables provided by rattler-build:
#   SRC_DIR     - Source directory (should be the actual repo, not a copy)
#   PREFIX      - Install prefix
#   BUILD_PREFIX - Build tools prefix
#   RECIPE_DIR  - Recipe directory
#   CPU_COUNT   - Number of CPUs available

set -exuo pipefail

echo "=============================================="
echo "Building SYCL Toolkit (Intel DPC++)"
echo "=============================================="
echo "SRC_DIR:      ${SRC_DIR}"
echo "PREFIX:       ${PREFIX}"
echo "BUILD_PREFIX: ${BUILD_PREFIX}"
echo "RECIPE_DIR:   ${RECIPE_DIR}"
echo "CPU_COUNT:    ${CPU_COUNT}"
echo "=============================================="

# =============================================================================
# Determine the REAL repo directory for in-place builds
# =============================================================================
# The recipe uses `source: path: ../repo` which means SRC_DIR might be:
# 1. A copy made by rattler-build (if it copies the source)
# 2. The actual repo directory (if rattler-build uses it directly)
#
# For incremental builds, we ALWAYS want to build in the real repo directory
# The real repo is at: RECIPE_DIR/../repo (relative to recipe/recipe.yaml)

REPO_DIR="$(cd "${RECIPE_DIR}/.." && pwd)/repo"

if [[ -d "${REPO_DIR}" ]]; then
    echo ">>> Using real repo directory for in-place build: ${REPO_DIR}"
    ACTUAL_SRC_DIR="${REPO_DIR}"
else
    echo ">>> Warning: Real repo not found at ${REPO_DIR}, using SRC_DIR"
    ACTUAL_SRC_DIR="${SRC_DIR}"
fi

# Build directory - inside the repo for persistence
BUILD_DIR="${ACTUAL_SRC_DIR}/build"

echo ">>> Build directory: ${BUILD_DIR}"
if [[ -d "${BUILD_DIR}" ]]; then
    echo ">>> Found existing build directory - will do incremental build!"
else
    echo ">>> No existing build directory - will do full build"
fi

# =============================================================================
# ccache configuration - use shared directory for all builds
# =============================================================================
export CCACHE_DIR="${CCACHE_DIR:-${HOME}/.cache/sycl-toolkit-ccache}"
export CCACHE_MAXSIZE="${CCACHE_MAXSIZE:-50G}"
export CCACHE_COMPRESS=1
export CCACHE_COMPRESSLEVEL=6

mkdir -p "${CCACHE_DIR}"

echo ">>> ccache configuration:"
echo "    CCACHE_DIR:     ${CCACHE_DIR}"
echo "    CCACHE_MAXSIZE: ${CCACHE_MAXSIZE}"
ccache --show-stats || true
echo "=============================================="

# CUDA configuration
CUDA_ROOT="${PREFIX}/targets/x86_64-linux"
if [[ ! -d "${CUDA_ROOT}" ]]; then
    echo "Warning: CUDA root not found at ${CUDA_ROOT}, trying PREFIX"
    CUDA_ROOT="${PREFIX}"
fi

# Toolchain host triple
HOST_TRIPLE="${HOST:-x86_64-conda-linux-gnu}"

# =============================================================================
# Compiler detection
# =============================================================================
echo ">>> Compiler configuration:"
echo "    CC:  ${CC:-not set}"
echo "    CXX: ${CXX:-not set}"

# =============================================================================
# Step 1: Configure with Intel LLVM's buildbot/configure.py
# =============================================================================
echo ">>> Configuring LLVM/DPC++..."

cd "${ACTUAL_SRC_DIR}"
mkdir -p "${BUILD_DIR}"

# Only run configure if CMakeCache.txt doesn't exist or PREFIX changed
if [[ ! -f "${BUILD_DIR}/CMakeCache.txt" ]] || \
   ! grep -q "CMAKE_INSTALL_PREFIX:PATH=${PREFIX}" "${BUILD_DIR}/CMakeCache.txt" 2>/dev/null; then
    
    echo ">>> Running configure (first build or PREFIX changed)..."
    
    python buildbot/configure.py \
        -o "${BUILD_DIR}" \
        --cmake-gen=Ninja \
        --shared-libs \
        --use-lld \
        --enable-all-llvm-targets \
        --cuda \
        --native_cpu \
        --cmake-opt="-DCMAKE_INSTALL_PREFIX=${PREFIX}" \
        --cmake-opt="-DCMAKE_C_COMPILER_LAUNCHER=ccache" \
        --cmake-opt="-DCMAKE_CXX_COMPILER_LAUNCHER=ccache" \
        --cmake-opt="-DLLVM_INSTALL_UTILS=ON" \
        --cmake-opt="-DLLVM_UTILS_INSTALL_DIR=libexec/llvm" \
        --cmake-opt="-DLLVM_LIBDIR_SUFFIX=" \
        --cmake-opt="-DLLVM_DEFAULT_TARGET_TRIPLE=${HOST_TRIPLE}" \
        --cmake-opt="-DLLVM_HOST_TRIPLE=${HOST_TRIPLE}" \
        --cmake-opt="-DCUDAToolkit_ROOT=${CUDA_ROOT}" \
        --cmake-opt="-DCMAKE_SHARED_LINKER_FLAGS_RELEASE=-Wl,--no-pie" \
        --cmake-opt="-DSYCL_LIBDEVICE_GCC_TOOLCHAIN=${BUILD_PREFIX}"
else
    echo ">>> Skipping configure (using existing CMakeCache.txt)"
fi

# =============================================================================
# Step 2: Create clang config files for the just-built compiler
# =============================================================================
# The just-built clang in BUILD_DIR/bin/ is used to compile libdevice targets.
# It needs to know where to find the C++ standard library headers from the
# conda GCC toolchain. We create .cfg files that point to the correct sysroot.
echo ">>> Creating clang config files for just-built compiler..."

CLANG_CFG_DIR="${BUILD_DIR}/bin"
mkdir -p "${CLANG_CFG_DIR}"

# Remove any existing cfg files (they may have stale paths from previous builds)
rm -f "${CLANG_CFG_DIR}"/*.cfg 2>/dev/null || true

# Find GCC version in BUILD_PREFIX
GCC_VERSION=$(ls "${BUILD_PREFIX}/lib/gcc/x86_64-conda-linux-gnu/" 2>/dev/null | head -1)
if [[ -n "${GCC_VERSION}" ]]; then
    echo "    Found GCC ${GCC_VERSION} in BUILD_PREFIX"
    
    # Create config file for the host triple
    # This will be picked up by clang when invoked with --target=x86_64-conda-linux-gnu
    cat > "${CLANG_CFG_DIR}/${HOST_TRIPLE}.cfg" << EOF
# Auto-generated config for conda sysroot
--gcc-toolchain=${BUILD_PREFIX}
--sysroot=${BUILD_PREFIX}/x86_64-conda-linux-gnu/sysroot
EOF
    echo "    Created ${CLANG_CFG_DIR}/${HOST_TRIPLE}.cfg"
    
    # Also create a generic clang.cfg for non-triple invocations
    cat > "${CLANG_CFG_DIR}/clang.cfg" << EOF
# Auto-generated config for conda sysroot
--gcc-toolchain=${BUILD_PREFIX}
--sysroot=${BUILD_PREFIX}/x86_64-conda-linux-gnu/sysroot
EOF
    echo "    Created ${CLANG_CFG_DIR}/clang.cfg"
    
    cat > "${CLANG_CFG_DIR}/clang++.cfg" << EOF
# Auto-generated config for conda sysroot
--gcc-toolchain=${BUILD_PREFIX}
--sysroot=${BUILD_PREFIX}/x86_64-conda-linux-gnu/sysroot
EOF
    echo "    Created ${CLANG_CFG_DIR}/clang++.cfg"
else
    echo "    Warning: Could not find GCC in BUILD_PREFIX, skipping cfg file creation"
fi

# =============================================================================
# Step 3: Fix Unified Runtime -pie bug (affects GCC builds)
# =============================================================================
echo ">>> Checking Unified Runtime cmake patch..."

UR_HELPERS="${BUILD_DIR}/_deps/unified-runtime-src/cmake/helpers.cmake"
if [[ -f "${UR_HELPERS}" ]]; then
    if grep -q '\$<\$<CXX_COMPILER_ID:GNU>:-pie>' "${UR_HELPERS}" 2>/dev/null; then
        sed -i 's/\$<\$<CXX_COMPILER_ID:GNU>:-pie>/#$<$<CXX_COMPILER_ID:GNU>:-pie> # DISABLED: breaks shared libs/' "${UR_HELPERS}"
        echo "Patched: ${UR_HELPERS}"
    else
        echo "Already patched or not needed"
    fi
else
    echo "Warning: helpers.cmake not found yet (will be downloaded during build)"
fi

# =============================================================================
# Step 4: Build
# =============================================================================
echo ">>> Building LLVM/DPC++ (incremental if possible)..."

cmake --build "${BUILD_DIR}" -j "${CPU_COUNT}"

# =============================================================================
# Step 5: Install to PREFIX
# =============================================================================
echo ">>> Installing LLVM/DPC++ to ${PREFIX}..."

# Deploy SYCL toolchain components
cmake --build "${BUILD_DIR}" --target deploy-sycl-toolchain -j "${CPU_COUNT}"

# Run cmake install
cmake --build "${BUILD_DIR}" --target install -j "${CPU_COUNT}"

# =============================================================================
# Step 6: Create compiler symlinks and config files
# =============================================================================
echo ">>> Creating compiler symlinks and config files..."

CHOST="${HOST_TRIPLE}"
echo "Host triple: ${CHOST}"

pushd "${PREFIX}/bin"
  for compiler in clang clang++ clang-cpp; do
    if [[ ! -e "${CHOST}-${compiler}" ]]; then
      ln -s "${compiler}" "${CHOST}-${compiler}"
      echo "Created symlink: ${CHOST}-${compiler} -> ${compiler}"
    fi
  done
popd

CONFIG_DIR="${PREFIX}/bin"
CONFIG_FILE="${CONFIG_DIR}/${CHOST}.cfg"

cat > "${CONFIG_FILE}" << 'CLANG_CFG'
# Clang configuration for conda-forge SYCL Toolkit
-I<CFGDIR>/../include/sycl
-I<CFGDIR>/../include/sycl/CL
-L<CFGDIR>/../lib
-Wl,-rpath,<CFGDIR>/../lib
CLANG_CFG

echo "Created config file: ${CONFIG_FILE}"

# =============================================================================
# Step 7: Install activation scripts
# =============================================================================
echo ">>> Installing activation scripts..."

mkdir -p "${PREFIX}/etc/conda/activate.d"
mkdir -p "${PREFIX}/etc/conda/deactivate.d"

cp "${RECIPE_DIR}/scripts/activate.sh" "${PREFIX}/etc/conda/activate.d/~~activate-sycl.sh"
cp "${RECIPE_DIR}/scripts/deactivate.sh" "${PREFIX}/etc/conda/deactivate.d/~~deactivate-sycl.sh"

chmod +x "${PREFIX}/etc/conda/activate.d/~~activate-sycl.sh"
chmod +x "${PREFIX}/etc/conda/deactivate.d/~~deactivate-sycl.sh"

echo "Installed activation scripts"

# =============================================================================
# Step 8: Copy license to PREFIX
# =============================================================================
echo ">>> Copying license..."
cp "${ACTUAL_SRC_DIR}/LICENSE.TXT" "${PREFIX}/LICENSE.TXT" 2>/dev/null || true

# =============================================================================
# Step 9: Show ccache stats after build
# =============================================================================
echo ">>> ccache statistics after build:"
ccache --show-stats || true

echo "=============================================="
echo "SYCL Toolkit build complete!"
echo "Installed to: ${PREFIX}"
echo "Build artifacts preserved in: ${BUILD_DIR}"
echo "=============================================="
