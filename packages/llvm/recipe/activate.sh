#!/bin/bash
# Activation script for sycl-dpcpp-toolkit conda package

# Backup existing variables
if [ -n "${CC:-}" ]; then
    export _SYCL_BACKUP_CC="${CC}"
fi
if [ -n "${CXX:-}" ]; then
    export _SYCL_BACKUP_CXX="${CXX}"
fi

# Set compiler environment
export CC="${CONDA_PREFIX}/bin/clang"
export CXX="${CONDA_PREFIX}/bin/clang++"

# CUDA paths
export CUDA_ROOT="${CONDA_PREFIX}/targets/x86_64-linux"
export CUDA_HOME="${CONDA_PREFIX}"
export CUDA_PATH="${CONDA_PREFIX}"

# OpenCL ICD configuration
export OCL_ICD_VENDORS="${CONDA_PREFIX}/etc/OpenCL/vendors"
