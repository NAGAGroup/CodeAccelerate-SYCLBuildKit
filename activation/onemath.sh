#!/bin/bash
# oneMath (formerly oneMKL Interfaces) build environment activation
# Requires a pre-built DPC++ toolchain

# Source base linux environment first
if [ "${SYCL_BUILD_ENV_ACTIVE:-0}" != "1" ]; then
    source "${PIXI_PROJECT_ROOT}/activation/linux.sh"
fi

if [ "${ONEMATH_BUILD_ENV_ACTIVE:-0}" != "1" ]; then
    # oneMath source and build directories
    if [ -z "$ONEMATH_SOURCE_DIR" ]; then
        export ONEMATH_SOURCE_DIR="${PROJECT_ROOT}/packages/onemath/repo"
    fi
    if [ -z "$ONEMATH_BUILD_DIR" ]; then
        export ONEMATH_BUILD_DIR="${PROJECT_ROOT}/build/onemath"
    fi

    # DPC++ toolchain location (must be pre-built or installed)
    if [ -z "$DPCPP_ROOT" ]; then
        export DPCPP_ROOT="${INSTALL_PREFIX}"
    fi

    # Verify DPC++ is available
    if [ -x "${DPCPP_ROOT}/bin/clang++" ]; then
        export PATH="${DPCPP_ROOT}/bin:${PATH}"
        export LD_LIBRARY_PATH="${DPCPP_ROOT}/lib:${LD_LIBRARY_PATH}"
        export CC="${DPCPP_ROOT}/bin/clang"
        export CXX="${DPCPP_ROOT}/bin/clang++"
    else
        echo "Warning: DPC++ not found at ${DPCPP_ROOT}"
        echo "Set DPCPP_ROOT or run 'pixi run -e llvm install' first"
    fi

    # oneMath backend configuration (NVIDIA CUDA backends)
    if [ -z "$ONEMATH_BLAS_BACKENDS" ]; then
        export ONEMATH_BLAS_BACKENDS="cublas"
    fi
    if [ -z "$ONEMATH_LAPACK_BACKENDS" ]; then
        export ONEMATH_LAPACK_BACKENDS="cusolver"
    fi
    if [ -z "$ONEMATH_RNG_BACKENDS" ]; then
        export ONEMATH_RNG_BACKENDS="curand"
    fi
    if [ -z "$ONEMATH_DFT_BACKENDS" ]; then
        export ONEMATH_DFT_BACKENDS="cufft"
    fi
    if [ -z "$ONEMATH_SPARSE_BACKENDS" ]; then
        export ONEMATH_SPARSE_BACKENDS="cusparse"
    fi

    export ONEMATH_BUILD_ENV_ACTIVE=1
fi
