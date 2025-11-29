#!/bin/bash
# LLVM/DPC++ build environment activation
# Sets up paths and environment for building Intel LLVM/DPC++

# Source base linux environment first
if [ "${SYCL_BUILD_ENV_ACTIVE:-0}" != "1" ]; then
    source "${PIXI_PROJECT_ROOT}/activation/linux.sh"
fi

if [ "${LLVM_BUILD_ENV_ACTIVE:-0}" != "1" ]; then
    # LLVM source and build directories
    # These can be overridden via pixi.toml activation.env
    if [ -z "$LLVM_SOURCE_DIR" ]; then
        export LLVM_SOURCE_DIR="${PROJECT_ROOT}/packages/llvm/repo"
    fi
    if [ -z "$LLVM_BUILD_DIR" ]; then
        export LLVM_BUILD_DIR="${PROJECT_ROOT}/build/llvm"
    fi

    # GCC information for clang configuration files
    # (May be needed for some library paths, but no longer for sysroot injection)
    if command -v gcc &> /dev/null; then
        export GCC_VERSION=$(gcc -dumpversion)
        export GCC_INSTALL_DIR="${PREFIX}/lib/gcc/x86_64-conda-linux-gnu/${GCC_VERSION}"
    fi

    # Default backend configuration
    if [ -z "$SYCL_BACKENDS" ]; then
        export SYCL_BACKENDS="opencl;cuda;native_cpu"
    fi
    if [ -z "$LLVM_TARGETS" ]; then
        export LLVM_TARGETS="X86;NVPTX;SPIRV"
    fi

    export LLVM_BUILD_ENV_ACTIVE=1
fi
