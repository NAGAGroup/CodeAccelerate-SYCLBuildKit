#!/bin/bash
# oneAPI libraries build environment activation
# Supports both DPC++ and AdaptiveCpp

# Source base linux environment first
if [ "${SYCL_BUILD_ENV_ACTIVE:-0}" != "1" ]; then
    source "${PIXI_PROJECT_ROOT}/activation/linux.sh"
fi

if [ "${ONEAPI_BUILD_ENV_ACTIVE:-0}" != "1" ]; then
    # Source and build directories
    if [ -z "$ONEMATH_SOURCE_DIR" ]; then
        export ONEMATH_SOURCE_DIR="${PROJECT_ROOT}/packages/onemath/repo"
    fi
    if [ -z "$ONEMATH_BUILD_DIR" ]; then
        export ONEMATH_BUILD_DIR="${PROJECT_ROOT}/build/onemath"
    fi

    # SYCL implementation selection
    export SYCL_IMPLEMENTATION="${SYCL_IMPLEMENTATION:-dpcpp}"
    
    # SYCL toolchain location
    if [ -z "$DPCPP_ROOT" ]; then
        export DPCPP_ROOT="${INSTALL_PREFIX}"
    fi

    # Determine compiler based on implementation
    if [ "$SYCL_IMPLEMENTATION" = "adaptivecpp" ]; then
        SYCL_COMPILER="${DPCPP_ROOT}/bin/acpp"
    else
        SYCL_COMPILER="${DPCPP_ROOT}/bin/clang++"
    fi

    # Verify SYCL compiler is available
    if [ -x "${SYCL_COMPILER}" ]; then
        export PATH="${DPCPP_ROOT}/bin:${PATH}"
        export LD_LIBRARY_PATH="${DPCPP_ROOT}/lib:${LD_LIBRARY_PATH}"
        export CC="${SYCL_COMPILER}"
        export CXX="${SYCL_COMPILER}"
    else
        echo "Warning: SYCL compiler not found at ${SYCL_COMPILER}"
        echo "Implementation: ${SYCL_IMPLEMENTATION}"
        echo "Set DPCPP_ROOT or build the SYCL implementation first"
    fi

    # Backend configuration (same as before)
    export ONEMATH_BLAS_BACKENDS="${ONEMATH_BLAS_BACKENDS:-cublas}"
    export ONEMATH_LAPACK_BACKENDS="${ONEMATH_LAPACK_BACKENDS:-cusolver}"
    export ONEMATH_RNG_BACKENDS="${ONEMATH_RNG_BACKENDS:-curand}"
    export ONEMATH_DFT_BACKENDS="${ONEMATH_DFT_BACKENDS:-cufft}"
    export ONEMATH_SPARSE_BACKENDS="${ONEMATH_SPARSE_BACKENDS:-cusparse}"

    export ONEAPI_BUILD_ENV_ACTIVE=1
fi
