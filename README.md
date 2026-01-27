# CodeAccelerate-SYCLBuildKit

Build open-source, relocatable SYCL toolchains with ease, putting the "Accelerate" into your CodeAccelerate++ devenv.

## Quick Start

Each package is built independently from its own directory. Use `pixi task list` within each package to see available commands.

### Initial Setup

```bash
# Initialize AdaptiveCPP SYCL compiler
cd packages/adaptivecpp
pixi task list               # See available tasks
pixi run repos-init          # Initialize source repository

# Initialize oneAPI Math libraries
cd ../onemath
pixi task list               # See available tasks
pixi run setup               # Setup package (includes initialization)

# Initialize oneAPI DPL
cd ../onedpl
pixi task list               # See available tasks
pixi run submodule-init      # Initialize source repository
```

### Building (once build tasks are configured)

Check each package's `pixi.toml` for available build, install, and test tasks:

```bash
cd packages/adaptivecpp
pixi run build               # Build (when task exists)
pixi run install             # Install to $INSTALL_PREFIX (when task exists)
```

### Installation Location

By default, toolchains are installed to `$HOME/.local/naga-sycl-toolkit` (configurable via `INSTALL_PREFIX` in package `pixi.toml`).

To use the installed compiler:
```bash
export PATH=$HOME/.local/naga-sycl-toolkit/bin:$PATH
acpp --version               # Verify installation
```

## Documentation

- **AGENTS.md**: Detailed guide for AI coding agents and developers
- **docs/**: Additional project documentation

## Requirements

- [Pixi](https://pixi.sh/) package manager (installs all build dependencies)
- Linux x64 system
- Git (for submodule management)
