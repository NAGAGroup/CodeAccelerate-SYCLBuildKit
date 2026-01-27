# AGENTS.md - AI Coding Agent Guide

## Project Overview

**CodeAccelerate-SYCLBuildKit** builds relocatable SYCL compiler toolchains based on AdaptiveCPP (formerly hipSYCL).

- **Tech stack**: AdaptiveCPP, oneAPI Math/DPL, pixi (conda)
- **Targets**: Linux x64, SYCL backends (CUDA, OpenCL, Native CPU)
- **Build system**: CMake + Ninja, orchestrated via per-package pixi tasks

## Critical Notes for AI Agents

1. **Per-package workflow**: Each package is built independently from its own directory
2. **Always use pixi**: Commands run from package directories: `cd packages/<name> && pixi run <task>`
3. **Check available tasks**: Use `pixi task list` within each package to see available commands
4. **Incremental builds work**: CMake/Ninja handle incremental builds; full rebuilds rarely needed
5. **Ccache enabled**: Automatic caching speeds up recompilation (when configured in package)
6. **Path validation**: Build scripts check paths rigorously; follow this pattern in new scripts
7. **Error messages**: Always include recovery suggestions (e.g., "Run: pixi run repos-init")
8. **Git submodules**: Package repos (e.g., `packages/adaptivecpp/repo`) are submodules; don't modify `.git` directly
9. **Test after changes**: Run package-specific tests after code modifications
10. **Parallelism**: Builds use all cores by default; override with `BUILD_JOBS` if needed

## Quick Start Commands

### Check Available Tasks

Each package has different tasks available. Always check first:

```bash
cd packages/adaptivecpp
pixi task list                   # Show available tasks for this package
```

### Current Package Tasks (as of Jan 2026)

**adaptivecpp**:
```bash
cd packages/adaptivecpp
pixi run repos-init              # Initialize AdaptiveCPP source repository
# Additional tasks: Use pixi task list to see all available commands
```

**onemath**:
```bash
cd packages/onemath
pixi run setup                   # Setup onemath build (may include submodule-init)
pixi run submodule-init          # Initialize source repositories (if needed separately)
# Additional tasks: Use pixi task list to see all available commands
```

**onedpl**:
```bash
cd packages/onedpl
pixi run submodule-init          # Initialize source repositories
# Additional tasks: Use pixi task list to see all available commands
```

> **Note**: Package tasks are actively being developed. The examples above show tasks that existed at time of writing. Always run `pixi task list` to see the current available commands for a package.

## Running Tests and Development Commands

### Manual SYCL test compilation (example for debugging):

```bash
cd packages/adaptivecpp
# Assuming package has build/install tasks configured
pixi shell                       # Enter package environment
# Inside pixi shell, environment variables are available
echo '#include <sycl/sycl.hpp>
int main() { return 0; }' > build/test/my_test.cpp
$INSTALL_PREFIX/bin/acpp -o build/test/my_test build/test/my_test.cpp
./build/test/my_test
exit                             # Exit pixi shell
```

### Running package test suite (when available):

```bash
cd packages/adaptivecpp
pixi shell
# Assuming ADAPTIVECPP_BUILD_DIR is set by package environment
cd $ADAPTIVECPP_BUILD_DIR
ctest --output-on-failure        # All tests
ctest -R sycl                    # SYCL-specific tests
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

**Quality Checks** (run within package environment):
```bash
cd packages/adaptivecpp
pixi shell
clang-format -i modified_files.cpp
clang-tidy path/to/file.cpp -- -I$ADAPTIVECPP_SOURCE_DIR/include
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
    print "Run: pixi run repos-init"
    exit 1
}
```

### Configuration Files (TOML/YAML)

- **Task names**: `kebab-case` (e.g., `repos-init`, `submodule-init`)
- **Env vars**: `UPPER_SNAKE_CASE`

## Project Structure

```
CodeAccelerate-SYCLBuildKit/
├── packages/
│   ├── adaptivecpp/
│   │   ├── pixi.toml              # AdaptiveCPP package configuration & tasks
│   │   ├── repo/                  # AdaptiveCPP source (git submodule)
│   │   │   └── tests/             # AdaptiveCPP test suite
│   │   └── build/                 # CMake build artifacts (gitignored)
│   ├── onemath/
│   │   ├── pixi.toml              # onemath package configuration & tasks
│   │   └── repo/                  # onemath source (git submodule)
│   └── onedpl/
│       ├── pixi.toml              # onedpl package configuration & tasks
│       └── repo/                  # onedpl source (git submodule)
├── docs/                          # Project documentation
├── .gitmodules                    # Git submodule configuration
└── README.md                      # Project overview
```

## Key Environment Variables

Environment variables are configured per-package in each `pixi.toml`. Common variables include:

| Variable                  | Typical Default                      | Purpose                      |
|---------------------------|--------------------------------------|------------------------------|
| `INSTALL_PREFIX`          | `$HOME/.local/naga-sycl-toolkit`     | Installation directory       |
| `ADAPTIVECPP_SOURCE_DIR`  | `./repo`                             | Package source directory     |
| `ADAPTIVECPP_BUILD_DIR`   | `./build`                            | CMake build directory        |
| `ACPP_TARGETS`            | `generic`                            | AdaptiveCPP target architectures |
| `BUILD_JOBS`              | (auto-detected via `nproc`)          | Parallel build jobs          |

**Override in shell**:
```bash
cd packages/adaptivecpp
export BUILD_JOBS=16
pixi run <task>
```

**Access within pixi shell**:
```bash
cd packages/adaptivecpp
pixi shell
echo $INSTALL_PREFIX            # Environment variables are available
```

## Common Workflows

### Initial setup (first time):

```bash
# Initialize each package's source repositories
cd packages/adaptivecpp && pixi run repos-init
cd ../onemath && pixi run setup  # or submodule-init, check pixi task list
cd ../onedpl && pixi run submodule-init
```

### Incremental development (when build tasks exist):

```bash
cd packages/adaptivecpp
# Edit code in repo/...
pixi run build                   # Incremental rebuild (when task exists)
pixi run install                 # Update installation (when task exists)
pixi run test                    # Verification (when task exists)
```

### Building multiple packages (example workflow):

```bash
# AdaptiveCPP first (required by other packages)
cd packages/adaptivecpp
pixi run repos-init
# Run build/install tasks once they're configured in pixi.toml

# Then onemath
cd ../onemath
pixi run setup
# Run build/install tasks once they're configured

# Then onedpl
cd ../onedpl
pixi run submodule-init
# Run build tasks once they're configured
```

## Getting Help

- **Project README**: `/home/jack/sycl-build-project/CodeAccelerate-SYCLBuildKit/README.md`
- **Package-specific docs**: Check `packages/<name>/README.md` if available
- **Package tasks**: Run `pixi task list` within each package directory
- **AdaptiveCPP upstream**: https://github.com/AdaptiveCpp/AdaptiveCpp
- **SYCL spec**: https://registry.khronos.org/SYCL/
- **Pixi docs**: https://pixi.sh/
