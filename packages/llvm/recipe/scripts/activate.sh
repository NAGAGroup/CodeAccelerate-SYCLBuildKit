#!/bin/bash
# SYCL Toolkit activation script
# Installed to: $PREFIX/etc/conda/activate.d/~~activate-sycl.sh
#
# This script runs AFTER other compiler activation scripts (due to ~~ prefix)
# so it can properly integrate with conda-forge compiler packages.

# Determine the prefix to use
if [ "${CONDA_BUILD:-0}" = "1" ]; then
    _SYCL_PREFIX="${PREFIX}"
else
    _SYCL_PREFIX="${CONDA_PREFIX}"
fi

# Host triple (matches conda-forge convention)
_SYCL_CHOST="x86_64-conda-linux-gnu"

# =============================================================================
# OpenCL ICD configuration
# =============================================================================
if [ -n "${OCL_ICD_VENDORS+x}" ]; then
    export CONDA_BACKUP_OCL_ICD_VENDORS="${OCL_ICD_VENDORS}"
fi
export OCL_ICD_VENDORS="${_SYCL_PREFIX}/etc/OpenCL/vendors"

# =============================================================================
# Compiler configuration
# =============================================================================
# Set CC and CXX to the triple-prefixed SYCL compilers
# This follows the conda-forge convention where compilers are named like:
#   x86_64-conda-linux-gnu-clang
#   x86_64-conda-linux-gnu-clang++

# Backup existing values
if [ -n "${CC+x}" ]; then
    export CONDA_BACKUP_CC="${CC}"
fi
if [ -n "${CXX+x}" ]; then
    export CONDA_BACKUP_CXX="${CXX}"
fi
if [ -n "${SYCL_CXX+x}" ]; then
    export CONDA_BACKUP_SYCL_CXX="${SYCL_CXX}"
fi
if [ -n "${SYCL_CC+x}" ]; then
    export CONDA_BACKUP_SYCL_CC="${SYCL_CC}"
fi

# Set compiler variables
export CC="${_SYCL_PREFIX}/bin/${_SYCL_CHOST}-clang"
export CXX="${_SYCL_PREFIX}/bin/${_SYCL_CHOST}-clang++"
export SYCL_CC="${CC}"
export SYCL_CXX="${CXX}"

# =============================================================================
# Build flags (similar to conda-forge pattern)
# =============================================================================
# These flags help integrate with conda environments

_SYCL_CFLAGS="-isystem ${_SYCL_PREFIX}/include"
_SYCL_CXXFLAGS="-isystem ${_SYCL_PREFIX}/include"
_SYCL_LDFLAGS="-Wl,-rpath,${_SYCL_PREFIX}/lib -L${_SYCL_PREFIX}/lib"

if [ -n "${CFLAGS+x}" ]; then
    export CONDA_BACKUP_CFLAGS="${CFLAGS}"
fi
if [ -n "${CXXFLAGS+x}" ]; then
    export CONDA_BACKUP_CXXFLAGS="${CXXFLAGS}"
fi
if [ -n "${LDFLAGS+x}" ]; then
    export CONDA_BACKUP_LDFLAGS="${LDFLAGS}"
fi

export CFLAGS="${_SYCL_CFLAGS}${CFLAGS:+ }${CFLAGS:-}"
export CXXFLAGS="${_SYCL_CXXFLAGS}${CXXFLAGS:+ }${CXXFLAGS:-}"
export LDFLAGS="${_SYCL_LDFLAGS}${LDFLAGS:+ }${LDFLAGS:-}"

# =============================================================================
# CMake configuration
# =============================================================================
if [ -n "${CMAKE_ARGS+x}" ]; then
    export CONDA_BACKUP_CMAKE_ARGS="${CMAKE_ARGS}"
fi

_CMAKE_ARGS="-DCMAKE_C_COMPILER=${CC}"
_CMAKE_ARGS="${_CMAKE_ARGS} -DCMAKE_CXX_COMPILER=${CXX}"
_CMAKE_ARGS="${_CMAKE_ARGS} -DSYCL_ROOT=${_SYCL_PREFIX}"

export CMAKE_ARGS="${_CMAKE_ARGS}${CMAKE_ARGS:+ }${CMAKE_ARGS:-}"

# =============================================================================
# Host/Build configuration (conda-forge convention)
# =============================================================================
if [ -n "${HOST+x}" ]; then
    export CONDA_BACKUP_HOST="${HOST}"
fi
if [ -n "${BUILD+x}" ]; then
    export CONDA_BACKUP_BUILD="${BUILD}"
fi

export HOST="${_SYCL_CHOST}"
export BUILD="${_SYCL_CHOST}"
export CONDA_TOOLCHAIN_HOST="${_SYCL_CHOST}"
export CONDA_TOOLCHAIN_BUILD="${_SYCL_CHOST}"

# =============================================================================
# Cleanup
# =============================================================================
unset _SYCL_PREFIX
unset _SYCL_CHOST
unset _SYCL_CFLAGS
unset _SYCL_CXXFLAGS
unset _SYCL_LDFLAGS
unset _CMAKE_ARGS
