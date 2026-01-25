#!/bin/bash
# Build script for AdaptiveCpp rattler-build recipe
#
# OPTIMIZATION: This recipe produces 3 packages (libs, devel, toolkit) from one
# source. To avoid rebuilding 3 times, we:
#   1. Build once on first package, touch a marker file
#   2. Subsequent packages detect marker, skip build, just re-install to PREFIX
#
# Environment variables provided by rattler-build:
#   SRC_DIR     - Source directory (dummy - we use RECIPE_DIR/../repo instead)
#   PREFIX      - Install prefix for this package
#   BUILD_PREFIX - Build tools prefix
#   RECIPE_DIR  - Recipe directory
#   CPU_COUNT   - Number of CPUs available

set -exuo pipefail

echo "=============================================="
echo "Building AdaptiveCpp SYCL Toolkit"
echo "=============================================="
echo "SRC_DIR:      ${SRC_DIR}"
echo "PREFIX:       ${PREFIX}"
echo "BUILD_PREFIX: ${BUILD_PREFIX}"
echo "RECIPE_DIR:   ${RECIPE_DIR}"
echo "CPU_COUNT:    ${CPU_COUNT}"
echo "=============================================="

# =============================================================================
# Source and build directories
# =============================================================================
# SRC_DIR points to a dummy directory (to avoid copying the repo)
# The REAL source is relative to the actual recipe directory.
#
# RECIPE_DIR may be a symlink (e.g., devel/recipe -> ../recipe), so we need
# to resolve it to find the real location and then navigate to repo/
REAL_RECIPE_DIR="$(cd "${RECIPE_DIR}" && pwd -P)"
REPO_DIR="$(dirname "${REAL_RECIPE_DIR}")/repo"

if [[ ! -d "${REPO_DIR}" ]]; then
    echo "ERROR: Repository not found at ${REPO_DIR}"
    echo "RECIPE_DIR:      ${RECIPE_DIR}"
    echo "REAL_RECIPE_DIR: ${REAL_RECIPE_DIR}"
    echo ""
    echo "Make sure the submodule is initialized:"
    echo "  git submodule update --init packages/adaptivecpp/repo"
    exit 1
fi

echo ">>> RECIPE_DIR (may be symlink): ${RECIPE_DIR}"
echo ">>> REAL_RECIPE_DIR:             ${REAL_RECIPE_DIR}"
echo ">>> Using source directory:      ${REPO_DIR}"

# Build directory - inside the repo for persistence across package builds
BUILD_DIR="${REPO_DIR}/build"

# Marker file to indicate build is complete
BUILD_MARKER="${BUILD_DIR}/.build_complete"

echo ">>> Build directory: ${BUILD_DIR}"

# =============================================================================
# Check if build is already complete (optimization for multi-output recipe)
# =============================================================================
if [[ -f "${BUILD_MARKER}" ]]; then
    echo "=============================================="
    echo ">>> BUILD ALREADY COMPLETE - skipping to install"
    echo ">>> Previous build detected via marker: ${BUILD_MARKER}"
    echo "=============================================="
    
    # Just re-run install with this package's PREFIX
    echo ">>> Installing to ${PREFIX}..."
    cmake --install "${BUILD_DIR}" --prefix "${PREFIX}"
    
    echo "=============================================="
    echo "AdaptiveCpp install complete (reused existing build)"
    echo "Installed to: ${PREFIX}"
    echo "=============================================="
    exit 0
fi

# =============================================================================
# Full build (first package only)
# =============================================================================
echo ">>> No build marker found - performing full build"

# =============================================================================
# ccache configuration
# =============================================================================
export CCACHE_DIR="${CCACHE_DIR:-${HOME}/.cache/adaptivecpp-ccache}"
export CCACHE_MAXSIZE="${CCACHE_MAXSIZE:-20G}"
export CCACHE_COMPRESS=1
export CCACHE_COMPRESSLEVEL=6

mkdir -p "${CCACHE_DIR}"

echo ">>> ccache configuration:"
echo "    CCACHE_DIR:     ${CCACHE_DIR}"
echo "    CCACHE_MAXSIZE: ${CCACHE_MAXSIZE}"
ccache --show-stats || true
echo "=============================================="

# =============================================================================
# Compiler configuration - use relocatable names (basename only)
# =============================================================================
# Extract just the compiler basename (not absolute path) for relocatability
# This allows AdaptiveCpp to find compilers in PATH at runtime
# Force use of clang compilers (not gcc) for AdaptiveCpp

if [[ "${CXX}" == *clang* ]]; then
    CXX_COMPILER=$(basename "${CXX}")
else
    # Force clang if CXX doesn't contain 'clang'
    CXX_COMPILER="x86_64-conda-linux-gnu-clang++"
fi

if [[ "${CC}" == *clang* ]]; then
    C_COMPILER=$(basename "${CC}")
else
    # Force clang if CC doesn't contain 'clang'
    C_COMPILER="x86_64-conda-linux-gnu-clang"
fi

echo ">>> Compiler configuration:"
echo "    Original CC:  ${CC}"
echo "    Original CXX: ${CXX}"
echo "    Relocatable C:   ${C_COMPILER}"
echo "    Relocatable CXX: ${CXX_COMPILER}"

# CUDA configuration
CUDA_ROOT="${PREFIX}/targets/x86_64-linux"
if [[ ! -d "${CUDA_ROOT}" ]]; then
    echo "Warning: CUDA root not found at ${CUDA_ROOT}, trying PREFIX"
    CUDA_ROOT="${PREFIX}"
fi

# =============================================================================
# Configure AdaptiveCpp with CMake
# =============================================================================
echo ">>> Configuring AdaptiveCpp..."

mkdir -p "${BUILD_DIR}"

# Only run configure if build.ninja doesn't exist
if [[ ! -f "${BUILD_DIR}/build.ninja" ]]; then
    echo ">>> Running cmake configure..."
    
    # Clean any stale CMake state
    rm -f "${BUILD_DIR}/CMakeCache.txt" 2>/dev/null || true
    
     cmake -S "${REPO_DIR}" -B "${BUILD_DIR}" -G Ninja \
         -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
         -DCMAKE_C_COMPILER="${C_COMPILER}" \
         -DCMAKE_CXX_COMPILER="${CXX_COMPILER}" \
         -DCMAKE_C_COMPILER_LAUNCHER=ccache \
         -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
         -DCMAKE_BUILD_TYPE=Release \
         -DACPP_TARGETS="generic" \
         -DACPP_COMPILER_FEATURE_PROFILE=full \
         -DWITH_CUDA_BACKEND=ON \
         -DWITH_SSCP_COMPILER=ON \
         -DWITH_ACCELERATED_CPU=ON \
         -DWITH_STDPAR=ON \
         -DWITH_LLVM_INTEGRATION=ON \
         -DCUDAToolkit_ROOT="${CUDA_ROOT}" \
         -DACPP_LLD_PATH="${BUILD_PREFIX}/bin/lld"
else
    echo ">>> Skipping configure (using existing build.ninja)"
fi

# =============================================================================
# Build
# =============================================================================
echo ">>> Building AdaptiveCpp..."

cmake --build "${BUILD_DIR}" -j "${CPU_COUNT}"

# =============================================================================
# Install
# =============================================================================
echo ">>> Installing AdaptiveCpp to ${PREFIX}..."

cmake --install "${BUILD_DIR}" --prefix "${PREFIX}"

# =============================================================================
# Mark build as complete
# =============================================================================
echo ">>> Marking build as complete..."
touch "${BUILD_MARKER}"
echo "Created marker: ${BUILD_MARKER}"

# =============================================================================
# Show ccache stats
# =============================================================================
echo ">>> ccache statistics after build:"
ccache --show-stats || true

echo "=============================================="
echo "AdaptiveCpp build complete!"
echo "Installed to: ${PREFIX}"
echo "Build artifacts preserved in: ${BUILD_DIR}"
echo "=============================================="
