#!/bin/bash
# Deactivation script for sycl-dpcpp-toolkit conda package

# Restore backed up variables
if [ -n "${_SYCL_BACKUP_CC:-}" ]; then
    export CC="${_SYCL_BACKUP_CC}"
    unset _SYCL_BACKUP_CC
else
    unset CC
fi

if [ -n "${_SYCL_BACKUP_CXX:-}" ]; then
    export CXX="${_SYCL_BACKUP_CXX}"
    unset _SYCL_BACKUP_CXX
else
    unset CXX
fi

# Unset SYCL-specific variables
unset CUDA_ROOT
unset CUDA_HOME
unset CUDA_PATH
unset OCL_ICD_VENDORS
