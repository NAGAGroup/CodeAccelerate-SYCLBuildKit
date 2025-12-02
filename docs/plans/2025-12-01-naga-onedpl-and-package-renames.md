# Package Renames & oneDPL Addition

**Date:** 2025-12-01  
**Status:** ✅ Completed

## Summary

This document records the implementation of:
1. Adding `naga-onedpl` as a new package (header-only SYCL parallel algorithms library)
2. Renaming all existing packages to use `naga-` prefix
3. Standardizing version numbers to `2025.12.1` (date-based versioning)

## Changes Implemented

### 1. New Package: `naga-onedpl`

Created `packages/onedpl/` with:
- Single package structure (header-only, no libs/devel split)
- Git submodule: `https://github.com/uxlfoundation/oneDPL.git`
- Build strategy: CMake configure + install (no compilation)
- Dependencies: `naga-sycl-toolkit` (SYCL compiler for backend support)

**Files created:**
- `packages/onedpl/pixi.toml` - Workspace configuration
- `packages/onedpl/recipe/recipe.yaml` - Package recipe
- `packages/onedpl/recipe/scripts/build.sh` - Build script
- `packages/onedpl/src/LICENSE.txt` - Dummy source (Apache-2.0 WITH LLVM-exception)
- `packages/onedpl/src/README.md` - Dummy source readme
- `packages/onedpl/.gitignore` - Ignore .pixi/, build/, pixi.lock

### 2. Package Renames

#### LLVM/SYCL Toolkit (`packages/llvm/`)

| Old Name | New Name |
|----------|----------|
| `sycl-toolkit` | `naga-sycl-toolkit` |
| `sycl-toolkit-libs` | `naga-sycl-toolkit-libs` |
| `sycl-toolkit-devel` | `naga-sycl-toolkit-devel` |

**Files updated:**
- `packages/llvm/recipe/recipe.yaml` - Package names, version `2025.12.1`
- `packages/llvm/recipe/scripts/build.sh` - CCACHE_DIR path
- `packages/llvm/pixi.toml` - Workspace comments, dependencies
- `packages/llvm/libs/pixi.toml` - Package name, version
- `packages/llvm/devel/pixi.toml` - Package name, version, dependencies
- `packages/llvm/toolkit/pixi.toml` - Package name, version, dependencies

#### oneMath (`packages/onemath/`)

| Old Name | New Name |
|----------|----------|
| `onemath` | `naga-onemath` |
| `onemath-libs` | `naga-onemath-libs` |
| `onemath-devel` | `naga-onemath-devel` |

**Files updated:**
- `packages/onemath/recipe/recipe.yaml` - Package names, version `2025.12.1`, dependencies
- `packages/onemath/recipe/scripts/build.sh` - Comments about compiler source
- `packages/onemath/recipe/variants.yaml` - Comment about consistency
- `packages/onemath/pixi.toml` - Workspace comments, dependencies
- `packages/onemath/libs/pixi.toml` - Package name, version
- `packages/onemath/devel/pixi.toml` - Package name, version, dependencies
- `packages/onemath/onemath/pixi.toml` - Package name, version, dependencies

### 3. Documentation & Configuration Updates

**Files updated:**
- `AGENTS.md` - Updated `INSTALL_PREFIX` default path
- `activation/linux.sh` - Updated `INSTALL_PREFIX` and `CCACHE_DIR` paths
- `pixi.toml` - Updated `INSTALL_PREFIX` environment variable
- `.gitmodules` - Added oneDPL submodule

## Package Structure Comparison

### naga-sycl-toolkit (3 packages)
```
naga-sycl-toolkit-libs   → Runtime libraries
naga-sycl-toolkit-devel  → Headers, cmake files
naga-sycl-toolkit        → Full compiler toolkit
```

### naga-onemath (3 packages)
```
naga-onemath-libs   → Runtime libraries
naga-onemath-devel  → Headers, cmake files
naga-onemath        → Meta-package
```

### naga-onedpl (1 package)
```
naga-onedpl  → Headers, cmake files (header-only library)
```

## Versioning Strategy

All packages now use version `2025.12.1`:
- Format: `YYYY.MM.patch`
- Date-based: reflects build date
- Consistent across all naga packages

## Build Commands

### naga-onedpl
```bash
cd packages/onedpl
pixi run -e init submodule-init  # Initialize git submodule
pixi install                      # Build package
```

### naga-sycl-toolkit
```bash
cd packages/llvm
pixi run -e init setup           # Create recipe symlinks (first time only)
pixi install                     # Build packages
```

### naga-onemath
```bash
cd packages/onemath
pixi run -e init setup           # Create recipe symlinks (first time only)
pixi run -e init submodule-init  # Initialize git submodule
pixi install                     # Build packages
```

## Design Rationale

### Why single package for oneDPL?
- Header-only library (no compiled libraries to separate)
- Simpler structure, faster builds
- No runtime/devel split needed

### Why naga- prefix?
- Clear branding and ownership
- Avoids conflicts with upstream/conda-forge packages
- Consistent naming across all custom packages

### Why date-based versioning?
- Reflects actual build date
- No need to track upstream versions separately
- Simple increment for rebuilds (patch number)

## Testing

After implementation, verify:
1. Git submodule initialized: `git submodule status packages/onedpl/repo`
2. Package structure: `ls -la packages/onedpl/`
3. Recipe validates: `cd packages/onedpl && pixi install --dry-run`
4. No old package name references: `grep -r "sycl-toolkit[^-]" --exclude-dir=repo`

## Top-Level Pixi Manifest Updates

The top-level `pixi.toml` was updated to:
- Rename `onemath` feature → `oneapi` (covers both oneMath and oneDPL)
- Add `ONEDPL_SOURCE_DIR` and `ONEDPL_BUILD_DIR` environment variables
- Add `ONEDPL_BACKEND = "dpcpp"` to feature activation
- Rename `onemath` environment → `oneapi` environment

The `oneapi` feature provides a unified environment for all oneAPI libraries.

## Future Considerations

1. **Upstream version tracking**: Consider adding upstream version to package metadata
2. **Build optimization**: Header-only packages could skip CMake entirely
3. **Additional oneAPI libs**: Follow similar pattern for oneTBB, oneCCL, etc.
4. **Channel management**: Document nagagroup channel setup and publishing

## Related Files

- Design discussion: Brainstorming session (2025-12-01)
- Build scripts: `packages/*/recipe/scripts/build.sh`
- Recipes: `packages/*/recipe/recipe.yaml`
