#!/bin/bash
# AdaptiveCPP conda package activation script
# The ~~ prefix ensures this runs AFTER other compiler activation scripts

# Determine prefix (build vs runtime)
if [ "${CONDA_BUILD:-0}" = "1" ]; then
    _ACPP_PREFIX="${BUILD_PREFIX}"
else
    _ACPP_PREFIX="${CONDA_PREFIX}"
fi

# Host triple (conda-forge convention)
_ACPP_CHOST="x86_64-conda-linux-gnu"

# =============================================================================
# Compiler configuration (CRITICAL SECTION)
# =============================================================================
# Backup existing values
if [ -n "${CC+x}" ]; then
    export CONDA_BACKUP_CC="${CC}"
fi
if [ -n "${CXX+x}" ]; then
    export CONDA_BACKUP_CXX="${CXX}"
    export CONDA_BACKUP_ACPP_CLANG="${ACPP_CLANG:-}"
fi

# Create symlinks
ln -sf "${_ACPP_PREFIX}/bin/clang++" "${_ACPP_PREFIX}/bin/${_ACPP_CHOST}-clang++"
ln -sf "${_ACPP_PREFIX}/bin/clang" "${_ACPP_PREFIX}/bin/${_ACPP_CHOST}-clang"
# Set compilers to triplet-prefixed symlinks (NOT acpp directly!)
export CC="${_ACPP_PREFIX}/bin/${_ACPP_CHOST}-clang"
export CXX="${_ACPP_PREFIX}/bin/${_ACPP_CHOST}-clang++"
export ACPP_CLANG="${CXX}"


# Create clang.cfg (using ${_ACPP_PREFIX} placeholders)
echo "--sysroot=${_ACPP_PREFIX}/x86_64-conda-linux-gnu/sysroot
-isystem ${_ACPP_PREFIX}/include/sycl
-isystem ${_ACPP_PREFIX}/include" > "$_ACPP_PREFIX/bin/${_ACPP_CHOST}-clang++.cfg"
echo "--sysroot=${_ACPP_PREFIX}/x86_64-conda-linux-gnu/sysroot" > "$_ACPP_PREFIX/bin/${_ACPP_CHOST}-clang.cfg"

# AdaptiveCPP-specific variables
export ACPP_CC="${CC}"
export ACPP_CXX="${CXX}"

# =============================================================================
# AdaptiveCPP runtime configuration
# =============================================================================
export ACPP_TARGETS="${ACPP_TARGETS:-generic}"
export ACPP_BACKENDS="${ACPP_BACKENDS:-auto}"  # Auto-detect at runtime

# =============================================================================
# Build flags (conda-forge pattern)
# =============================================================================
_ACPP_CFLAGS="-isystem ${_ACPP_PREFIX}/include"
_ACPP_CXXFLAGS="-isystem ${_ACPP_PREFIX}/include/sycl -isystem ${_ACPP_PREFIX}/include"
_ACPP_LDFLAGS="-Wl,-rpath,${_ACPP_PREFIX}/lib -L${_ACPP_PREFIX}/lib"

if [ -n "${CFLAGS+x}" ]; then
    export CONDA_BACKUP_CFLAGS="${CFLAGS}"
fi
if [ -n "${CXXFLAGS+x}" ]; then
    export CONDA_BACKUP_CXXFLAGS="${CXXFLAGS}"
fi
if [ -n "${LDFLAGS+x}" ]; then
    export CONDA_BACKUP_LDFLAGS="${LDFLAGS}"
fi

export CFLAGS="${_ACPP_CFLAGS}"
export CXXFLAGS="${_ACPP_CXXFLAGS}"
export LDFLAGS="${_ACPP_LDFLAGS}"

# # =============================================================================
# # CMake configuration
# # =============================================================================
# if [ -n "${CMAKE_ARGS+x}" ]; then
#     export CONDA_BACKUP_CMAKE_ARGS="${CMAKE_ARGS}"
# fi
#
# _CMAKE_ARGS="-DCMAKE_C_COMPILER=${CC}"
# _CMAKE_ARGS="${_CMAKE_ARGS} -DCMAKE_CXX_COMPILER=${CXX}"
# _CMAKE_ARGS="${_CMAKE_ARGS} -DAdaptiveCpp_ROOT=${_ACPP_PREFIX}"
#
# export CMAKE_ARGS="${_CMAKE_ARGS}${CMAKE_ARGS:+ }${CMAKE_ARGS:-}"

# =============================================================================
# Host/Build configuration (conda-forge convention)
# =============================================================================
if [ -n "${HOST+x}" ]; then
    export CONDA_BACKUP_HOST="${HOST}"
fi
if [ -n "${BUILD+x}" ]; then
    export CONDA_BACKUP_BUILD="${BUILD}"
fi

export HOST="${_ACPP_CHOST}"
export BUILD="${_ACPP_CHOST}"
export CONDA_TOOLCHAIN_HOST="${_ACPP_CHOST}"
export CONDA_TOOLCHAIN_BUILD="${_ACPP_CHOST}"

# =============================================================================
# Library paths
# =============================================================================
if [[ ":$LD_LIBRARY_PATH:" != *":${_ACPP_PREFIX}/lib:"* ]]; then
    if [ -n "${LD_LIBRARY_PATH+x}" ]; then
        export CONDA_BACKUP_LD_LIBRARY_PATH="${LD_LIBRARY_PATH}"
    fi
    export LD_LIBRARY_PATH="${_ACPP_PREFIX}/lib:${LD_LIBRARY_PATH:-}"
fi

# ============================================================================
# ACPP Config Env Vars
# ============================================================================
# Core AdaptiveCPP paths
export ACPP_PATH="${_ACPP_PREFIX}"
export ACPP_LIB_PATH="${_ACPP_PREFIX}/lib"
# CUDA paths (point to conda CUDA installation)
if [ -d "${_ACPP_PREFIX}/targets/x86_64-linux/lib" ]; then
    # CUDA from nvidia channel has this structure
    export ACPP_CUDA_LIB_PATH="${_ACPP_PREFIX}/targets/x86_64-linux/lib"
elif [ -d "${_ACPP_PREFIX}/lib64" ]; then
    # Some CUDA packages use lib64
    export ACPP_CUDA_LIB_PATH="${_ACPP_PREFIX}/lib64"
else
    # Fallback to standard lib
    export ACPP_CUDA_LIB_PATH="${_ACPP_PREFIX}/lib"
fi

# Set CUDA path (acpp uses this to find CUDA toolkit)
export ACPP_CUDA_PATH="${ACPP_PATH}"
# Ensure libraries can be found at runtime
if [[ ":$LD_LIBRARY_PATH:" != *":${ACPP_CUDA_LIB_PATH}:"* ]]; then
    export LD_LIBRARY_PATH="${ACPP_CUDA_LIB_PATH}${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
fi
if [[ ":$LD_LIBRARY_PATH:" != *":${ACPP_LIB_PATH}:"* ]]; then
    export LD_LIBRARY_PATH="${ACPP_LIB_PATH}${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
fi


# =============================================================================
# Cleanup temporary variables
# =============================================================================
unset _ACPP_PREFIX
unset _ACPP_CHOST
unset _ACPP_CFLAGS
unset _ACPP_CXXFLAGS
unset _ACPP_LDFLAGS
unset _CMAKE_ARGS
