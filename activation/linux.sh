#!/bin/bash
# Linux build environment activation
# Simplified version - no sysroot injection needed with modern Intel LLVM

if [ "${SYCL_BUILD_ENV_ACTIVE:-0}" != "1" ]; then
    # Core directories
    export PROJECT_ROOT="${PIXI_PROJECT_ROOT}"
    export BUILD_PREFIX="${CONDA_PREFIX}"
    export PREFIX="${CONDA_PREFIX}"
    
    # Default install location for local development
    if [ -z "$INSTALL_PREFIX" ]; then
        export INSTALL_PREFIX="${HOME}/.local/sycl-toolkit"
    fi

    # CUDA configuration (from conda-forge cuda-toolkit)
    if [ -d "${PREFIX}/targets/x86_64-linux" ]; then
        export CUDA_ROOT="${PREFIX}/targets/x86_64-linux"
        export CUDA_HOME="${PREFIX}"
        export CUDA_PATH="${PREFIX}"
    fi

    # OpenCL ICD loader configuration
    export OCL_ICD_VENDORS="${PREFIX}/etc/OpenCL/vendors"

    # ccache configuration
    export CCACHE_DIR="${HOME}/.cache/ccache"
    export CCACHE_MAXSIZE="50G"

    export SYCL_BUILD_ENV_ACTIVE=1
fi
