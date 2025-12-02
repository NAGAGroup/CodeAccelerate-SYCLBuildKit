#!/bin/bash
# Linux build environment activation for local development builds
# (Not used by rattler-build recipe - only for `pixi run -e llvm` tasks)

if [ "${SYCL_BUILD_ENV_ACTIVE:-0}" != "1" ]; then
    # Core directories
    export PROJECT_ROOT="${PIXI_PROJECT_ROOT}"
    export PREFIX="${CONDA_PREFIX}"

    # Default install location for local development
    export INSTALL_PREFIX="${INSTALL_PREFIX:-${HOME}/.local/naga-sycl-toolkit}"

    # CUDA configuration (from conda-forge cuda-toolkit)
    if [ -d "${PREFIX}/targets/x86_64-linux" ]; then
        export CUDA_ROOT="${PREFIX}/targets/x86_64-linux"
        export CUDA_HOME="${PREFIX}"
        export CUDA_PATH="${PREFIX}"
    fi

    # OpenCL ICD loader configuration
    export OCL_ICD_VENDORS="${PREFIX}/etc/OpenCL/vendors"

    # ccache configuration (shared with rattler-build)
    export CCACHE_DIR="${HOME}/.cache/naga-sycl-toolkit-ccache"
    export CCACHE_MAXSIZE="50G"

    export SYCL_BUILD_ENV_ACTIVE=1
fi
