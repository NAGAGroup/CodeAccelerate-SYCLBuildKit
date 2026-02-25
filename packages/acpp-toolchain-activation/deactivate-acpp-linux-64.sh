#!/usr/bin/env bash
# deactivate-acpp-linux-64.sh
# Restores all variables to pre-activation state and removes .cfg files.

# ── Helper: restore from backup ───────────────────────────────────────────
_acpp_restore() {
    local var="$1"
    local bak="CONDA_BACKUP_ACPP_${var}"
    local val="${!bak:-}"

    if [ -z "${val}" ]; then
        unset "${var}" 2>/dev/null || true
    elif [ "${val}" = "__CONDA_ACPP_UNSET__" ]; then
        unset "${var}" 2>/dev/null || true
    else
        export "${var}=${val}"
    fi
    unset "${bak}" 2>/dev/null || true
}

# ── Restore all variables (reverse order of backup) ──────────────────────
_acpp_restore ACPP_CLANG
_acpp_restore ACPP_COMPILER_DIR
_acpp_restore ACPP_TARGETS
_acpp_restore OBJCOPY
_acpp_restore OBJDUMP
_acpp_restore LD
_acpp_restore STRIP
_acpp_restore RANLIB
_acpp_restore NM
_acpp_restore AR
_acpp_restore CONDA_BUILD_SYSROOT
_acpp_restore CMAKE_PREFIX_PATH
_acpp_restore CMAKE_ARGS
_acpp_restore DEBUG_CXXFLAGS
_acpp_restore DEBUG_CFLAGS
_acpp_restore LDFLAGS
_acpp_restore CPPFLAGS
_acpp_restore CXXFLAGS
_acpp_restore CFLAGS
_acpp_restore CXX
_acpp_restore CC

# ── Remove .cfg files written at activation time ──────────────────────────
# Use CONDA_PREFIX — at deactivation time this is still set to the
# environment being deactivated.
_ACPP_DEACT_PFX="${CONDA_PREFIX:-}"
if [ -n "${_ACPP_DEACT_PFX}" ]; then
    rm -f "${_ACPP_DEACT_PFX}/bin/clang++.cfg"
    rm -f "${_ACPP_DEACT_PFX}/bin/clang.cfg"
    rm -f "${_ACPP_DEACT_PFX}/bin/x86_64-conda-linux-gnu-clang++.cfg"
    rm -f "${_ACPP_DEACT_PFX}/bin/x86_64-conda-linux-gnu-clang.cfg"
fi

unset _ACPP_DEACT_PFX
unset -f _acpp_restore
