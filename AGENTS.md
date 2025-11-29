# Agent Guidelines for CodeAccelerate-SYCLBuildKit

## Project Overview

This project builds open-source, relocatable SYCL toolchains (Intel LLVM/DPC++) as conda packages with NVIDIA CUDA support.

### Key Components
- **Intel LLVM/DPC++**: SYCL compiler based on LLVM (submodule at `packages/llvm/repo`)
- **oneMath**: Math library with CUDA backends - cublas, cusolver, curand, cufft, cusparse (submodule at `packages/onemath/repo`)

### Target Platforms
- Linux x86_64 only
- CPU + NVIDIA GPU backends (no AMD/HIP support currently)

## Build Commands

```bash
# LLVM/DPC++ build (use 'llvm' or 'dev' environment)
pixi run -e llvm submodule-init   # Initialize git submodule
pixi run -e llvm configure        # Configure build
pixi run -e llvm build            # Build (takes 1-2 hours)
pixi run -e llvm install          # Install to $INSTALL_PREFIX
pixi run -e llvm test             # Run tests
pixi run -e llvm test -- --quick  # Quick smoke tests only

# oneMath build (requires pre-built DPC++)
pixi run -e onemath submodule-init
pixi run -e onemath configure
pixi run -e onemath build
pixi run -e onemath install

# Utility
pixi run -e llvm clean            # Remove build directory
pixi run -e llvm sycl-ls          # List SYCL devices
```

## Directory Structure

```
CodeAccelerate-SYCLBuildKit/
├── packages/
│   ├── llvm/
│   │   ├── repo/               # Intel LLVM submodule
│   │   ├── recipe/             # rattler-build recipe for conda package
│   │   │   ├── recipe.yaml     # Main recipe file
│   │   │   ├── scripts/        # Build scripts for recipe
│   │   │   └── build-activation/  # Environment setup for recipe
│   │   └── pixi.toml           # Standalone pixi config for package build
│   └── onemath/
│       └── repo/               # oneMath submodule
├── scripts/
│   ├── llvm/
│   │   ├── configure.nu        # Configure using buildbot/configure.py
│   │   ├── build.nu            # Build with cmake
│   │   ├── install.nu          # Install toolchain
│   │   └── test.nu             # Run tests
│   └── onemath/
│       ├── configure.nu
│       ├── build.nu
│       └── install.nu
├── activation/
│   ├── linux.sh                # Base Linux environment
│   ├── llvm.sh                 # LLVM-specific environment
│   └── onemath.sh              # oneMath-specific environment
├── build/                      # Build artifacts (gitignored)
├── pixi.toml                   # Main pixi configuration
└── pixi.toml.old               # Old config (can be deleted)

# Legacy directories (can be removed after migration is complete):
├── llvm/                       # Old LLVM scripts (replaced by scripts/llvm/)
├── onemkl/                     # Old oneMKL scripts (replaced by scripts/onemath/)
└── toolchains/                 # Old CMake toolchain files (no longer needed)
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `INSTALL_PREFIX` | `~/.local/sycl-toolkit` | Installation directory |
| `LLVM_SOURCE_DIR` | `packages/llvm/repo` | LLVM source location |
| `LLVM_BUILD_DIR` | `build/llvm` | LLVM build directory |
| `SYCL_BACKENDS` | `opencl;cuda;native_cpu` | SYCL backends to enable |
| `LLVM_TARGETS` | `X86;NVPTX;SPIRV` | LLVM target architectures |
| `DPCPP_ROOT` | `$INSTALL_PREFIX` | DPC++ location for oneMath |
| `ONEMATH_SOURCE_DIR` | `packages/onemath/repo` | oneMath source location |
| `ONEMATH_BUILD_DIR` | `build/onemath` | oneMath build directory |

## Pixi Environments

| Environment | Purpose | Features |
|-------------|---------|----------|
| `dev` | Full development | build-tools, host-compiler, cuda, llvm |
| `llvm` | LLVM build only | Same as dev |
| `onemath` | oneMath build | build-tools, cuda, onemath (requires pre-built DPC++) |

## Key Files

- `scripts/llvm/configure.nu`: Wraps Intel's `buildbot/configure.py`
- `packages/llvm/recipe/recipe.yaml`: rattler-build recipe for conda packaging
- `activation/linux.sh`: Sets up CUDA paths, ccache

## Build System Notes

### Intel LLVM Configuration
The build uses Intel's `buildbot/configure.py` script with flags:
- `--cuda`: Enable CUDA backend
- `--native_cpu`: Enable native CPU backend  
- `--shared-libs`: Build shared libraries
- `--use-lld`: Use LLD linker (faster)
- `--use-zstd`: Enable zstd compression

### No Sysroot Injection Needed
Modern Intel LLVM builds correctly without the complex sysroot injection that was previously required. The activation scripts have been simplified accordingly.

### CUDA from Conda
CUDA toolkit comes from conda-forge (`cuda-toolkit` package). The CUDA root is at `$CONDA_PREFIX/targets/x86_64-linux`.

## Common Issues

1. **Long build times**: LLVM build takes 1-2 hours. Use `BUILD_JOBS` env var to control parallelism.
2. **Disk space**: Build requires ~50GB for LLVM build directory.
3. **ccache**: Enabled by default; cache is at `~/.cache/ccache` with 50GB max.

## Testing

The `test.nu` script runs:
1. Compiler version check
2. `sycl-ls` device enumeration
3. SYCL vector addition test (compile + run)
4. Optional: `check-sycl` lit tests (slow)

Use `--quick` flag for fast smoke tests only.

## Conda Package Build

The `packages/llvm/recipe/` directory contains a rattler-build recipe that produces three packages:
- `sycl-dpcpp-libs`: Runtime libraries only
- `sycl-dpcpp-libs-devel`: Development headers and cmake files
- `sycl-dpcpp-toolkit`: Full compiler toolkit

To build the conda package:
```bash
cd packages/llvm
rattler-build build --recipe recipe/
```
