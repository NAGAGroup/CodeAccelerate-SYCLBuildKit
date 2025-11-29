#!/bin/bash
# SYCL Toolkit deactivation script
# Installed to: $PREFIX/etc/conda/deactivate.d/~~deactivate-sycl.sh
#
# Restores environment variables to their pre-activation state.

# =============================================================================
# OpenCL ICD configuration
# =============================================================================
if [ -n "${CONDA_BACKUP_OCL_ICD_VENDORS+x}" ]; then
    export OCL_ICD_VENDORS="${CONDA_BACKUP_OCL_ICD_VENDORS}"
    unset CONDA_BACKUP_OCL_ICD_VENDORS
else
    unset OCL_ICD_VENDORS
fi

# =============================================================================
# Compiler configuration
# =============================================================================
if [ -n "${CONDA_BACKUP_CC+x}" ]; then
    export CC="${CONDA_BACKUP_CC}"
    unset CONDA_BACKUP_CC
else
    unset CC
fi

if [ -n "${CONDA_BACKUP_CXX+x}" ]; then
    export CXX="${CONDA_BACKUP_CXX}"
    unset CONDA_BACKUP_CXX
else
    unset CXX
fi

if [ -n "${CONDA_BACKUP_SYCL_CC+x}" ]; then
    export SYCL_CC="${CONDA_BACKUP_SYCL_CC}"
    unset CONDA_BACKUP_SYCL_CC
else
    unset SYCL_CC
fi

if [ -n "${CONDA_BACKUP_SYCL_CXX+x}" ]; then
    export SYCL_CXX="${CONDA_BACKUP_SYCL_CXX}"
    unset CONDA_BACKUP_SYCL_CXX
else
    unset SYCL_CXX
fi

# =============================================================================
# Build flags
# =============================================================================
if [ -n "${CONDA_BACKUP_CFLAGS+x}" ]; then
    export CFLAGS="${CONDA_BACKUP_CFLAGS}"
    unset CONDA_BACKUP_CFLAGS
else
    unset CFLAGS
fi

if [ -n "${CONDA_BACKUP_CXXFLAGS+x}" ]; then
    export CXXFLAGS="${CONDA_BACKUP_CXXFLAGS}"
    unset CONDA_BACKUP_CXXFLAGS
else
    unset CXXFLAGS
fi

if [ -n "${CONDA_BACKUP_LDFLAGS+x}" ]; then
    export LDFLAGS="${CONDA_BACKUP_LDFLAGS}"
    unset CONDA_BACKUP_LDFLAGS
else
    unset LDFLAGS
fi

# =============================================================================
# CMake configuration
# =============================================================================
if [ -n "${CONDA_BACKUP_CMAKE_ARGS+x}" ]; then
    export CMAKE_ARGS="${CONDA_BACKUP_CMAKE_ARGS}"
    unset CONDA_BACKUP_CMAKE_ARGS
else
    unset CMAKE_ARGS
fi

# =============================================================================
# Host/Build configuration
# =============================================================================
if [ -n "${CONDA_BACKUP_HOST+x}" ]; then
    export HOST="${CONDA_BACKUP_HOST}"
    unset CONDA_BACKUP_HOST
else
    unset HOST
fi

if [ -n "${CONDA_BACKUP_BUILD+x}" ]; then
    export BUILD="${CONDA_BACKUP_BUILD}"
    unset CONDA_BACKUP_BUILD
else
    unset BUILD
fi

unset CONDA_TOOLCHAIN_HOST
unset CONDA_TOOLCHAIN_BUILD
