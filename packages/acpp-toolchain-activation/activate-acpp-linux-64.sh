#!/usr/bin/env bash
# activate-acpp-linux-64.sh
#
# Sourced automatically on `conda activate` / `pixi run`.
# @VARIABLE@ tokens are replaced by build.sh at package build time.
# Dynamic paths use $CONDA_PREFIX resolved at activation time.

# ── Helper: save a variable for later restoration ─────────────────────────
_acpp_backup() {
    local var="$1"
    local bak="CONDA_BACKUP_ACPP_${var}"
    if [ -n "${!var+x}" ]; then
        export "${bak}=${!var}"
    else
        export "${bak}=__CONDA_ACPP_UNSET__"
    fi
}

# ── Resolve prefix ────────────────────────────────────────────────────────
# Inside conda-build/rattler-build: $PREFIX is the host prefix.
# Normal activation: $CONDA_PREFIX.
if [ -n "${SRC_DIR:-}" ] && [ -n "${PKG_NAME:-}" ]; then
    _ACPP_PFX="${PREFIX}"
    _ACPP_BUILD_MODE=1
else
    _ACPP_PFX="${CONDA_PREFIX}"
    _ACPP_BUILD_MODE=0
fi

_ACPP_SYSROOT="${_ACPP_PFX}/@CHOST@/sysroot"

# Warn if sysroot is missing
if [ ! -d "${_ACPP_SYSROOT}/usr/include" ]; then
    echo "WARNING [acpp-toolchain_linux-64]: sysroot not found at ${_ACPP_SYSROOT}" >&2
    echo "  Ensure sysroot_linux-64 >=2.28 is installed." >&2
fi

# ── Compiler paths ────────────────────────────────────────────────────────
# Use triple-prefixed names (symlinks to clang/clang++ installed by
# acpp-toolchain base package). This follows conda-forge convention where
# CC is set to the long name like x86_64-conda-linux-gnu-cc.
_ACPP_CC="${_ACPP_PFX}/bin/@CHOST@-clang"
_ACPP_CXX="${_ACPP_PFX}/bin/@CHOST@-clang++"
_ACPP_LD="${_ACPP_PFX}/bin/ld.lld"
_ACPP_AR="${_ACPP_PFX}/bin/@CHOST@-ar"
_ACPP_NM="${_ACPP_PFX}/bin/@CHOST@-nm"
_ACPP_RANLIB="${_ACPP_PFX}/bin/@CHOST@-ranlib"
_ACPP_STRIP="${_ACPP_PFX}/bin/@CHOST@-strip"
_ACPP_OBJDUMP="${_ACPP_PFX}/bin/@CHOST@-objdump"
_ACPP_OBJCOPY="${_ACPP_PFX}/bin/@CHOST@-objcopy"

# ── Sysroot and target flags ──────────────────────────────────────────────
_ACPP_SYSROOT_FLAGS="--sysroot=${_ACPP_SYSROOT} --target=@CHOST@"

# ── Full flag sets ────────────────────────────────────────────────────────
if [ "${_ACPP_BUILD_MODE}" -eq 1 ]; then
    # Inside conda-build/rattler-build: use $PREFIX for include/lib paths.
    # Add debug prefix maps for reproducible builds.
    _ACPP_CFLAGS="@CFLAGS@ ${_ACPP_SYSROOT_FLAGS} -isystem ${PREFIX}/include \
-fdebug-prefix-map=${SRC_DIR}=/usr/local/src/conda/${PKG_NAME}-${PKG_VERSION} \
-fdebug-prefix-map=${PREFIX}=/usr/local/src/conda-prefix"
    _ACPP_CXXFLAGS="@CXXFLAGS@ ${_ACPP_SYSROOT_FLAGS} -isystem ${PREFIX}/include \
-fdebug-prefix-map=${SRC_DIR}=/usr/local/src/conda/${PKG_NAME}-${PKG_VERSION} \
-fdebug-prefix-map=${PREFIX}=/usr/local/src/conda-prefix"
    _ACPP_CPPFLAGS="@CPPFLAGS@ -isystem ${PREFIX}/include"
    _ACPP_LDFLAGS="@LDFLAGS@ --sysroot=${_ACPP_SYSROOT} \
-Wl,-rpath,${PREFIX}/lib -Wl,-rpath-link,${PREFIX}/lib -L${PREFIX}/lib \
-fuse-ld=lld"
    _ACPP_DEBUG_CFLAGS="@DEBUG_CFLAGS@ ${_ACPP_SYSROOT_FLAGS} -isystem ${PREFIX}/include"
    _ACPP_DEBUG_CXXFLAGS="@DEBUG_CXXFLAGS@ ${_ACPP_SYSROOT_FLAGS} -isystem ${PREFIX}/include"
    _ACPP_CMAKE_PFX_PATH="${PREFIX};${_ACPP_PFX}/@CHOST@/sysroot/usr"
    _ACPP_INSTALL_PFX="${PREFIX}"
else
    # Normal environment activation
    _ACPP_CFLAGS="@CFLAGS@ ${_ACPP_SYSROOT_FLAGS} -isystem ${CONDA_PREFIX}/include"
    _ACPP_CXXFLAGS="@CXXFLAGS@ ${_ACPP_SYSROOT_FLAGS} -isystem ${CONDA_PREFIX}/include"
    _ACPP_CPPFLAGS="@CPPFLAGS@ -isystem ${CONDA_PREFIX}/include"
    _ACPP_LDFLAGS="@LDFLAGS@ --sysroot=${_ACPP_SYSROOT} \
-Wl,-rpath,${CONDA_PREFIX}/lib -Wl,-rpath-link,${CONDA_PREFIX}/lib \
-L${CONDA_PREFIX}/lib -fuse-ld=lld"
    _ACPP_DEBUG_CFLAGS="@DEBUG_CFLAGS@ ${_ACPP_SYSROOT_FLAGS} -isystem ${CONDA_PREFIX}/include"
    _ACPP_DEBUG_CXXFLAGS="@DEBUG_CXXFLAGS@ ${_ACPP_SYSROOT_FLAGS} -isystem ${CONDA_PREFIX}/include"
    _ACPP_CMAKE_PFX_PATH="${CONDA_PREFIX};${_ACPP_PFX}/@CHOST@/sysroot/usr"
    _ACPP_INSTALL_PFX="${CONDA_PREFIX}"
fi

# ── CMAKE_ARGS construction ───────────────────────────────────────────────
_ACPP_CMAKE_ARGS=""
_ACPP_CMAKE_ARGS="${_ACPP_CMAKE_ARGS} -DCMAKE_C_COMPILER=${_ACPP_CC}"
_ACPP_CMAKE_ARGS="${_ACPP_CMAKE_ARGS} -DCMAKE_CXX_COMPILER=${_ACPP_CXX}"
_ACPP_CMAKE_ARGS="${_ACPP_CMAKE_ARGS} -DCMAKE_LINKER=${_ACPP_LD}"
_ACPP_CMAKE_ARGS="${_ACPP_CMAKE_ARGS} -DCMAKE_AR=${_ACPP_AR}"
_ACPP_CMAKE_ARGS="${_ACPP_CMAKE_ARGS} -DCMAKE_NM=${_ACPP_NM}"
_ACPP_CMAKE_ARGS="${_ACPP_CMAKE_ARGS} -DCMAKE_RANLIB=${_ACPP_RANLIB}"
_ACPP_CMAKE_ARGS="${_ACPP_CMAKE_ARGS} -DCMAKE_STRIP=${_ACPP_STRIP}"
_ACPP_CMAKE_ARGS="${_ACPP_CMAKE_ARGS} -DCMAKE_OBJDUMP=${_ACPP_OBJDUMP}"
_ACPP_CMAKE_ARGS="${_ACPP_CMAKE_ARGS} -DCMAKE_OBJCOPY=${_ACPP_OBJCOPY}"
_ACPP_CMAKE_ARGS="${_ACPP_CMAKE_ARGS} -DCMAKE_SYSROOT=${_ACPP_SYSROOT}"
_ACPP_CMAKE_ARGS="${_ACPP_CMAKE_ARGS} -DCMAKE_BUILD_TYPE=Release"
_ACPP_CMAKE_ARGS="${_ACPP_CMAKE_ARGS} -DCMAKE_INSTALL_PREFIX=${_ACPP_INSTALL_PFX}"
_ACPP_CMAKE_ARGS="${_ACPP_CMAKE_ARGS} -DCMAKE_INSTALL_LIBDIR=lib"
_ACPP_CMAKE_ARGS="${_ACPP_CMAKE_ARGS} -DCMAKE_FIND_ROOT_PATH=${_ACPP_CMAKE_PFX_PATH}"
_ACPP_CMAKE_ARGS="${_ACPP_CMAKE_ARGS} -DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER"
_ACPP_CMAKE_ARGS="${_ACPP_CMAKE_ARGS} -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=BOTH"
_ACPP_CMAKE_ARGS="${_ACPP_CMAKE_ARGS} -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=BOTH"
_ACPP_CMAKE_ARGS="${_ACPP_CMAKE_ARGS} -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=BOTH"
_ACPP_CMAKE_ARGS="${_ACPP_CMAKE_ARGS} -DAdaptiveCpp_DIR=${_ACPP_PFX}/lib/cmake/AdaptiveCpp"

# ── Save current values for deactivation ─────────────────────────────────
_acpp_backup CC
_acpp_backup CXX
_acpp_backup CFLAGS
_acpp_backup CXXFLAGS
_acpp_backup CPPFLAGS
_acpp_backup LDFLAGS
_acpp_backup DEBUG_CFLAGS
_acpp_backup DEBUG_CXXFLAGS
_acpp_backup CMAKE_ARGS
_acpp_backup CMAKE_PREFIX_PATH
_acpp_backup CONDA_BUILD_SYSROOT
_acpp_backup AR
_acpp_backup NM
_acpp_backup RANLIB
_acpp_backup STRIP
_acpp_backup LD
_acpp_backup OBJDUMP
_acpp_backup OBJCOPY
_acpp_backup ACPP_TARGETS
_acpp_backup ACPP_COMPILER_DIR
_acpp_backup ACPP_CLANG

# ── Export environment variables ──────────────────────────────────────────
export CC="${_ACPP_CC}"
export CXX="${_ACPP_CXX}"
export CFLAGS="${_ACPP_CFLAGS}"
export CXXFLAGS="${_ACPP_CXXFLAGS}"
export CPPFLAGS="${_ACPP_CPPFLAGS}"
export LDFLAGS="${_ACPP_LDFLAGS}"
export DEBUG_CFLAGS="${_ACPP_DEBUG_CFLAGS}"
export DEBUG_CXXFLAGS="${_ACPP_DEBUG_CXXFLAGS}"
export AR="${_ACPP_AR}"
export NM="${_ACPP_NM}"
export RANLIB="${_ACPP_RANLIB}"
export STRIP="${_ACPP_STRIP}"
export LD="${_ACPP_LD}"
export OBJDUMP="${_ACPP_OBJDUMP}"
export OBJCOPY="${_ACPP_OBJCOPY}"
export CMAKE_ARGS="${_ACPP_CMAKE_ARGS}"
export CMAKE_PREFIX_PATH="${_ACPP_CMAKE_PFX_PATH}"
export CONDA_BUILD_SYSROOT="${_ACPP_SYSROOT}"

# ── AdaptiveCpp-specific variables ───────────────────────────────────────
# Default ACPP_TARGETS if not already set by user.
# "generic" = SSCP JIT: a single binary dispatches at runtime to
# CPU (via libomp), CUDA, Level Zero, OpenCL — whatever drivers are present.
# This is the ONLY compilation flow we built. "omp" as a target would
# refer to a separate, non-SSCP explicit-multipass CPU flow that we
# did NOT enable. Do not set "generic;omp" — just "generic".
if [ -z "${ACPP_TARGETS:-}" ]; then
    export ACPP_TARGETS="generic"
fi

# Point acpp driver to our clang installation
export ACPP_COMPILER_DIR="${_ACPP_PFX}"
export ACPP_CLANG="${_ACPP_PFX}/bin/clang++"

# ── Write clang .cfg files ────────────────────────────────────────────────
# .cfg files are loaded by clang on every invocation, regardless of whether
# the caller set CFLAGS/CXXFLAGS. This ensures --sysroot is applied even
# when acpp internally invokes clang++ with its own constructed command line.
#
# Written at activation time (not install time) because they contain
# $CONDA_PREFIX-dependent absolute paths. Removed on deactivation.
# Post-link scripts are NOT used (not supported in rattler-build/pixi).

_ACPP_CFG_CONTENT="--target=@CHOST@
--sysroot=${_ACPP_SYSROOT}
-isystem ${_ACPP_INSTALL_PFX}/include
-isystem ${_ACPP_PFX}/@CHOST@/include/c++/13
-isystem ${_ACPP_PFX}/@CHOST@/include/c++/13/@CHOST@"

# clang++ cfg
printf '%s\n' "${_ACPP_CFG_CONTENT}" > "${_ACPP_PFX}/bin/clang++.cfg"
# Triple-named variant (same content, clang resolves cfg by invocation name)
printf '%s\n' "${_ACPP_CFG_CONTENT}" > "${_ACPP_PFX}/bin/@CHOST@-clang++.cfg"

# clang (C compiler) cfg — same but without C++ stdlib include lines
_ACPP_C_CFG_CONTENT="--target=@CHOST@
--sysroot=${_ACPP_SYSROOT}
-isystem ${_ACPP_INSTALL_PFX}/include"
printf '%s\n' "${_ACPP_C_CFG_CONTENT}" > "${_ACPP_PFX}/bin/clang.cfg"
printf '%s\n' "${_ACPP_C_CFG_CONTENT}" > "${_ACPP_PFX}/bin/@CHOST@-clang.cfg"

# ── Debug output ──────────────────────────────────────────────────────────
if [ "${ACPP_TOOLCHAIN_DEBUG:-0}" = "1" ]; then
    echo "╔══════════════════════════════════════════════════════════════════╗"
    echo "║  acpp-toolchain_linux-64 activated                              ║"
    echo "╠══════════════════════════════════════════════════════════════════╣"
    printf "║ CC           = %s\n" "${CC}"
    printf "║ CXX          = %s\n" "${CXX}"
    printf "║ LD           = %s\n" "${LD}"
    printf "║ SYSROOT      = %s\n" "${CONDA_BUILD_SYSROOT}"
    printf "║ ACPP_TARGETS = %s\n" "${ACPP_TARGETS}"
    printf "║ CFLAGS       = %s\n" "${CFLAGS}"
    printf "║ LDFLAGS      = %s\n" "${LDFLAGS}"
    printf "║ cfg files    = %s/bin/clang++.cfg\n" "${_ACPP_PFX}"
    echo "╚══════════════════════════════════════════════════════════════════╝"
fi

# ── Cleanup temporaries ───────────────────────────────────────────────────
unset _ACPP_PFX _ACPP_BUILD_MODE _ACPP_SYSROOT _ACPP_SYSROOT_FLAGS
unset _ACPP_CC _ACPP_CXX _ACPP_LD _ACPP_AR _ACPP_NM _ACPP_RANLIB
unset _ACPP_STRIP _ACPP_OBJDUMP _ACPP_OBJCOPY
unset _ACPP_CFLAGS _ACPP_CXXFLAGS _ACPP_CPPFLAGS _ACPP_LDFLAGS
unset _ACPP_DEBUG_CFLAGS _ACPP_DEBUG_CXXFLAGS
unset _ACPP_CMAKE_ARGS _ACPP_CMAKE_PFX_PATH _ACPP_INSTALL_PFX
unset _ACPP_CFG_CONTENT _ACPP_C_CFG_CONTENT
unset -f _acpp_backup
