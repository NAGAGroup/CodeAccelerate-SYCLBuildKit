#!/bin/bash
# Build script for naga-onedpl rattler-build recipe
#
# oneDPL is header-only, so we just:
#   1. Run CMake configure to generate proper CMake config files
#   2. Run CMake install to copy headers and config files
#
# No actual compilation is needed.
#
# Environment variables provided by rattler-build:
#   SRC_DIR     - Source directory (dummy - we use RECIPE_DIR/../repo instead)
#   PREFIX      - Install prefix for this package
#   BUILD_PREFIX - Build tools prefix
#   RECIPE_DIR  - Recipe directory
#   CPU_COUNT   - Number of CPUs available

set -exuo pipefail

echo "=============================================="
echo "Building naga-onedpl (Header-only SYCL Library)"
echo "=============================================="
echo "SRC_DIR:      ${SRC_DIR}"
echo "PREFIX:       ${PREFIX}"
echo "BUILD_PREFIX: ${BUILD_PREFIX}"
echo "RECIPE_DIR:   ${RECIPE_DIR}"
echo "=============================================="

# =============================================================================
# Source and build directories
# =============================================================================
# SRC_DIR points to a dummy directory (to avoid copying the repo)
# The REAL source is relative to the actual recipe directory.
REAL_RECIPE_DIR="$(cd "${RECIPE_DIR}" && pwd -P)"
REPO_DIR="$(dirname "${REAL_RECIPE_DIR}")/repo"

if [[ ! -d "${REPO_DIR}" ]]; then
    echo "ERROR: Repository not found at ${REPO_DIR}"
    echo "RECIPE_DIR:      ${RECIPE_DIR}"
    echo "REAL_RECIPE_DIR: ${REAL_RECIPE_DIR}"
    echo ""
    echo "Make sure the submodule is initialized:"
    echo "  git submodule update --init packages/onedpl/repo"
    exit 1
fi

echo ">>> RECIPE_DIR (may be symlink): ${RECIPE_DIR}"
echo ">>> REAL_RECIPE_DIR:             ${REAL_RECIPE_DIR}"
echo ">>> Using source directory:      ${REPO_DIR}"

# Build directory - inside the repo for caching
BUILD_DIR="${REPO_DIR}/build"

echo ">>> Build directory: ${BUILD_DIR}"

# =============================================================================
# AdaptiveCpp SYCL headers configuration
# =============================================================================
# Add AdaptiveCpp include path to compiler flags to ensure sycl/sycl.hpp is found
# export CXXFLAGS="${CXXFLAGS:-} -I${PREFIX}/include/AdaptiveCpp"
# export CFLAGS="${CFLAGS:-} -I${PREFIX}/include/AdaptiveCpp"

echo ">>> AdaptiveCpp include path added to compiler flags"
echo "    CXXFLAGS: ${CXXFLAGS}"
echo "    CFLAGS:   ${CFLAGS}"
echo "=============================================="

# =============================================================================
# Compiler configuration for AdaptiveCpp
# =============================================================================
# Use system C/C++ compilers provided by rattler-build (${CC} and ${CXX})
# AdaptiveCpp headers will be found via CXXFLAGS set above
# SYCL_CXX="${CXX}"

# if [[ -z "${SYCL_CXX}" ]]; then
#     echo "ERROR: CXX compiler not set by build environment"
#     echo "This should be provided by rattler-build"
#     exit 1
# fi
#
# echo ">>> Using compiler: ${SYCL_CXX}"
# "${SYCL_CXX}" --version
# echo "=============================================="

# =============================================================================
# Configure oneDPL with CMake
# =============================================================================
echo ">>> Configuring oneDPL..."

mkdir -p "${BUILD_DIR}"

export CXX="${BUILD_PREFIX}/bin/acpp"

cmake -S "${REPO_DIR}" -B "${BUILD_DIR}" -G Ninja \
    -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
    -DCMAKE_C_COMPILER="${CC}" \
    -DCMAKE_CXX_COMPILER="${CXX}" \
    -DCMAKE_CXX_FLAGS="${CXXFLAGS}" \
    -DCMAKE_C_FLAGS="${CFLAGS}" \
    -DONEDPL_BACKEND=dpcpp \
    -DONEDPL_USE_TBB_BACKEND=0 \
    -DBUILD_TESTING=OFF

# =============================================================================
# Install (no build step needed - header-only library)
# =============================================================================
echo ">>> Installing oneDPL to ${PREFIX}..."

cmake --install "${BUILD_DIR}"

# =============================================================================
# Copy license (required by rattler-build)
# =============================================================================
echo ">>> Copying license..."
cp "${REPO_DIR}/LICENSE.txt" "${PREFIX}/LICENSE.txt"
echo "License copied to ${PREFIX}/LICENSE.txt"

echo "=============================================="
echo "naga-onedpl install complete!"
echo "Installed to: ${PREFIX}"
echo "=============================================="
