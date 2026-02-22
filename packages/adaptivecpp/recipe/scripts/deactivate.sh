#!/bin/bash
# AdaptiveCPP conda package deactivation script

# Restore compilers
if [ -n "${CONDA_BACKUP_CC:-}" ]; then
    export CC="$CONDA_BACKUP_CC"
    unset CONDA_BACKUP_CC
else
    unset CC
fi

if [ -n "${CONDA_BACKUP_CXX:-}" ]; then
    export CXX="$CONDA_BACKUP_CXX"
    unset CONDA_BACKUP_CXX
else
unset CXX
fi

# Restore host/build
if [ -n "${CONDA_BACKUP_HOST:-}" ]; then
    export HOST="$CONDA_BACKUP_HOST"
    unset CONDA_BACKUP_HOST
else
    unset HOST
fi

if [ -n "${CONDA_BACKUP_BUILD:-}" ]; then
    export BUILD="$CONDA_BACKUP_BUILD"
    unset CONDA_BACKUP_BUILD
else
    unset BUILD
fi

# Restore library path
if [ -n "${CONDA_BACKUP_LD_LIBRARY_PATH:-}" ]; then
    export LD_LIBRARY_PATH="$CONDA_BACKUP_LD_LIBRARY_PATH"
    unset CONDA_BACKUP_LD_LIBRARY_PATH
else
    unset LD_LIBRARY_PATH
fi

# Unset AdaptiveCPP-specific variables
unset ACPP_CC
unset ACPP_CXX
unset ACPP_TARGETS
unset ACPP_BACKENDS
unset CONDA_TOOLCHAIN_HOST
unset CONDA_TOOLCHAIN_BUILD

# Unset AdaptiveCPP path variables (set by activate.sh but previously missing from deactivate)
unset ACPP_PATH
unset ACPP_LIB_PATH
unset ACPP_CUDA_LIB_PATH
unset ACPP_CUDA_PATH
unset ACPP_CLANG

# Clean up symlinks created by activate.sh
rm -f "${CONDA_PREFIX}/bin/x86_64-conda-linux-gnu-clang++"
rm -f "${CONDA_PREFIX}/bin/x86_64-conda-linux-gnu-clang"

# Clean up .cfg response files written by activate.sh
rm -f "${CONDA_PREFIX}/bin/x86_64-conda-linux-gnu-clang++.cfg"
rm -f "${CONDA_PREFIX}/bin/x86_64-conda-linux-gnu-clang.cfg"
