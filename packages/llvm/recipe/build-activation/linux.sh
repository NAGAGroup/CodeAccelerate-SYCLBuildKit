#!/bin/bash
# Linux build environment for rattler-build recipe
# Simplified - no sysroot injection needed with modern Intel LLVM

set -e

if [ "${LINUX_BUILD_ENV_ACTIVE:-0}" != "1" ]; then
    # Use BUILD_PREFIX for build tools, PREFIX for host libraries
    export BUILD_PREFIX="${BUILD_PREFIX:-${CONDA_PREFIX}}"
    export PREFIX="${PREFIX:-${CONDA_PREFIX}}"
    
    # Toolchain host triple
    export CONDA_TOOLCHAIN_HOST="${CONDA_TOOLCHAIN_HOST:-${HOST:-x86_64-conda-linux-gnu}}"

    # CUDA configuration (from conda-forge cuda-toolkit)
    export CUDA_ROOT="${PREFIX}/targets/x86_64-linux"
    export CUDA_HOME="${PREFIX}"
    export CUDA_PATH="${PREFIX}"

    # Install prefix for the build (within recipe directory)
    export CMAKE_INSTALL_PREFIX="${RECIPE_DIR}/../install"

    # ccache configuration
    export CCACHE_DIR="${CCACHE_DIR:-${HOME}/.cache/ccache}"
    export CCACHE_MAXSIZE="${CCACHE_MAXSIZE:-50G}"

    export LINUX_BUILD_ENV_ACTIVE=1
fi
