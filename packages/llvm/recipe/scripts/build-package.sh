#!/bin/bash
# Main build script for rattler-build recipe
# Orchestrates configure, build, and install steps

set -exuo pipefail

# Source the build environment
source "${RECIPE_DIR}/build-activation/llvm.sh"

# Copy license file
cp "${SRC_DIR}/LICENSE.TXT" "${SRC_DIR}/LICENSE.TXT" 2>/dev/null || true

# Only build if not already installed
if [ ! -d "${CMAKE_INSTALL_PREFIX}" ] || [ ! -f "${CMAKE_INSTALL_PREFIX}/bin/clang++" ]; then
    echo "=== Configuring LLVM/DPC++ ==="
    bash "${RECIPE_DIR}/scripts/configure.sh"
    
    echo "=== Building LLVM/DPC++ ==="
    bash "${RECIPE_DIR}/scripts/build.sh"
    
    echo "=== Installing LLVM/DPC++ ==="
    bash "${RECIPE_DIR}/scripts/install.sh"

    # Install activation scripts for the conda package
    for action in "activate" "deactivate"; do
        mkdir -p "${CMAKE_INSTALL_PREFIX}/etc/conda/${action}.d"
        cp "${RECIPE_DIR}/${action}.sh" \
           "${CMAKE_INSTALL_PREFIX}/etc/conda/${action}.d/~100-dpcpp-toolkit-${action}.sh"
    done

    # Create clang configuration files for CUDA support
    # These use @PREFIX@ and @SYSROOT@ placeholders that are resolved at runtime
    echo "--cuda-path=@PREFIX@/targets/x86_64-linux" > "${CMAKE_INSTALL_PREFIX}/bin/${CONDA_TOOLCHAIN_HOST}-clang.cfg"
    echo "--cuda-path=@PREFIX@/targets/x86_64-linux" > "${CMAKE_INSTALL_PREFIX}/bin/${CONDA_TOOLCHAIN_HOST}-clang++.cfg"
fi

echo "=== Build complete ==="
