#!/bin/bash
# LLVM/DPC++ build environment for rattler-build recipe

set -e

if [ "${LINUX_BUILD_ENV_ACTIVE:-0}" != "1" ]; then
    source "${RECIPE_DIR}/build-activation/linux.sh"
fi

if [ "${DPCPP_BUILD_ENV_ACTIVE:-0}" != "1" ]; then
    # Package home directory
    export DPCPP_HOME="${RECIPE_DIR}/.."
    
    # Build directory
    export DPCPP_BUILD="${DPCPP_HOME}/build"
    
    # Source directory (from cache)
    export DPCPP_SOURCE="${SRC_DIR}"

    # GCC information (for reference, not for sysroot injection)
    if command -v gcc &> /dev/null; then
        export GCC_VERSION=$(gcc -dumpversion)
        export GCC_INSTALL_DIR="${PREFIX}/lib/gcc/${CONDA_TOOLCHAIN_HOST}/${GCC_VERSION}"
    fi

    # OpenCL ICD configuration
    export OCL_ICD_VENDORS="${PREFIX}/etc/OpenCL/vendors"

    # Backend configuration
    export SYCL_BACKENDS="${SYCL_BACKENDS:-opencl;cuda;native_cpu}"
    export LLVM_TARGETS="${LLVM_TARGETS:-X86;NVPTX;SPIRV}"

    export DPCPP_BUILD_ENV_ACTIVE=1
fi
