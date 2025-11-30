#!/bin/bash
# LLVM/DPC++ build environment activation for local development
# (Not used by rattler-build recipe - only for `pixi run -e llvm` tasks)

# Source base linux environment first
source "${PIXI_PROJECT_ROOT}/activation/linux.sh"

if [ "${LLVM_BUILD_ENV_ACTIVE:-0}" != "1" ]; then
    # LLVM source and build directories
    export LLVM_SOURCE_DIR="${LLVM_SOURCE_DIR:-${PROJECT_ROOT}/packages/llvm/repo}"
    export LLVM_BUILD_DIR="${LLVM_BUILD_DIR:-${PROJECT_ROOT}/build/llvm}"

    # Default backend configuration
    export SYCL_BACKENDS="${SYCL_BACKENDS:-opencl;cuda;native_cpu}"
    export LLVM_TARGETS="${LLVM_TARGETS:-X86;NVPTX;SPIRV}"

    export LLVM_BUILD_ENV_ACTIVE=1
fi
