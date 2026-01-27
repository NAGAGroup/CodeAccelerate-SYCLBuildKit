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

# Restore build flags
if [ -n "${CONDA_BACKUP_CFLAGS:-}" ]; then
    export CFLAGS="$CONDA_BACKUP_CFLAGS"
    unset CONDA_BACKUP_CFLAGS
else
    unset CFLAGS
fi

if [ -n "${CONDA_BACKUP_CXXFLAGS:-}" ]; then
    export CXXFLAGS="$CONDA_BACKUP_CXXFLAGS"
    unset CONDA_BACKUP_CXXFLAGS
else
    unset CXXFLAGS
fi

if [ -n "${CONDA_BACKUP_LDFLAGS:-}" ]; then
    export LDFLAGS="$CONDA_BACKUP_LDFLAGS"
    unset CONDA_BACKUP_LDFLAGS
else
    unset LDFLAGS
fi

# Restore CMake args
if [ -n "${CONDA_BACKUP_CMAKE_ARGS:-}" ]; then
    export CMAKE_ARGS="$CONDA_BACKUP_CMAKE_ARGS"
    unset CONDA_BACKUP_CMAKE_ARGS
else
    unset CMAKE_ARGS
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
