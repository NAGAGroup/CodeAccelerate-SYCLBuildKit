# acpp-linux-64.cmake
# CMake toolchain file for acpp-toolchain_linux-64.
# Provides self-contained toolchain configuration for IDEs and direct
# cmake invocations (without needing the activation script).
#
# Usage:
#   cmake -DCMAKE_TOOLCHAIN_FILE=$CONDA_PREFIX/share/acpp/toolchain/acpp-linux-64.cmake ..
#
# When the activation script is sourced, CMAKE_ARGS already contains
# all these settings. This file is for cases where CMAKE_ARGS isn't used.

cmake_minimum_required(VERSION 3.18)

set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR x86_64)

# ── Resolve prefix ────────────────────────────────────────────────────────
if(DEFINED ENV{PREFIX} AND DEFINED ENV{SRC_DIR})
    set(_ACPP_PFX "$ENV{PREFIX}")       # inside conda-build/rattler-build
else()
    set(_ACPP_PFX "$ENV{CONDA_PREFIX}") # normal activation
endif()

# ── Compilers (triple-prefixed symlinks → clang/clang++) ─────────────────
set(CMAKE_C_COMPILER   "${_ACPP_PFX}/bin/x86_64-conda-linux-gnu-clang")
set(CMAKE_CXX_COMPILER "${_ACPP_PFX}/bin/x86_64-conda-linux-gnu-clang++")
set(CMAKE_LINKER       "${_ACPP_PFX}/bin/ld.lld")
set(CMAKE_AR           "${_ACPP_PFX}/bin/x86_64-conda-linux-gnu-ar")
set(CMAKE_NM           "${_ACPP_PFX}/bin/x86_64-conda-linux-gnu-nm")
set(CMAKE_RANLIB       "${_ACPP_PFX}/bin/x86_64-conda-linux-gnu-ranlib")
set(CMAKE_STRIP        "${_ACPP_PFX}/bin/x86_64-conda-linux-gnu-strip")
set(CMAKE_OBJDUMP      "${_ACPP_PFX}/bin/x86_64-conda-linux-gnu-objdump")
set(CMAKE_OBJCOPY      "${_ACPP_PFX}/bin/x86_64-conda-linux-gnu-objcopy")

# ── Target triple ─────────────────────────────────────────────────────────
set(CMAKE_C_COMPILER_TARGET   "x86_64-conda-linux-gnu")
set(CMAKE_CXX_COMPILER_TARGET "x86_64-conda-linux-gnu")

# ── Sysroot ───────────────────────────────────────────────────────────────
if(DEFINED ENV{CONDA_BUILD_SYSROOT})
    set(CMAKE_SYSROOT "$ENV{CONDA_BUILD_SYSROOT}")
else()
    set(CMAKE_SYSROOT "${_ACPP_PFX}/x86_64-conda-linux-gnu/sysroot")
endif()

# ── Find root paths ───────────────────────────────────────────────────────
# NEVER search sysroot for build tools (we want host-machine tools).
# BOTH for libraries/headers/packages (conda prefix AND sysroot searched).
set(CMAKE_FIND_ROOT_PATH "${_ACPP_PFX}" "${CMAKE_SYSROOT}")
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY BOTH)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE BOTH)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE BOTH)

# ── Include paths ─────────────────────────────────────────────────────────
# -isystem so conda headers don't generate warnings and take precedence
# over sysroot headers (per clang's search order rules).
set(CMAKE_C_FLAGS_INIT   "-isystem ${_ACPP_PFX}/include")
set(CMAKE_CXX_FLAGS_INIT "-isystem ${_ACPP_PFX}/include")

# ── Linker flags ──────────────────────────────────────────────────────────
set(_ACPP_RPATH_FLAGS
    "-Wl,-rpath,${_ACPP_PFX}/lib -Wl,-rpath-link,${_ACPP_PFX}/lib \
-L${_ACPP_PFX}/lib -fuse-ld=lld")
set(CMAKE_EXE_LINKER_FLAGS_INIT    "${_ACPP_RPATH_FLAGS}")
set(CMAKE_SHARED_LINKER_FLAGS_INIT "${_ACPP_RPATH_FLAGS}")
set(CMAKE_MODULE_LINKER_FLAGS_INIT "${_ACPP_RPATH_FLAGS}")

# ── Installation defaults ─────────────────────────────────────────────────
set(CMAKE_INSTALL_PREFIX "${_ACPP_PFX}" CACHE PATH "Install prefix")
set(CMAKE_INSTALL_LIBDIR "lib"          CACHE STRING "Library directory")
set(CMAKE_BUILD_TYPE     "Release"      CACHE STRING "Build type")

# ── AdaptiveCpp integration ───────────────────────────────────────────────
set(AdaptiveCpp_DIR "${_ACPP_PFX}/lib/cmake/AdaptiveCpp"
    CACHE PATH "AdaptiveCpp CMake config directory")

if(NOT DEFINED ACPP_TARGETS)
    if(DEFINED ENV{ACPP_TARGETS})
        set(ACPP_TARGETS "$ENV{ACPP_TARGETS}"
            CACHE STRING "AdaptiveCpp compilation targets")
    else()
        # "generic" = SSCP JIT. One binary covers CPU, CUDA, Level Zero,
        # OpenCL at runtime. This is the only flow we built — do NOT add
        # "omp" here, as that is a separate non-SSCP compilation flow.
        set(ACPP_TARGETS "generic"
            CACHE STRING "AdaptiveCpp compilation targets")
    endif()
endif()

message(STATUS "[acpp-linux-64.cmake] Prefix:        ${_ACPP_PFX}")
message(STATUS "[acpp-linux-64.cmake] Sysroot:       ${CMAKE_SYSROOT}")
message(STATUS "[acpp-linux-64.cmake] CXX:           ${CMAKE_CXX_COMPILER}")
message(STATUS "[acpp-linux-64.cmake] AdaptiveCpp:   ${AdaptiveCpp_DIR}")
message(STATUS "[acpp-linux-64.cmake] ACPP_TARGETS:  ${ACPP_TARGETS}")
