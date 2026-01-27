# AGENTS.md - AI Coding Agent Guide

## Project Overview

**CodeAccelerate-SYCLBuildKit** is a conda packaging workspace that builds relocatable SYCL compiler toolchains for heterogeneous computing.

- **Tech stack**: AdaptiveCpp (SYCL compiler), oneAPI Math/DPL libraries, pixi-build (rattler-build backend)
- **Platform**: Linux x64 only
- **Output**: `.conda` packages (conda 2.0 format) uploaded to prefix.dev/code-accelerate
- **Goal**: Platform-agnostic compute stack with JIT compilation (generic target, no platform-specific recompilation)

## Critical Notes for AI Agents

1. **PACKAGING FOCUS**: This is a packaging workspace. **DO NOT** modify source code in `repo/` or `llvm-project/` directories.
2. **BUILD COMMANDS**: Use `pixi install` (triggers build) or `pixi build` (explicit). **DO NOT** use `pixi run build`.
3. **TOOL USAGE**: Use `pixi` for lifecycle management. Only use `rattler-build` directly for debugging recipe tests.
4. **MULTI-OUTPUT RECIPES**: Each package produces 3 outputs (libs, devel, meta-package) from a single build.
5. **BUILD MARKER OPTIMIZATION**: Recipes use `.build_complete` to avoid rebuilding for each output.
6. **RECIPE SYMLINKS**: onemath/onedpl use symlinked recipe dirs as workaround for pixi-build limitation.
7. **GIT SUBMODULES**: onemath/repo and onedpl/repo are git submodules; adaptivecpp uses custom `.repos.toml`.
8. **BUILD DEPENDENCY ORDER**: adaptivecpp MUST be built first (onemath/onedpl depend on it).
9. **CCACHE ENABLED**: onemath uses ccache with 10GB cache for faster recompilation.
10. **TEST SCOPE**: Recipe tests validate file existence and binary invocation only (no integration tests).
11. **GENERIC TARGET**: `ACPP_TARGETS=generic` enables runtime JIT to device code (portable, no AOT compilation).

## Package Build Commands

### Check Recipe Configuration

```bash
cd packages/adaptivecpp
cat recipe/recipe.yaml              # Multi-output recipe definition
cat recipe/variants.yaml            # Compiler/CUDA version constraints
```

### Build Single Package

```bash
cd packages/adaptivecpp
pixi run repos-init                 # First time: initialize llvm-project + AdaptiveCpp repos
pixi install                        # Trigger build via pixi-build backend
```

**Output**: `.conda` files in `output/` (e.g., `naga-adaptivecpp-toolkit-libs-2026.2.17-h9f6055b_0.conda`)

### Build All Packages (Sequential)

```bash
# 1. AdaptiveCpp (LLVM + SYCL compiler)
cd packages/adaptivecpp && pixi run repos-init && pixi install

# 2. onemath (SYCL math library, depends on adaptivecpp)
cd ../onemath && pixi run -e init submodule-init && pixi run -e init setup && pixi install

# 3. onedpl (SYCL parallel algorithms, depends on adaptivecpp)
cd ../onedpl && pixi run -e init submodule-init && pixi install
```

### Run Recipe Tests

```bash
cd packages/adaptivecpp
# Tests run automatically after build; to re-run manually for debugging:
pixi shell
rattler-build test --recipe-dir recipe/
exit
```

**Test scope**: File existence checks (`test -f $PREFIX/lib/libacpp_runtime.so`) and binary invocation (`acpp --version`)

## Code Style Guidelines

### Recipe Files (YAML)

- **Naming**: `kebab-case` for package names, task names
- **Env vars**: `UPPER_SNAKE_CASE` (e.g., `BUILD_PREFIX`, `PREFIX`)
- **Indentation**: 2 spaces
- **Comments**: Use `#` for explanations of non-obvious configurations
- **Jinja2**: Use `{{ compiler('cxx') }}` for compiler selection, `${{ version }}` for version interpolation

**Example**:
```yaml
outputs:
  - package:
      name: naga-adaptivecpp-toolkit-libs
      version: ${{ version }}
    requirements:
      host:
        - ${{ compiler('cxx') }}
        - cmake >=3.18
```

### Build Scripts (Bash)

- **Shebang**: `#!/usr/bin/env bash`
- **Error handling**: `set -euo pipefail` at top
- **Naming**: `snake_case` for variables/functions
- **Env vars**: `${BUILD_PREFIX}`, `${PREFIX}`, `${SRC_DIR}` (conda-build conventions)
- **Path handling**: Always use absolute paths with `realpath` or `readlink -f`
- **Verbose output**: Use `set -x` or echo key steps for debugging

**Error handling pattern**:
```bash
if [[ ! -d "${LLVM_SOURCE}" ]]; then
    echo "ERROR: llvm-project not found at ${LLVM_SOURCE}"
    echo "Run: cd packages/adaptivecpp && pixi run repos-init"
    exit 1
fi
```

### Nushell Scripts (`.nu` files)

- **Variables/Functions**: `snake_case`
- **Options/Flags**: `kebab-case` (e.g., `--sycl-only`)
- **Indentation**: 4 spaces
- **Entry point**: Always include `def main []`
- **Strings**: Use interpolation `$"text ($variable)"`
- **Env vars**: `$env.VAR_NAME`, with defaults: `$env.VAR? | default "value"`

### Configuration Files (TOML)

- **Task names**: `kebab-case` (e.g., `repos-init`, `submodule-init`)
- **Env vars**: `UPPER_SNAKE_CASE`
- **Channels**: Ordered by priority (code-accelerate > pixi-build-backends > conda-forge)

### Python (if used in build)

- **Formatter**: Black with 88-character line limit
- **Naming**: PEP 8 (snake_case for functions/variables, PascalCase for classes)
- **Type hints**: Use for function signatures
- **Imports**: Standard library, third-party, local (separated by blank lines)

## Project Structure

```
CodeAccelerate-SYCLBuildKit/
├── packages/
│   ├── adaptivecpp/
│   │   ├── pixi.toml                    # Package config (channels, dependencies, tasks)
│   │   ├── .repos.toml                  # Repository definitions (llvm-project, AdaptiveCpp)
│   │   ├── recipe/
│   │   │   ├── recipe.yaml              # Multi-output recipe (libs, devel, toolkit)
│   │   │   ├── variants.yaml            # Compiler/CUDA constraints
│   │   │   └── scripts/
│   │   │       ├── build.sh             # Build orchestration
│   │   │       ├── activate.sh          # Conda activation script
│   │   │       └── deactivate.sh        # Conda deactivation script
│   │   ├── llvm-project/                # LLVM source (cloned by repos-init)
│   │   ├── build/                       # CMake build artifacts
│   │   └── output/                      # Built .conda packages
│   ├── onemath/
│   │   ├── pixi.toml
│   │   ├── recipe/                      # Shared recipe
│   │   ├── libs/, devel/, onemath/      # Symlink dirs (→ ../recipe)
│   │   └── repo/                        # Git submodule (uxlfoundation/oneMath)
│   └── onedpl/
│       ├── pixi.toml
│       ├── recipe/
│       └── repo/                        # Git submodule (uxlfoundation/oneDPL)
├── docs/                                # Project documentation
└── README.md
```

## Key Build Environment Variables

| Variable           | Set By          | Purpose                                  |
|--------------------|-----------------|------------------------------------------|
| `BUILD_PREFIX`     | rattler-build   | Build-time dependencies location         |
| `PREFIX`           | rattler-build   | Installation prefix for current output   |
| `SRC_DIR`          | rattler-build   | Source directory (dummy, not used)       |
| `RECIPE_DIR`       | rattler-build   | Recipe directory path                    |
| `CPU_COUNT`        | rattler-build   | Number of CPUs for parallel builds       |
| `ACPP_TARGETS`     | Build scripts   | AdaptiveCpp compilation targets (generic)|

## Getting Help

- **Project README**: `/home/jack/sycl-build-project/CodeAccelerate-SYCLBuildKit/README.md`
- **Integration docs**: `ADAPTIVECPP_INTEGRATION.md` (implementation details)
- **Migration plan**: `docs/adaptivecpp-migration-plan.md` (design decisions)
- **Pixi docs**: https://pixi.sh/latest/advanced/pixi_build/
- **Rattler-build docs**: https://prefix-dev.github.io/rattler-build/
- **AdaptiveCpp upstream**: https://github.com/AdaptiveCpp/AdaptiveCpp
- **SYCL spec**: https://registry.khronos.org/SYCL/
