# AdaptiveCPP Migration Plan: Upstream LLVM Integration

**Version**: 1.0  
**Date**: January 2026  
**Status**: Implementation Ready  

---

## Executive Summary

This document provides a complete implementation plan for migrating from Intel DPC++/SYCL to AdaptiveCPP built into upstream LLVM. This is a **complete ecosystem replacement**, not a co-location strategy.

**Key Architectural Decisions**:
- **LLVM Source**: Upstream `llvm/llvm-project` (LLVM 18.1.8), NOT `intel/llvm`
- **Build Method**: AdaptiveCPP linked into LLVM tools using `LLVM_ADAPTIVECPP_LINK_INTO_TOOLS=ON`
- **Target**: Generic SSCP only (JIT compilation at runtime)
- **Workflow**: Package-level `rattler-build` configuration (`cd packages/adaptivecpp && pixi build`)

---

## 1. Architecture Overview

### 1.1 Ecosystem Replacement Strategy

```
OLD (Intel DPC++):
    Intel LLVM Fork → Intel SYCL Runtime → DPC++ Toolchain

NEW (AdaptiveCPP):
    Upstream LLVM → AdaptiveCPP SYCL Runtime → acpp Toolchain
```

**What Changes**:
- LLVM source: `https://github.com/llvm/llvm-project.git` (branch: `release/18.x`)
- SYCL implementation: AdaptiveCPP
- Compiler driver: `acpp` (with `clang++` symlink for IDE compatibility)
- Compilation mode: Generic SSCP (JIT at runtime)

**What Stays**:
- Conda packaging structure (3 outputs: libs, devel, toolkit)
- Activation script patterns (following conda-forge conventions)
- Build optimization (marker file for multi-output recipes)

### 1.2 Build Architecture

```
┌─────────────────────────────────────────────────────────┐
│           AdaptiveCPP SYCL Toolchain                    │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  User SYCL Code (SYCL 2020)                            │
│         ↓                                              │
│  acpp compiler driver (Python)                         │
│         ↓                                              │
│  Clang++ (with AdaptiveCPP passes LINKED IN)          │
│         ↓                                              │
│  LLVM Backend (Upstream LLVM 18.x)                    │
│         ↓                                              │
│  Generic IR → JIT compilation at runtime              │
│         ↓                                              │
│  Execution (CPU/GPU via OpenMP/CUDA/OpenCL)           │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

**Key Feature**: AdaptiveCPP compiler passes are **linked directly into** `clang`, `opt`, and other LLVM tools, not loaded as plugins.

### 1.3 Generic SSCP Compilation Model

**Generic Target** (`ACPP_TARGETS=generic`):
- Compiles to portable intermediate representation (IR)
- No GPU-specific ahead-of-time compilation
- JIT compilation at first kernel execution
- Single binary works on multiple GPU types (CUDA, OpenCL, CPU)

**Trade-offs**:
- ✅ Fast builds (no GPU precompilation)
- ✅ Portable binaries
- ✅ No need to specify GPU architecture
- ⚠️ Slower first kernel launch (JIT overhead, typically <1 second)
- ⚠️ Cannot use GPU-specific intrinsics

---

## 2. Package Structure

### 2.1 Three Conda Packages

#### Package 1: `naga-adaptivecpp-toolkit-libs` (Runtime)

**Purpose**: Minimal runtime libraries for deployed applications

**Size**: ~50-80 MB

**Files**:
```
lib/libacpp_runtime.so*
lib/libacpp_common.so*
lib/libhipSYCL_rt.so*           # Legacy name compatibility
lib/libOpenSYCL_rt.so*          # Legacy name compatibility
lib/hipSYCL/libkernel-*.bc      # Bitcode for JIT compilation
lib/hipSYCL/libkernel-sscp-*.bc
```

**Dependencies**:
- `boost-cpp >=1.84` (threading, fiber context)
- Standard library (`libstdc++`)

---

#### Package 2: `naga-adaptivecpp-toolkit-devel` (Development)

**Purpose**: Headers and CMake configs for compiling SYCL code

**Size**: ~5-10 MB

**Files**:
```
include/sycl/sycl.hpp                      # Main SYCL 2020 header
include/sycl/detail/**                     # SYCL implementation details
include/CL/sycl.hpp                        # OpenCL SYCL compatibility
include/hipSYCL/**                         # Legacy API compatibility
lib/cmake/AdaptiveCpp/AdaptiveCppConfig.cmake
lib/cmake/AdaptiveCpp/AdaptiveCppTargets.cmake
lib/cmake/hipSYCL/**                       # Legacy CMake compatibility
lib/pkgconfig/AdaptiveCpp.pc
```

**Dependencies**:
- `naga-adaptivecpp-toolkit-libs` (exact version pin)
- `boost-cpp >=1.84` (headers)

---

#### Package 3: `naga-adaptivecpp-toolkit` (Full Toolkit)

**Purpose**: Complete compiler toolchain for developers

**Size**: ~300-500 MB (includes full LLVM toolchain)

**Files**:
```
bin/acpp                                   # Compiler driver (Python)
bin/acpp-info                              # System info utility
bin/clang*                                 # Clang with AdaptiveCPP passes
bin/clang++                                # Symlink → acpp
bin/x86_64-conda-linux-gnu-clang++         # Symlink → acpp (for IDEs)
bin/clang.cfg                              # Clang config for IDE tooling
bin/opt                                    # LLVM optimizer
bin/llc                                    # LLVM compiler
bin/llvm-link                              # LLVM linker
bin/llvm-as                                # LLVM assembler
libexec/acpp/**                            # Helper tools
share/acpp/**                              # Documentation
etc/conda/activate.d/~~activate-acpp.sh    # Activation script
etc/conda/deactivate.d/~~deactivate-acpp.sh
```

**Dependencies**:
- `naga-adaptivecpp-toolkit-devel` (exact version pin)
- `python >=3.10` (for `acpp` driver script)

---

### 2.2 Package Dependencies

```
naga-adaptivecpp-toolkit (full)
  ├─ depends: naga-adaptivecpp-toolkit-devel (exact version)
  └─ depends: python >=3.10

naga-adaptivecpp-toolkit-devel
  ├─ depends: naga-adaptivecpp-toolkit-libs (exact version)
  └─ depends: boost-cpp >=1.84

naga-adaptivecpp-toolkit-libs
  └─ depends: boost-cpp >=1.84
```

---

## 3. Build Configuration

### 3.1 Complete CMake Configuration

```bash
cmake -S llvm-project/llvm -B llvm-project/build \
    -GNinja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="$PREFIX" \
    -DCMAKE_C_COMPILER="clang" \
    -DCMAKE_CXX_COMPILER="clang++" \
    -DCMAKE_C_COMPILER_LAUNCHER=ccache \
    -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
    \
    # LLVM Core Configuration
    -DLLVM_TARGETS_TO_BUILD="X86;NVPTX;AMDGPU" \
    -DLLVM_ENABLE_PROJECTS="clang;openmp;lld" \
    -DLLVM_BUILD_LLVM_DYLIB=ON \
    -DLLVM_LINK_LLVM_DYLIB=ON \
    -DLLVM_PARALLEL_LINK_JOBS="${CPU_COUNT}" \
    \
    # AdaptiveCPP Integration (CRITICAL)
    -DLLVM_EXTERNAL_PROJECTS=AdaptiveCpp \
    -DLLVM_EXTERNAL_ADAPTIVECPP_SOURCE_DIR="llvm-project/AdaptiveCpp" \
    -DLLVM_ADAPTIVECPP_LINK_INTO_TOOLS=ON \
    \
    # AdaptiveCPP Generic SSCP Configuration
    -DACPP_TARGETS=generic \
    -DACPP_COMPILER_FEATURE_PROFILE=full \
    -DWITH_SSCP_COMPILER=ON \
    -DWITH_ACCELERATED_CPU=ON \
    -DWITH_STDPAR=ON
```

### 3.2 CMake Flags Reference

#### LLVM Core Flags

| Flag | Value | Purpose |
|------|-------|---------|
| `LLVM_TARGETS_TO_BUILD` | `X86;NVPTX;AMDGPU` | CPU + NVIDIA/AMD GPU backends |
| `LLVM_ENABLE_PROJECTS` | `clang;openmp;lld` | Required LLVM components |
| `LLVM_BUILD_LLVM_DYLIB` | `ON` | Shared LLVM library (required for AdaptiveCPP) |
| `LLVM_LINK_LLVM_DYLIB` | `ON` | Link tools against shared lib (reduces size) |
| `LLVM_PARALLEL_LINK_JOBS` | `${CPU_COUNT}` | Control RAM usage during linking |

#### AdaptiveCPP Integration Flags (CRITICAL)

| Flag | Value | Purpose |
|------|-------|---------|
| `LLVM_EXTERNAL_PROJECTS` | `AdaptiveCpp` | Register AdaptiveCPP with LLVM build system |
| `LLVM_EXTERNAL_ADAPTIVECPP_SOURCE_DIR` | `path/to/AdaptiveCpp` | AdaptiveCPP source location |
| `LLVM_ADAPTIVECPP_LINK_INTO_TOOLS` | `ON` | **Links compiler passes into clang/opt** (key feature!) |

#### AdaptiveCPP Configuration Flags

| Flag | Value | Purpose |
|------|-------|---------|
| `ACPP_TARGETS` | `generic` | JIT compilation (no GPU-specific precompilation) |
| `ACPP_COMPILER_FEATURE_PROFILE` | `full` | Enable all compiler features |
| `WITH_SSCP_COMPILER` | `ON` | Enable Single Source Compiler Platform |
| `WITH_ACCELERATED_CPU` | `ON` | CPU backend support via OpenMP |
| `WITH_STDPAR` | `ON` | C++17 parallel algorithms support |

#### Backends NOT Enabled

These are implicitly OFF (generic target handles them via JIT):
- `WITH_CUDA_BACKEND`: Generic handles CUDA
- `WITH_HIP_BACKEND`: Generic handles HIP
- `WITH_OPENCL_BACKEND`: Generic handles OpenCL

---

## 4. IDE Tooling Compatibility (clangd Support)

### 4.1 Problem Statement

- IDE tooling (clangd, clang-tidy, etc.) expects standard compiler names like `clang++`
- AdaptiveCPP uses custom compiler driver `acpp`
- Without symlinks, IDEs cannot find SYCL headers or perform code analysis

### 4.2 Solution: Symlinks + Configuration File

#### Symlinks to Create

```bash
# In $PREFIX/bin/:
clang++                          → acpp
x86_64-conda-linux-gnu-clang++   → acpp
```

**Rationale**:
- `clang++` symlink: General IDE compatibility
- `${BUILD_TRIPLET}-clang++` symlink: Conda-forge convention, used by activation scripts

#### clang.cfg File

**Location**: `$PREFIX/bin/clang.cfg`

**Content**:
```bash
# Clang configuration for conda environment
# Used by clangd and other tooling

# Point to conda sysroot
--sysroot=@CONDA_PREFIX@/x86_64-conda-linux-gnu/sysroot

# Include SYCL headers
-isystem @CONDA_PREFIX@/include/sycl
-isystem @CONDA_PREFIX@/include

# Standard library includes
-isystem @CONDA_PREFIX@/x86_64-conda-linux-gnu/sysroot/usr/include/c++/v1
-isystem @CONDA_PREFIX@/x86_64-conda-linux-gnu/sysroot/usr/include
```

**Note**: `@CONDA_PREFIX@` is replaced by conda at activation time with actual environment path.

### 4.3 Implementation in build.sh

Add this section after main install, before creating build marker:

```bash
# ============================================================================
# Clangd/Tooling Compatibility
# ============================================================================
echo "Creating clangd compatibility symlinks and config..."

BUILD_TRIPLET="${BUILD:-x86_64-conda-linux-gnu}"

# Create symlinks
ln -sf acpp "$PREFIX/bin/clang++"
ln -sf acpp "$PREFIX/bin/${BUILD_TRIPLET}-clang++"

# Create clang.cfg
cat > "$PREFIX/bin/clang.cfg" << 'EOF'
--sysroot=@CONDA_PREFIX@/x86_64-conda-linux-gnu/sysroot
-isystem @CONDA_PREFIX@/include/sycl
-isystem @CONDA_PREFIX@/include
-isystem @CONDA_PREFIX@/x86_64-conda-linux-gnu/sysroot/usr/include/c++/v1
-isystem @CONDA_PREFIX@/x86_64-conda-linux-gnu/sysroot/usr/include
EOF

echo "Clangd compatibility setup complete."
```

---

## 5. Activation Script Requirements

### 5.1 CRITICAL: CXX Environment Variable

**MUST** set `CXX` to the **triplet-prefixed symlink**, not `acpp` or plain `clang++`:

```bash
export CXX="${_ACPP_PREFIX}/bin/${_ACPP_CHOST}-clang++"
```

**Rationale**:
- Follows conda-forge convention for cross-compilation support
- Ensures build systems find the correct compiler with proper sysroot
- `acpp` would work but breaks conda integration patterns
- Plain `clang++` works but doesn't carry triplet information

### 5.2 Complete Activation Script

**File**: `recipe/scripts/activate.sh`  
**Installed to**: `$PREFIX/etc/conda/activate.d/~~activate-acpp.sh`

```bash
#!/bin/bash
# AdaptiveCPP conda package activation script
# The ~~ prefix ensures this runs AFTER other compiler activation scripts

# Determine prefix (build vs runtime)
if [ "${CONDA_BUILD:-0}" = "1" ]; then
    _ACPP_PREFIX="${PREFIX}"
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
fi

# Set compilers to triplet-prefixed symlinks (NOT acpp directly!)
export CC="${_ACPP_PREFIX}/bin/${_ACPP_CHOST}-clang"
export CXX="${_ACPP_PREFIX}/bin/${_ACPP_CHOST}-clang++"

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

export CFLAGS="${_ACPP_CFLAGS}${CFLAGS:+ }${CFLAGS:-}"
export CXXFLAGS="${_ACPP_CXXFLAGS}${CXXFLAGS:+ }${CXXFLAGS:-}"
export LDFLAGS="${_ACPP_LDFLAGS}${LDFLAGS:+ }${LDFLAGS:-}"

# =============================================================================
# CMake configuration
# =============================================================================
if [ -n "${CMAKE_ARGS+x}" ]; then
    export CONDA_BACKUP_CMAKE_ARGS="${CMAKE_ARGS}"
fi

_CMAKE_ARGS="-DCMAKE_C_COMPILER=${CC}"
_CMAKE_ARGS="${_CMAKE_ARGS} -DCMAKE_CXX_COMPILER=${CXX}"
_CMAKE_ARGS="${_CMAKE_ARGS} -DAdaptiveCpp_ROOT=${_ACPP_PREFIX}"

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

# =============================================================================
# Cleanup temporary variables
# =============================================================================
unset _ACPP_PREFIX
unset _ACPP_CHOST
unset _ACPP_CFLAGS
unset _ACPP_CXXFLAGS
unset _ACPP_LDFLAGS
unset _CMAKE_ARGS
```

### 5.3 Deactivation Script

**File**: `recipe/scripts/deactivate.sh`  
**Installed to**: `$PREFIX/etc/conda/deactivate.d/~~deactivate-acpp.sh`

```bash
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
```

---

## 6. Source Structure

### 6.1 Directory Layout

```
packages/adaptivecpp/
├── llvm-project/              # NEW: Git submodule (upstream LLVM)
│   ├── llvm/                 # LLVM core
│   ├── clang/                # Clang compiler
│   ├── openmp/               # OpenMP runtime
│   ├── lld/                  # Linker
│   ├── AdaptiveCpp/          # NEW: Nested git submodule
│   │   ├── CMakeLists.txt
│   │   ├── src/
│   │   ├── include/
│   │   └── ...
│   └── build/                # Build directory (persistent, gitignored)
│       └── .build_complete   # Marker file for multi-output optimization
├── recipe/
│   ├── recipe.yaml           # Rattler-build manifest
│   ├── variants.yaml         # Build matrix configuration
│   └── scripts/
│       ├── build.sh          # Main build script
│       ├── activate.sh       # Conda activation
│       └── deactivate.sh     # Conda deactivation
├── devel/
│   ├── pixi.toml
│   └── recipe -> ../recipe   # Symlink
├── libs/
│   ├── pixi.toml
│   └── recipe -> ../recipe   # Symlink
├── toolkit/
│   ├── pixi.toml
│   └── recipe -> ../recipe   # Symlink
├── src/                      # Dummy source (rattler-build requirement)
│   ├── LICENSE
│   └── README.md
├── output/                   # Built .conda packages
├── pixi.toml                 # Package workspace config
├── pixi.lock
└── .gitignore
```

### 6.2 Git Submodule Configuration

**Level 1: Upstream LLVM**

```bash
cd packages/adaptivecpp

# Remove old standalone submodule (if exists)
git submodule deinit repo || true
git rm repo || true
rm -rf .git/modules/repo

# Add upstream LLVM
git submodule add -b release/18.x \
    https://github.com/llvm/llvm-project.git \
    llvm-project
```

**Level 2: AdaptiveCPP (nested inside LLVM)**

```bash
cd packages/adaptivecpp/llvm-project

# Add AdaptiveCPP as nested submodule
git submodule add -b develop \
    https://github.com/AdaptiveCpp/AdaptiveCpp.git \
    AdaptiveCpp

cd ../..
git add .gitmodules packages/adaptivecpp
git commit -m "Add upstream LLVM + AdaptiveCPP submodules"
```

**Version Pinning**:

```bash
# Pin LLVM to specific release
cd packages/adaptivecpp/llvm-project
git checkout llvmorg-18.1.8
cd ..
git add llvm-project

# Pin AdaptiveCPP to specific version (optional)
cd llvm-project/AdaptiveCpp
git checkout v24.06.0
cd ../..
git add llvm-project
```

### 6.3 Initialization for Builds

**Before first build**:

```bash
cd packages/adaptivecpp

# Initialize both LLVM and AdaptiveCPP
git submodule update --init --recursive llvm-project

# Verify
ls llvm-project/llvm/CMakeLists.txt          # LLVM present
ls llvm-project/AdaptiveCpp/CMakeLists.txt   # AdaptiveCPP present
```

---

## 7. rattler-build Files Specification

### 7.1 recipe.yaml

**File**: `packages/adaptivecpp/recipe/recipe.yaml`

```yaml
schema_version: 1

context:
  name: naga-adaptivecpp-toolkit
  version: "2026.2.0"

package:
  name: ${{ name }}
  version: ${{ version }}

source:
  - path: ../src  # Dummy source (actual source in submodules)

build:
  number: 0
  skip:
    - win
    - osx
  script: recipe/scripts/build.sh

requirements:
  build:
    - ${{ compiler('c') }}      # clang from variants
    - ${{ compiler('cxx') }}    # clangxx from variants
    - ${{ stdlib('c') }}
    - cmake >=3.24
    - ninja >=1.12
    - python >=3.10
    - git
    - ccache
    - lld >=18
  host:
    - ${{ stdlib('c') }}
    - boost-cpp >=1.84
    - python >=3.10

outputs:
  # Output 1: Runtime libraries
  - package:
      name: ${{ name }}-libs
      version: ${{ version }}
    
    build:
      script: recipe/scripts/build.sh
      run_exports:
        - ${{ pin_subpackage(name ~ '-libs', max_pin='x.x') }}
    
    requirements:
      build:
        - ${{ compiler('c') }}
        - ${{ compiler('cxx') }}
      host:
        - ${{ stdlib('c') }}
        - boost-cpp >=1.84
      run:
        - ${{ stdlib('c') }}
        - boost-cpp >=1.84
    
    files:
      include:
        - lib/libacpp*.so*
        - lib/libhipSYCL*.so*
        - lib/libOpenSYCL*.so*
        - lib/hipSYCL/**
      exclude:
        - lib/*.a
    
    tests:
      - script:
          - test -f $PREFIX/lib/libacpp_runtime.so

  # Output 2: Development headers
  - package:
      name: ${{ name }}-devel
      version: ${{ version }}
    
    build:
      script: recipe/scripts/build.sh
    
    requirements:
      host:
        - ${{ stdlib('c') }}
      run:
        - ${{ pin_subpackage(name ~ '-libs', exact=True) }}
        - boost-cpp >=1.84
    
    files:
      include:
        - include/sycl/**
        - include/CL/**
        - include/hipSYCL/**
        - lib/cmake/AdaptiveCpp/**
        - lib/cmake/hipSYCL/**
        - lib/pkgconfig/*.pc
    
    tests:
      - script:
          - test -f $PREFIX/include/sycl/sycl.hpp
          - test -d $PREFIX/lib/cmake/AdaptiveCpp

  # Output 3: Full toolkit
  - package:
      name: ${{ name }}
      version: ${{ version }}
    
    build:
      script: recipe/scripts/build.sh
    
    requirements:
      host:
        - ${{ stdlib('c') }}
      run:
        - ${{ pin_subpackage(name ~ '-devel', exact=True) }}
        - python >=3.10
    
    files:
      include:
        - bin/acpp*
        - bin/clang*              # Includes clang++ symlink
        - bin/clang.cfg           # Clang config for IDEs
        - bin/*-clang*            # Triplet-prefixed symlinks
        - bin/opt
        - bin/llc
        - bin/llvm-link
        - bin/llvm-as
        - libexec/acpp/**
        - share/acpp/**
        - etc/conda/activate.d/**
        - etc/conda/deactivate.d/**
    
    tests:
      - script:
          - acpp --version
          - acpp-info --list-targets
          - clang++ --version
```

### 7.2 variants.yaml

**File**: `packages/adaptivecpp/recipe/variants.yaml`

```yaml
# Compiler variants - use Clang 18 to match LLVM 18
c_compiler:
  - clang
c_compiler_version:
  - "18"

cxx_compiler:
  - clangxx
cxx_compiler_version:
  - "18"
```

### 7.3 build.sh Script Outline

**File**: `packages/adaptivecpp/recipe/scripts/build.sh`

```bash
#!/bin/bash
set -euo pipefail

# ============================================================================
# Section 1: Setup and Path Resolution
# ============================================================================
RECIPE_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)
PACKAGE_DIR=$(cd "$RECIPE_DIR/.." && pwd -P)
LLVM_SOURCE_DIR="$PACKAGE_DIR/llvm-project"
ACPP_SOURCE_DIR="$LLVM_SOURCE_DIR/AdaptiveCpp"
BUILD_DIR="$PACKAGE_DIR/llvm-project/build"
BUILD_MARKER="$BUILD_DIR/.build_complete"

echo "LLVM Source:  $LLVM_SOURCE_DIR"
echo "ACPP Source:  $ACPP_SOURCE_DIR"
echo "Build Dir:    $BUILD_DIR"
echo "Install:      $PREFIX"

# ============================================================================
# Section 2: Verify Sources
# ============================================================================
if [ ! -d "$LLVM_SOURCE_DIR/llvm" ] || [ ! -d "$ACPP_SOURCE_DIR" ]; then
    echo "ERROR: Sources not found"
    exit 1
fi

# ============================================================================
# Section 3: Multi-Output Optimization (check build marker)
# ============================================================================
if [ -f "$BUILD_MARKER" ]; then
    echo "Build complete - running install only"
    cmake --install "$BUILD_DIR" --prefix "$PREFIX"
    # Skip to activation script installation (Section 6)
    # ... (see below)
    exit 0
fi

# ============================================================================
# Section 4: Configure + Build (first output only)
# ============================================================================
export CCACHE_DIR="${CCACHE_DIR:-$HOME/.ccache}"
export CCACHE_MAXSIZE="${CCACHE_MAXSIZE:-20G}"

C_COMPILER=$(basename "${CC:-clang}")
CXX_COMPILER=$(basename "${CXX:-clang++}")

mkdir -p "$BUILD_DIR"

# Configure (if not already configured)
if [ ! -f "$BUILD_DIR/build.ninja" ]; then
    cmake -S "$LLVM_SOURCE_DIR/llvm" -B "$BUILD_DIR" \
        -GNinja \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX="$PREFIX" \
        -DCMAKE_C_COMPILER="$C_COMPILER" \
        -DCMAKE_CXX_COMPILER="$CXX_COMPILER" \
        -DCMAKE_C_COMPILER_LAUNCHER=ccache \
        -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
        -DLLVM_TARGETS_TO_BUILD="X86;NVPTX;AMDGPU" \
        -DLLVM_ENABLE_PROJECTS="clang;openmp;lld" \
        -DLLVM_BUILD_LLVM_DYLIB=ON \
        -DLLVM_LINK_LLVM_DYLIB=ON \
        -DLLVM_PARALLEL_LINK_JOBS="${CPU_COUNT:-4}" \
        -DLLVM_EXTERNAL_PROJECTS=AdaptiveCpp \
        -DLLVM_EXTERNAL_ADAPTIVECPP_SOURCE_DIR="$ACPP_SOURCE_DIR" \
        -DLLVM_ADAPTIVECPP_LINK_INTO_TOOLS=ON \
        -DACPP_TARGETS=generic \
        -DACPP_COMPILER_FEATURE_PROFILE=full \
        -DWITH_SSCP_COMPILER=ON \
        -DWITH_ACCELERATED_CPU=ON \
        -DWITH_STDPAR=ON
fi

# Build
cmake --build "$BUILD_DIR" -j "${CPU_COUNT:-4}"

# ============================================================================
# Section 5: Install
# ============================================================================
cmake --install "$BUILD_DIR" --prefix "$PREFIX"

# ============================================================================
# Section 6: IDE Tooling Compatibility
# ============================================================================
BUILD_TRIPLET="${BUILD:-x86_64-conda-linux-gnu}"

# Create symlinks for clangd
ln -sf acpp "$PREFIX/bin/clang++"
ln -sf acpp "$PREFIX/bin/${BUILD_TRIPLET}-clang++"

# Create clang.cfg
cat > "$PREFIX/bin/clang.cfg" << 'EOF'
--sysroot=@CONDA_PREFIX@/x86_64-conda-linux-gnu/sysroot
-isystem @CONDA_PREFIX@/include/sycl
-isystem @CONDA_PREFIX@/include
-isystem @CONDA_PREFIX@/x86_64-conda-linux-gnu/sysroot/usr/include/c++/v1
-isystem @CONDA_PREFIX@/x86_64-conda-linux-gnu/sysroot/usr/include
EOF

# ============================================================================
# Section 7: Install Activation Scripts
# ============================================================================
mkdir -p "$PREFIX/etc/conda/activate.d"
mkdir -p "$PREFIX/etc/conda/deactivate.d"

cp "$RECIPE_DIR/scripts/activate.sh" \
   "$PREFIX/etc/conda/activate.d/~~activate-acpp.sh"
cp "$RECIPE_DIR/scripts/deactivate.sh" \
   "$PREFIX/etc/conda/deactivate.d/~~deactivate-acpp.sh"

chmod +x "$PREFIX/etc/conda/activate.d/~~activate-acpp.sh"
chmod +x "$PREFIX/etc/conda/deactivate.d/~~deactivate-acpp.sh"

# ============================================================================
# Section 8: Create Build Marker
# ============================================================================
touch "$BUILD_MARKER"
echo "Build complete."
```

### 7.4 Package-Level pixi.toml

**File**: `packages/adaptivecpp/pixi.toml`

```toml
[workspace]
name = "naga-adaptivecpp-toolkit"
channels = ["https://prefix.dev/pixi-build-backends", "conda-forge"]
platforms = ["linux-64"]
preview = ["pixi-build"]

[system-requirements]
libc = "2.34"

[dependencies]
naga-adaptivecpp-toolkit = { path = "toolkit" }

[build-dependencies]
pixi-build-rattler-build = "*"

[feature.build.dependencies]
# Compilers (match LLVM version)
clangxx_linux-64 = "18.*"
clang_linux-64 = "18.*"

# Build tools
cmake = ">=3.24"
ninja = ">=1.12"
python = ">=3.10"
git = "*"
ccache = "*"
lld = "18.*"

# Runtime dependencies
boost-cpp = ">=1.84"
sysroot_linux-64 = ">=2.34"
libstdcxx-devel_linux-64 = ">=15.2,<15.3"
```

---

## 8. Implementation Checklist

### Phase 1: Source Preparation

- [ ] Navigate to `packages/adaptivecpp/`
- [ ] Remove old standalone submodule: `git submodule deinit repo && git rm repo`
- [ ] Add upstream LLVM submodule: `git submodule add -b release/18.x https://github.com/llvm/llvm-project.git llvm-project`
- [ ] Add AdaptiveCPP nested submodule: `cd llvm-project && git submodule add -b develop https://github.com/AdaptiveCpp/AdaptiveCpp.git AdaptiveCpp`
- [ ] Pin LLVM version: `cd llvm-project && git checkout llvmorg-18.1.8`
- [ ] Commit changes: `git add .gitmodules packages/adaptivecpp && git commit -m "Switch to upstream LLVM + AdaptiveCPP"`

### Phase 2: Configuration Files

- [ ] Update `recipe/recipe.yaml`:
  - Remove `llvmdev` and `clangdev` from dependencies
  - Add `lld >=18` to build requirements
  - Update file lists for all three outputs (libs, devel, toolkit)
  - Add `bin/clang.cfg` and `bin/*-clang*` to toolkit files
- [ ] Update `recipe/variants.yaml`:
  - Set compiler to `clang` version `18`
- [ ] Update `pixi.toml`:
  - Remove `llvmdev` and `clangdev` dependencies
  - Add `lld = "18.*"` dependency

### Phase 3: Build Script

- [ ] Create/update `recipe/scripts/build.sh`:
  - Update paths to use `llvm-project/` instead of `repo/`
  - Add complete CMake configuration (see Section 3.1)
  - Add IDE tooling compatibility section (symlinks + clang.cfg)
  - Ensure activation script installation
  - Verify build marker logic for multi-output optimization

### Phase 4: Activation Scripts

- [ ] Create `recipe/scripts/activate.sh`:
  - Use template from Section 5.2
  - **CRITICAL**: Set `CXX` to `${_ACPP_PREFIX}/bin/${_ACPP_CHOST}-clang++`
  - Add all required environment variables
  - Follow conda-forge backup/restore patterns
- [ ] Create `recipe/scripts/deactivate.sh`:
  - Use template from Section 5.3
  - Restore all backed-up variables

### Phase 5: Initial Build Test

- [ ] Initialize submodules: `cd packages/adaptivecpp && git submodule update --init --recursive llvm-project`
- [ ] Verify sources: `ls llvm-project/llvm/CMakeLists.txt && ls llvm-project/AdaptiveCpp/CMakeLists.txt`
- [ ] Run build: `pixi build`
- [ ] Monitor build progress (expect 2-4 hours for first build)
- [ ] Check outputs in `output/linux-64/`:
  - `naga-adaptivecpp-toolkit-libs-*.conda` (~50-80 MB)
  - `naga-adaptivecpp-toolkit-devel-*.conda` (~5-10 MB)
  - `naga-adaptivecpp-toolkit-*.conda` (~300-500 MB)

### Phase 6: Package Validation

- [ ] Create test environment:
  ```bash
  conda create -n test-acpp --override-channels \
      -c ./packages/adaptivecpp/output/linux-64 \
      -c conda-forge \
      naga-adaptivecpp-toolkit
  ```
- [ ] Activate and test:
  ```bash
  conda activate test-acpp
  acpp --version
  acpp-info --list-targets
  echo $CXX  # Should be x86_64-conda-linux-gnu-clang++
  ```
- [ ] Test compilation:
  ```bash
  cat > test.cpp << 'EOF'
  #include <sycl/sycl.hpp>
  #include <iostream>
  int main() {
      sycl::queue q;
      std::cout << "Device: " << q.get_device().get_info<sycl::info::device::name>() << std::endl;
      return 0;
  }
  EOF
  
  acpp test.cpp -o test
  ./test
  ```
- [ ] Verify clangd compatibility:
  ```bash
  ls -l $CONDA_PREFIX/bin/clang++  # Should be symlink → acpp
  cat $CONDA_PREFIX/bin/clang.cfg  # Should contain sysroot config
  ```

### Phase 7: Documentation

- [ ] Update package README if exists
- [ ] Document build time expectations (~2-4 hours first build, ~5-15 min incremental)
- [ ] Document generic SSCP compilation model (JIT at runtime)
- [ ] Note IDE tooling setup (clangd should work out-of-box)

### Phase 8: Integration Testing

- [ ] Test with real SYCL application (if available)
- [ ] Verify JIT compilation (first kernel launch may pause briefly)
- [ ] Test on different hardware (CPU, NVIDIA GPU if available)
- [ ] Verify conda activation/deactivation cycles

---

## 9. References

### 9.1 Internal References

**Existing Intel LLVM Package** (for pattern reference):
- Location: `packages/llvm/`
- Activation script: `packages/llvm/recipe/scripts/activate.sh`
- Build script: `packages/llvm/recipe/scripts/build.sh`
- Recipe: `packages/llvm/recipe/recipe.yaml`

**Key patterns to replicate**:
- Triplet-prefixed compiler naming (`x86_64-conda-linux-gnu-clang++`)
- Conda backup/restore pattern for environment variables
- Multi-output recipe with build marker optimization
- Activation script ordering (`~~` prefix to run after other scripts)

### 9.2 External Documentation

**AdaptiveCPP**:
- Main documentation: https://github.com/AdaptiveCpp/AdaptiveCpp/blob/develop/doc/installing.md
- Linked-in build section: https://github.com/AdaptiveCpp/AdaptiveCpp/blob/develop/doc/installing.md#building-an-llvm-toolchain-with-adaptivecpp-linked-in-experimental-but-also-for-windows
- Repository: https://github.com/AdaptiveCpp/AdaptiveCpp

**Upstream LLVM**:
- Repository: https://github.com/llvm/llvm-project
- Release page: https://github.com/llvm/llvm-project/releases/tag/llvmorg-18.1.8
- External projects documentation: https://llvm.org/docs/CMake.html#llvm-external-projects

**Conda/Rattler-build**:
- Rattler-build docs: https://prefix-dev.github.io/rattler-build/
- Conda package specification: https://docs.conda.io/projects/conda-build/en/latest/

**Build Tools**:
- CMake documentation: https://cmake.org/documentation/
- Ninja build: https://ninja-build.org/
- Ccache: https://ccache.dev/

---

## 10. Troubleshooting Guide

### 10.1 Common Build Issues

**Issue**: `LLVM source not found`
```bash
# Solution: Initialize submodules
cd packages/adaptivecpp
git submodule update --init --recursive llvm-project
```

**Issue**: `Out of memory during linking`
```bash
# Solution: Reduce parallel link jobs
# Edit build.sh, change:
-DLLVM_PARALLEL_LINK_JOBS="${CPU_COUNT:-4}"
# To:
-DLLVM_PARALLEL_LINK_JOBS="2"
```

**Issue**: Build marker prevents rebuilding after failure
```bash
# Solution: Remove marker to force rebuild
rm packages/adaptivecpp/llvm-project/build/.build_complete
```

**Issue**: Ccache fills up
```bash
# Solution: Clear or increase cache
ccache -C                      # Clear cache
export CCACHE_MAXSIZE="30G"    # Increase limit (default 20G)
```

### 10.2 Runtime Issues

**Issue**: `acpp: command not found` after activation
```bash
# Check PATH
echo $PATH
# Should include $CONDA_PREFIX/bin

# Verify installation
conda list | grep adaptivecpp
```

**Issue**: `error: sycl/sycl.hpp: No such file or directory`
```bash
# Check CXX variable
echo $CXX
# Should be: /path/to/conda/bin/x86_64-conda-linux-gnu-clang++

# Check include paths
echo $CXXFLAGS
# Should contain: -isystem /path/to/conda/include/sycl
```

**Issue**: Clangd cannot find SYCL headers
```bash
# Verify clang.cfg exists
cat $CONDA_PREFIX/bin/clang.cfg

# Verify symlink
ls -l $CONDA_PREFIX/bin/clang++
# Should be: clang++ -> acpp

# Restart language server in IDE
```

### 10.3 Validation Commands

**Check CMake configuration**:
```bash
cd packages/adaptivecpp/llvm-project/build
grep LLVM_EXTERNAL_PROJECTS CMakeCache.txt
# Expected: LLVM_EXTERNAL_PROJECTS:STRING=AdaptiveCpp

grep LLVM_ADAPTIVECPP_LINK_INTO_TOOLS CMakeCache.txt
# Expected: LLVM_ADAPTIVECPP_LINK_INTO_TOOLS:BOOL=ON

grep ACPP_TARGETS CMakeCache.txt
# Expected: ACPP_TARGETS:STRING=generic
```

**Check installed files**:
```bash
conda activate test-acpp

# Verify binaries
which acpp
which clang++
ls -l $(which clang++)  # Should be symlink

# Verify libraries
ls $CONDA_PREFIX/lib/libacpp_runtime.so

# Verify headers
ls $CONDA_PREFIX/include/sycl/sycl.hpp

# Verify CMake configs
ls $CONDA_PREFIX/lib/cmake/AdaptiveCpp/AdaptiveCppConfig.cmake
```

---

## Appendix A: Quick Reference Commands

### Build Workflow
```bash
cd packages/adaptivecpp
git submodule update --init --recursive llvm-project
pixi build
```

### Test Installation
```bash
conda create -n test-acpp -c ./output/linux-64 -c conda-forge naga-adaptivecpp-toolkit
conda activate test-acpp
acpp --version
```

### Compile SYCL Program
```bash
acpp my_code.cpp -o my_program
ACPP_VERBOSE=1 ./my_program  # Verbose output shows JIT compilation
```

### Check Environment
```bash
echo $CXX                    # x86_64-conda-linux-gnu-clang++
echo $ACPP_TARGETS           # generic
acpp-info --list-targets     # Shows available targets
```

---

## Appendix B: File Checklist

**Files to create/modify**:
- [x] `packages/adaptivecpp/recipe/recipe.yaml`
- [x] `packages/adaptivecpp/recipe/variants.yaml`
- [x] `packages/adaptivecpp/recipe/scripts/build.sh`
- [x] `packages/adaptivecpp/recipe/scripts/activate.sh`
- [x] `packages/adaptivecpp/recipe/scripts/deactivate.sh`
- [x] `packages/adaptivecpp/pixi.toml`
- [x] `.gitmodules` (add llvm-project and AdaptiveCpp submodules)

**Submodules to configure**:
- [x] `packages/adaptivecpp/llvm-project/` (upstream LLVM)
- [x] `packages/adaptivecpp/llvm-project/AdaptiveCpp/` (nested)

**Expected outputs** (in `packages/adaptivecpp/output/linux-64/`):
- [x] `naga-adaptivecpp-toolkit-libs-2026.2.0-*.conda`
- [x] `naga-adaptivecpp-toolkit-devel-2026.2.0-*.conda`
- [x] `naga-adaptivecpp-toolkit-2026.2.0-*.conda`

---

**End of Migration Plan**

This document is implementation-ready. Proceed with Phase 1 when ready to begin migration.
