# CodeAccelerate-SYCLBuildKit

Conda packages for [AdaptiveCpp](https://github.com/AdaptiveCpp/AdaptiveCpp) — the independent, community-driven SYCL compiler for CPUs and GPUs from all vendors.

AdaptiveCpp uses a generic single-pass compiler design: kernels are compiled once to a portable LLVM IR representation and JIT-compiled at runtime for whatever hardware is present. A single binary can transparently target NVIDIA GPUs, AMD GPUs, Intel GPUs, and CPUs — no recompilation needed.

These packages bundle LLVM 20 + AdaptiveCpp 25.10.0 with all backends enabled.

---

## Packages

| Package | Description |
|---|---|
| `acpp-libs` | Runtime shared libraries (LLVM, Clang, acpp-rt). Required by all other packages. |
| `acpp-toolchain` | Compiler binaries (`acpp`, `clang`, `lld`, etc.), headers, and CMake configs. |
| `acpp-clang-tools` | Clang tooling (`clang-format`, `clang-tidy`, `clangd`, etc.). Drop-in replacement for conda-forge's `clang-tools`, built against the same LLVM. |
| `acpp-toolchain_linux-64` | Activation package: sets `CC`/`CXX`, installs sysroot cfg for building redistributable conda packages with the acpp toolchain. |

It is recommended that `acpp-libs` is the only package installed in the runtime environments of packages built with acpp to keep install sizes down.

---

## Installation

Packages are available from the `code-accelerate` channel on [prefix.dev](https://prefix.dev).

### Using pixi (recommended)

```toml
# pixi.toml
[project]
channels = ["https://prefix.dev/code-accelerate", "conda-forge"]
platforms = ["linux-64"]

[dependencies]
```

```sh
pixi add acpp-toolchain
```

### Installing globally

```sh
pixi global install -c "https://prefix.dev/code-accelerate" acpp-toolchain
```

---

## Backend Configuration

Backend availability is determined entirely by what's already on your system. `acpp-libs` detects installed drivers and device libraries at environment activation time and wires them up automatically — no manual configuration needed.

The only backend enabled out-of-the-box is **OpenMP (CPU)**. All others activate when the relevant drivers and conda packages are present.

### OpenMP (CPU) — always available

No additional packages or drivers required.

```sh
pixi add acpp-toolchain
```

### CUDA (NVIDIA GPUs)

Requires NVIDIA drivers with CUDA 12 support already installed on the host (`nvidia-smi` should report `CUDA Version: 12.x`). Install the runtime packages:

```sh
pixi add acpp-toolchain cuda-runtime cuda-nvvm
```

`cuda-nvvm` provides `libdevice.10.bc`, the bitcode library required for CUDA kernel JIT compilation.

> CUDA major version must be 12. CUDA 11 and CUDA 13+ are not supported by this build.

### ROCm (AMD GPUs)

Requires ROCm 6 drivers already installed on the host. Install:

```sh
pixi add acpp-toolchain hip-runtime-amd rocm-device-libs
```

`rocm-device-libs` provides the AMD GPU bitcode libraries required for kernel JIT compilation.

> ROCm major version must be 6. ROCm 5.x is not supported by this build.

### Level Zero (Intel GPUs)

Requires Intel GPU drivers with Level Zero support, which are typically present on any system running an Intel discrete or integrated GPU with a recent kernel. No additional conda packages are needed — just activate the environment and AdaptiveCpp will find the Level Zero driver automatically:

```sh
pixi add acpp-toolchain
```

Verify your Intel GPU is visible to AdaptiveCpp:

```sh
acpp-info
```

### OpenCL

The OpenCL backend activates automatically when a compatible ICD is present on the system.

AdaptiveCpp's OpenCL backend requires devices that support SPIR-V ingestion and Intel's USM extension. In practice this means Intel GPUs and CPUs with Intel's compute drivers installed. NVIDIA and AMD GPUs are not supported via OpenCL — use the CUDA or ROCm backends instead.

[PoCL](https://portablecl.org) (`pocl-cpu` on conda-forge) provides a CPU-based OpenCL implementation compatible with AdaptiveCpp, but cannot currently be installed in the same environment as `acpp-libs`. Use a separate environment if you need PoCL.

---

## Verifying Your Installation

Check which backends and devices AdaptiveCpp can see:

```sh
acpp-info
```

Run a program with a specific backend:

```sh
# CPU via OpenMP (always works)
ACPP_VISIBILITY_MASK="omp" ./my_sycl_program

# NVIDIA GPU
ACPP_VISIBILITY_MASK="cuda" ./my_sycl_program

# AMD GPU
ACPP_VISIBILITY_MASK="hip" ./my_sycl_program

# Intel GPU via Level Zero
ACPP_VISIBILITY_MASK="ze" ./my_sycl_program

# OpenCL
ACPP_VISIBILITY_MASK="ocl" ./my_sycl_program
```

---

## Compiler Usage

Compile SYCL programs using `acpp`:

```sh
acpp -O2 -o my_program my_program.cpp
```

Or via CMake:

```cmake
find_package(AdaptiveCpp REQUIRED)
add_executable(my_program my_program.cpp)
add_sycl_to_target(TARGET my_program)
```

For building redistributable conda packages with the acpp toolchain, also install `acpp-toolchain_linux-64` which configures the GCC sysroot for the conda build environment.

---

## Clang Tools

`clang-format`, `clang-tidy`, `clangd`, and the full clang tooling suite — built against the same LLVM as your SYCL compiler:

```sh
pixi add acpp-clang-tools
```

This is a drop-in replacement for conda-forge's `clang-tools`. Installing `acpp-clang-tools` blocks conda-forge's `clang-tools` since they provide the same binaries, intentionally preventing version mismatches between your formatter and compiler.

---

## Compatibility Notes

**Linux x86-64 only.** LLVM 20 / AdaptiveCpp 25.10.0 — see [AdaptiveCpp releases](https://github.com/AdaptiveCpp/AdaptiveCpp/releases).

### Incompatible packages

`acpp-libs` bundles its own LLVM 20 and Clang 20 shared libraries. The following conda-forge packages are blocked to prevent conflicts:

**Clang/LLVM activation and dev packages** — these stomp `CC`/`CXX`/`CFLAGS` environment variables or install unversioned symlinks and headers that would conflict with the bundled libraries: `clang_linux-64`, `clangxx_linux-64`, `clang_impl_linux-64`, `clangxx_impl_linux-64`, `llvmdev`, `clangdev`.

**Versioned LLVM 20 shared libraries** — conda-forge's `libllvm20`, `libclang20`, and `libclang-cpp20` install the same `.so` files as the bundled libraries and would clobber them.

If you need a standalone conda-forge clang/LLVM toolchain, use a separate environment.

**CUDA version** — if CUDA packages are installed, the major version must be 12. `cuda-cudart`, `cuda-nvrtc`, `cuda-nvvm`, and `cuda` must all be `>=12,<13`, and the system CUDA driver (`__cuda`) must also be version 12. CUDA 11 and CUDA 13+ are not supported.

**ROCm version** — if ROCm packages are installed, `hip-runtime-amd` and `rocm-device-libs` must be `>=6,<7`. ROCm 5.x is not supported.

### acpp-clang-tools incompatibilities

`acpp-clang-tools` installs the same binaries as conda-forge's clang tooling packages. The following are blocked to prevent binary conflicts: `clang-tools`, `clang-format`, `clang-tidy`, `clangd`. If you need conda-forge's versions of these tools, do not install `acpp-clang-tools`.

---

## License

AdaptiveCpp is licensed under Apache-2.0 with LLVM exception. LLVM is licensed under Apache-2.0 with LLVM exception.
See [AdaptiveCpp/LICENSE](https://github.com/AdaptiveCpp/AdaptiveCpp/blob/develop/LICENSE) and [llvm/LICENSE](https://github.com/llvm/llvm-project/blob/main/LICENSE.TXT).
