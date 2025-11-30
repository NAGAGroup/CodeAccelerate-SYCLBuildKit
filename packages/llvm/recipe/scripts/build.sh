#!/bin/bash
# Build script for SYCL Toolkit rattler-build recipe
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
echo "Building SYCL Toolkit (Intel DPC++)"
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
# SRC_DIR points to a dummy directory (to avoid copying 160k files)
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
    
    # Install activation scripts (only needed for toolkit package, but harmless for others)
    echo ">>> Installing activation scripts..."
    mkdir -p "${PREFIX}/etc/conda/activate.d"
    mkdir -p "${PREFIX}/etc/conda/deactivate.d"
    # Write activation script directly (since scripts are not bundled)
    cat /tmp/activate_content.sh > "${PREFIX}/etc/conda/activate.d/~~activate-sycl.sh"
    cat /tmp/deactivate_content.sh > "${PREFIX}/etc/conda/deactivate.d/~~deactivate-sycl.sh"
    chmod +x "${PREFIX}/etc/conda/activate.d/~~activate-sycl.sh"
    chmod +x "${PREFIX}/etc/conda/deactivate.d/~~deactivate-sycl.sh"
    
    # Copy license (required by rattler-build)
    echo ">>> Copying license..."
    cp "${REPO_DIR}/LICENSE.TXT" "${PREFIX}/LICENSE.TXT"
    echo "License copied to ${PREFIX}/LICENSE.TXT"
    
    # Create compiler symlinks (only matters for toolkit package)
    CHOST="${HOST:-x86_64-conda-linux-gnu}"
    if [[ -d "${PREFIX}/bin" ]]; then
        pushd "${PREFIX}/bin"
        for compiler in clang clang++ clang-cpp; do
            if [[ -e "${compiler}" ]] && [[ ! -e "${CHOST}-${compiler}" ]]; then
                ln -s "${compiler}" "${CHOST}-${compiler}"
                echo "Created symlink: ${CHOST}-${compiler} -> ${compiler}"
            fi
        done
        popd
        
        # Create config file if clang exists
        if [[ -e "${PREFIX}/bin/clang" ]]; then
            CONFIG_FILE="${PREFIX}/bin/${CHOST}.cfg"
            cat > "${CONFIG_FILE}" << 'CLANG_CFG'
# Clang configuration for conda-forge SYCL Toolkit
-I<CFGDIR>/../include/sycl
-I<CFGDIR>/../include/sycl/CL
-L<CFGDIR>/../lib
-Wl,-rpath,<CFGDIR>/../lib
CLANG_CFG
            echo "Created config file: ${CONFIG_FILE}"
        fi
    fi
    
    echo "=============================================="
    echo "SYCL Toolkit install complete (reused existing build)"
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

cd "${REPO_DIR}"
mkdir -p "${BUILD_DIR}"

# Only run configure if CMakeCache.txt doesn't exist
if [[ ! -f "${BUILD_DIR}/CMakeCache.txt" ]]; then
    
    echo ">>> Running configure (first build)..."
    
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
echo ">>> Creating clang config files for just-built compiler..."

CLANG_CFG_DIR="${BUILD_DIR}/bin"
mkdir -p "${CLANG_CFG_DIR}"

# Remove any existing cfg files
rm -f "${CLANG_CFG_DIR}"/*.cfg 2>/dev/null || true

# Find GCC version in BUILD_PREFIX
GCC_VERSION=$(ls "${BUILD_PREFIX}/lib/gcc/x86_64-conda-linux-gnu/" 2>/dev/null | head -1)
if [[ -n "${GCC_VERSION}" ]]; then
    echo "    Found GCC ${GCC_VERSION} in BUILD_PREFIX"
    
    cat > "${CLANG_CFG_DIR}/${HOST_TRIPLE}.cfg" << EOF
# Auto-generated config for conda sysroot
--gcc-toolchain=${BUILD_PREFIX}
--sysroot=${BUILD_PREFIX}/x86_64-conda-linux-gnu/sysroot
EOF
    echo "    Created ${CLANG_CFG_DIR}/${HOST_TRIPLE}.cfg"
    
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
# Step 3: Fix Unified Runtime -pie bug
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
# Step 5: Deploy and Install
# =============================================================================
echo ">>> Deploying SYCL toolchain..."
cmake --build "${BUILD_DIR}" --target deploy-sycl-toolchain -j "${CPU_COUNT}"

echo ">>> Installing LLVM/DPC++ to ${PREFIX}..."
cmake --install "${BUILD_DIR}" --prefix "${PREFIX}"

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
cat /tmp/activate_content.sh > "${PREFIX}/etc/conda/activate.d/~~activate-sycl.sh"
cat /tmp/deactivate_content.sh > "${PREFIX}/etc/conda/deactivate.d/~~deactivate-sycl.sh"
cp "${RECIPE_DIR}/scripts/deactivate.sh" "${PREFIX}/etc/conda/deactivate.d/~~deactivate-sycl.sh"

chmod +x "${PREFIX}/etc/conda/activate.d/~~activate-sycl.sh"
chmod +x "${PREFIX}/etc/conda/deactivate.d/~~deactivate-sycl.sh"

echo "Installed activation scripts"

# =============================================================================
# Step 8: Copy license (required by rattler-build)
# =============================================================================
echo ">>> Copying license..."
cp "${REPO_DIR}/LICENSE.TXT" "${PREFIX}/LICENSE.TXT"
echo "License copied to ${PREFIX}/LICENSE.TXT"

# =============================================================================
# Step 9: Mark build as complete
# =============================================================================
echo ">>> Marking build as complete..."
touch "${BUILD_MARKER}"
echo "Created marker: ${BUILD_MARKER}"

# =============================================================================
# Step 10: Show ccache stats
# =============================================================================
echo ">>> ccache statistics after build:"
ccache --show-stats || true

echo "=============================================="
echo "SYCL Toolkit build complete!"
echo "Installed to: ${PREFIX}"
echo "Build artifacts preserved in: ${BUILD_DIR}"
echo "=============================================="
