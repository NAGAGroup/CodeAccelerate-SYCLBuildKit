# AGENTS.md - AI Coding Agent Guide

## Project Overview

**CodeAccelerate-SYCLBuildKit** builds relocatable SYCL compiler toolchains based on Intel's LLVM/DPC++.

- **Tech stack**: Intel LLVM/DPC++, oneAPI Math/DPL, pixi (conda), Nushell scripts
- **Targets**: Linux x64, SYCL backends (CUDA, OpenCL, Native CPU)
- **Build system**: CMake + Ninja, orchestrated via pixi tasks

## Critical Notes for AI Agents

1. **Always use pixi**: All commands require `pixi run` or `pixi shell` for correct environment
2. **Incremental builds work**: CMake/Ninja handle incremental builds; full rebuilds rarely needed
3. **Ccache enabled**: Automatic caching speeds up recompilation
4. **Path validation**: Nushell scripts check paths rigorously; follow this pattern in new scripts
5. **Error messages**: Always include recovery suggestions (e.g., "Run: pixi run configure")
6. **Git submodule**: `packages/llvm/repo` is a submodule; don't modify `.git` directly
7. **Test after changes**: Minimum `pixi run test --quick` after code modifications
8. **Parallelism**: Builds use all cores by default; override with `BUILD_JOBS` if needed

## Quick Start Commands

```bash
pixi shell                    # Activate environment (required for all commands)
pixi run submodule-init       # Initialize LLVM source (first time only)
pixi run submodule-update     # Update to latest upstream (if needed)
pixi run configure            # Configure CMake
pixi run build                # Build LLVM/DPC++ (parallel, uses ccache)
pixi run install              # Install to $INSTALL_PREFIX
pixi run test                 # Full test suite
pixi run test --quick         # Fast smoke tests only
pixi run test --sycl-only     # Skip LLVM lit tests
pixi run clean                # Remove build artifacts
```

## Running Single Tests

**Manual SYCL test compilation** (recommended for debugging):
```bash
pixi run install
# Create test file in build/test/ or temp directory
echo '#include <sycl/sycl.hpp>
int main() { return 0; }' > build/test/my_test.cpp
$INSTALL_PREFIX/bin/clang++ -fsycl build/test/my_test.cpp -o build/test/my_test
./build/test/my_test
```

**LLVM lit tests**:
```bash
cd $LLVM_BUILD_DIR
llvm-lit test/sycl/basic_tests/dimension.cpp  # Specific test
ninja check-sycl                               # All SYCL tests
ninja check-sycl-host                          # Host-only tests
```

## Code Style Guidelines

### C/C++ (LLVM/SYCL Code)

**Formatting**: LLVM style via `.clang-format`
- 80-column limit, 2-space indentation

**Naming** (enforced by `.clang-tidy`):
- Classes/Enums/Unions: `CamelCase`
- Functions: `camelBack` (e.g., `myFunction`)
- Variables/Parameters/Members: `CamelCase`
- Macros: `UPPER_SNAKE_CASE`

**Quality Checks**:
```bash
clang-format -i modified_files.cpp              # Apply formatting
clang-tidy path/to/file.cpp -- -I$LLVM_SOURCE_DIR/sycl/include  # Lint
```

### Python

- **Formatter**: Black with 88-character line limit
- **Naming**: PEP 8 (snake_case for functions/variables)
- **Apply**: `black --line-length 88 script.py`

### Nushell Scripts (`.nu` files)

- **Variables/Functions**: `snake_case`
- **Options/Flags**: `kebab-case` (e.g., `--sycl-only`)
- **Indentation**: 4 spaces
- **Entry point**: Always include `def main []`
- **Strings**: Use interpolation `$"text ($variable)"`
- **Env vars**: `$env.VAR_NAME`, with defaults: `$env.VAR? | default "value"`

**Error handling pattern**:
```nu
if not ($source_dir | path exists) {
    print $"Error: Source not found at ($source_dir)"
    print "Run: pixi run submodule-init"
    exit 1
}
```

### Configuration Files (TOML/YAML)

- **Task names**: `kebab-case` (e.g., `submodule-init`)
- **Env vars**: `UPPER_SNAKE_CASE`

## Project Structure

```
CodeAccelerate-SYCLBuildKit/
├── packages/llvm/repo/           # Intel LLVM/DPC++ submodule
│   └── sycl/                     # SYCL runtime & tests
│       ├── test/                 # LIT-based compilation tests
│       └── test-e2e/             # End-to-end functional tests
├── packages/onemath/repo/        # oneAPI Math (BLAS/LAPACK)
├── scripts/llvm/*.nu             # Build orchestration (configure/build/install/test)
├── build/llvm/                   # CMake build artifacts (gitignored)
├── activation/*.sh               # Environment setup scripts
├── toolchains/linux.cmake        # Cross-compilation toolchain
└── pixi.toml                     # Main configuration
```

## Key Environment Variables

| Variable            | Default                          | Purpose                      |
|---------------------|----------------------------------|------------------------------|
| `INSTALL_PREFIX`    | `$HOME/.local/naga-sycl-toolkit` | Installation directory       |
| `LLVM_SOURCE_DIR`   | `$PROJECT_ROOT/packages/llvm/repo` | LLVM source location       |
| `LLVM_BUILD_DIR`    | `$PROJECT_ROOT/build/llvm`       | CMake build directory        |
| `LLVM_TARGETS`      | `X86;NVPTX;SPIRV`                | LLVM target architectures    |
| `SYCL_BACKENDS`     | `opencl;cuda;native_cpu`         | SYCL runtime backends        |
| `BUILD_JOBS`        | (auto-detected via `nproc`)      | Parallel build jobs          |

**Override in shell**: `export BUILD_JOBS=16 && pixi run build`

## Common Workflows

**Incremental development**:
```bash
# Edit code in packages/llvm/repo/sycl/...
pixi run build                    # Incremental rebuild
pixi run install                  # Update installation
pixi run test --quick             # Fast verification
```

**Debugging test failure**:
```bash
pixi run install
$INSTALL_PREFIX/bin/clang++ -fsycl -g failing_test.cpp -o test_debug
./test_debug                      # Run with debugger
```

## oneAPI Math Workflow

Requires DPC++ built first (note: `-e` flag is crucial):
```bash
pixi run -e onemath submodule-init
pixi run -e onemath configure     # Uses installed DPC++
pixi run -e onemath build
pixi run -e onemath install
```

## Getting Help

- **Project README**: `/home/jack/sycl-build-project/CodeAccelerate-SYCLBuildKit/README.md`
- **LLVM upstream**: https://github.com/intel/llvm/tree/sycl
- **SYCL spec**: https://registry.khronos.org/SYCL/
- **Pixi docs**: https://pixi.sh/
