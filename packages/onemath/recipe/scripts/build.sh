#!/bin/bash
# Build script for oneMath rattler-build recipe
#
# OPTIMIZATION: This recipe produces 3 packages (libs, devel, onemath) from one
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
echo "Building oneMath (SYCL Math Library)"
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
    echo "  git submodule update --init packages/onemath/repo"
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
    
    # Copy license (required by rattler-build)
    echo ">>> Copying license..."
    cp "${REPO_DIR}/LICENSE" "${PREFIX}/LICENSE"
    echo "License copied to ${PREFIX}/LICENSE"
    
    echo "=============================================="
    echo "oneMath install complete (reused existing build)"
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
export CCACHE_DIR="${CCACHE_DIR:-${HOME}/.cache/onemath-ccache}"
export CCACHE_MAXSIZE="${CCACHE_MAXSIZE:-10G}"
export CCACHE_COMPRESS=1
export CCACHE_COMPRESSLEVEL=6

mkdir -p "${CCACHE_DIR}"

echo ">>> ccache configuration:"
echo "    CCACHE_DIR:     ${CCACHE_DIR}"
echo "    CCACHE_MAXSIZE: ${CCACHE_MAXSIZE}"
ccache --show-stats || true
echo "=============================================="

# =============================================================================
# Find SYCL compiler (from sycl-toolkit package)
# =============================================================================
SYCL_ROOT="${PREFIX}"
SYCL_CXX="${SYCL_ROOT}/bin/clang++"
SYCL_CC="${SYCL_ROOT}/bin/clang"

if [[ ! -x "${SYCL_CXX}" ]]; then
    echo "ERROR: SYCL compiler not found at ${SYCL_CXX}"
    echo "Make sure sycl-toolkit is in host requirements"
    exit 1
fi

echo ">>> SYCL compiler: ${SYCL_CXX}"
"${SYCL_CXX}" --version

# =============================================================================
# CUDA configuration
# =============================================================================
CUDA_ROOT="${PREFIX}/targets/x86_64-linux"
if [[ ! -d "${CUDA_ROOT}" ]]; then
    CUDA_ROOT="${PREFIX}"
fi

echo ">>> CUDA root: ${CUDA_ROOT}"

# =============================================================================
# Configure oneMath with CMake
# =============================================================================
echo ">>> Configuring oneMath..."

mkdir -p "${BUILD_DIR}"

# Only run configure if build.ninja doesn't exist (indicates valid build system)
# We check build.ninja instead of CMakeCache.txt because CMakeCache.txt can exist
# from a failed configure that didn't generate the build system
if [[ ! -f "${BUILD_DIR}/build.ninja" ]]; then
    echo ">>> Running cmake configure..."
    
    # Clean any stale CMake state that might interfere
    rm -f "${BUILD_DIR}/CMakeCache.txt" 2>/dev/null || true
    
    cmake -S "${REPO_DIR}" -B "${BUILD_DIR}" -G Ninja \
        -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
        -DCMAKE_C_COMPILER="${SYCL_CC}" \
        -DCMAKE_CXX_COMPILER="${SYCL_CXX}" \
        -DCMAKE_C_COMPILER_LAUNCHER=ccache \
        -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
        -DSYCL_IMPLEMENTATION=dpc++ \
        -DENABLE_SYCL=ON \
        -DTARGET_DOMAINS="blas;lapack;rng;dft;sparse_blas" \
        -DENABLE_MKLCPU_BACKEND=OFF \
        -DENABLE_MKLGPU_BACKEND=OFF \
        -DENABLE_CUBLAS_BACKEND=ON \
        -DENABLE_CUSOLVER_BACKEND=ON \
        -DENABLE_CURAND_BACKEND=ON \
        -DENABLE_CUFFT_BACKEND=ON \
        -DENABLE_CUSPARSE_BACKEND=ON \
        -DCUDAToolkit_ROOT="${CUDA_ROOT}" \
        -DBUILD_SHARED_LIBS=ON \
        -DBUILD_FUNCTIONAL_TESTS=OFF \
        -DBUILD_EXAMPLES=OFF \
        -DBUILD_DOC=OFF
else
    echo ">>> Skipping configure (using existing build.ninja)"
fi

# =============================================================================
# Build
# =============================================================================
echo ">>> Building oneMath..."

cmake --build "${BUILD_DIR}" -j "${CPU_COUNT}"

# =============================================================================
# Install
# =============================================================================
echo ">>> Installing oneMath to ${PREFIX}..."

cmake --install "${BUILD_DIR}" --prefix "${PREFIX}"

# =============================================================================
# Copy license (required by rattler-build)
# =============================================================================
echo ">>> Copying license..."
cp "${REPO_DIR}/LICENSE" "${PREFIX}/LICENSE"
echo "License copied to ${PREFIX}/LICENSE"

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
echo "oneMath build complete!"
echo "Installed to: ${PREFIX}"
echo "Build artifacts preserved in: ${BUILD_DIR}"
echo "=============================================="
