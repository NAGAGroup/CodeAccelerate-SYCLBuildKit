#!/bin/bash
set -euo pipefail

# ============================================================================
# Section 1: Setup and Path Resolution
# ============================================================================
REAL_RECIPE_DIR="$(cd "${RECIPE_DIR}" && pwd -P)"
PACKAGE_DIR=$(cd "$REAL_RECIPE_DIR/.." && pwd -P)
LLVM_SOURCE_DIR="$PACKAGE_DIR/llvm-project"
ACPP_SOURCE_DIR="$LLVM_SOURCE_DIR/AdaptiveCpp"
BUILD_DIR="$PACKAGE_DIR/llvm-project/build"
BUILD_MARKER="$BUILD_DIR/.build_complete"

echo "LLVM Source:  $LLVM_SOURCE_DIR"
echo "ACPP Source:  $ACPP_SOURCE_DIR"
echo "Build Dir:    $BUILD_DIR"
echo "Install:      $PREFIX"

# ============================================================================
# Section 2: Verify Sources
# ============================================================================
if [ ! -d "$LLVM_SOURCE_DIR/llvm" ] || [ ! -d "$ACPP_SOURCE_DIR" ]; then
    echo "ERROR: Sources not found"
    exit 1
fi

# ============================================================================
# Section 3: Multi-Output Optimization (check build marker)
# ============================================================================
if [ -f "$BUILD_MARKER" ]; then
    echo "Build complete - running install only"
    cmake --install "$BUILD_DIR" --prefix "$PREFIX"
    # Skip to activation script installation (Section 7)
    mkdir -p "$PREFIX/etc/conda/activate.d"
    mkdir -p "$PREFIX/etc/conda/deactivate.d"
    
    cp "$RECIPE_DIR/scripts/activate.sh" \
       "$PREFIX/etc/conda/activate.d/~~activate-acpp.sh"
    cp "$RECIPE_DIR/scripts/deactivate.sh" \
       "$PREFIX/etc/conda/deactivate.d/~~deactivate-acpp.sh"
    
    chmod +x "$PREFIX/etc/conda/activate.d/~~activate-acpp.sh"
    chmod +x "$PREFIX/etc/conda/deactivate.d/~~deactivate-acpp.sh"
    exit 0
fi

# ============================================================================
# Section 4: Configure + Build
# ============================================================================
export CCACHE_DIR="${CCACHE_DIR:-$HOME/.ccache}"
export CCACHE_MAXSIZE="${CCACHE_MAXSIZE:-20G}"

# Use GCC from conda environment (via $CC and $CXX)
C_COMPILER="${CC}"
CXX_COMPILER="${CXX}"

# Toolchain host triple for cross-compilation support
HOST_TRIPLE="${HOST:-x86_64-conda-linux-gnu}"

mkdir -p "$BUILD_DIR"

export CXXFLAGS=
export CFLAGS=

# Configure (if not already configured)
if [ ! -f "$BUILD_DIR/build.ninja" ]; then
    # Use GCC as bootstrap compiler (standard practice)
    # CMAKE_SYSROOT and compiler target still needed for conda pseudo-cross-compilation
    
    cmake -S "$LLVM_SOURCE_DIR/llvm" -B "$BUILD_DIR" \
        -GNinja \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX="$PREFIX" \
        -DCMAKE_C_COMPILER="$(basename $C_COMPILER)" \
        -DCMAKE_CXX_COMPILER="$(basename $CXX_COMPILER)" \
        -DCMAKE_C_COMPILER_LAUNCHER=ccache \
        -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
        -DCMAKE_SYSROOT="${BUILD_PREFIX}/${HOST_TRIPLE}/sysroot" \
        -DLLVM_TARGETS_TO_BUILD="X86;NVPTX;AMDGPU" \
        -DLLVM_ENABLE_PROJECTS="clang;openmp;lld" \
        -DLLVM_BUILD_LLVM_DYLIB=ON \
        -DLLVM_LINK_LLVM_DYLIB=ON \
        -DLLVM_ENABLE_ASSERTIONS=OFF -DLLVM_ENABLE_DUMP=OFF \
        -DLLVM_PARALLEL_LINK_JOBS="${CPU_COUNT:-4}" \
        -DLLVM_EXTERNAL_PROJECTS=AdaptiveCpp \
        -DLLVM_EXTERNAL_ADAPTIVECPP_SOURCE_DIR="$ACPP_SOURCE_DIR" \
        -DLLVM_ADAPTIVECPP_LINK_INTO_TOOLS=ON \
        -DACPP_TARGETS=generic \
        -DWITH_CUDA_BACKEND=ON \
        -DACPP_COMPILER_FEATURE_PROFILE=full \
        $CMAKE_ARGS
        # -DCMAKE_C_COMPILER_TARGET="${HOST_TRIPLE}" \
        # -DCMAKE_CXX_COMPILER_TARGET="${HOST_TRIPLE}" \
        # -DLLVM_DEFAULT_TARGET_TRIPLE="${HOST_TRIPLE}" \
        # -DLLVM_HOST_TRIPLE="${HOST_TRIPLE}" \
fi

# Build
cmake --build "$BUILD_DIR" -j "${CPU_COUNT:-4}"

# ============================================================================
# Section 5: Install
# ============================================================================
cmake --install "$BUILD_DIR" --prefix "$PREFIX"

# ===========================================================================
# Section 5b: Post-Install Path Adjustments
# ==========================================================================
find "$PREFIX/etc/AdaptiveCpp" -type f -name "*.json" -exec sed -i "s|${BUILD_PREFIX}|\$ACPP_PATH|g" {} +

# ============================================================================
# Section 6: IDE Tooling Compatibility (symlinks + clang.cfg)
# ============================================================================
BUILD_TRIPLET="${HOST_TRIPLE}"

# ============================================================================
# Section 7: Install Activation Scripts
# ============================================================================
mkdir -p "$PREFIX/etc/conda/activate.d"
mkdir -p "$PREFIX/etc/conda/deactivate.d"

cp "$RECIPE_DIR/scripts/activate.sh" \
   "$PREFIX/etc/conda/activate.d/~~activate-acpp.sh"
cp "$RECIPE_DIR/scripts/deactivate.sh" \
   "$PREFIX/etc/conda/deactivate.d/~~deactivate-acpp.sh"

chmod +x "$PREFIX/etc/conda/activate.d/~~activate-acpp.sh"
chmod +x "$PREFIX/etc/conda/deactivate.d/~~deactivate-acpp.sh"

# ============================================================================
# Section 8: Create Build Marker
# ============================================================================
touch "$BUILD_MARKER"
echo "Build complete."
