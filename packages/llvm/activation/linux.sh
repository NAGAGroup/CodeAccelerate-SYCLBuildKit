#!/bin/bash
set -e

if [ "$LINUX_BUILD_ENV_ACTIVE" != "1" ]; then
  if [ -z "$BUILD_PREFIX" ]; then
    export BUILD_PREFIX="$CONDA_PREFIX"
  fi
  if [ -z "$PREFIX" ]; then
    export PREFIX="$CONDA_PREFIX"
  fi
  if [ -z "$INSTALL_PREFIX" ]; then
    export INSTALL_PREFIX="$PREFIX"
  fi
  if [ -z "$CONDA_TOOLCHAIN_HOST" ]; then
    export CONDA_TOOLCHAIN_HOST="$HOST"
  fi
  if [ -z "$PROJECT_ROOT" ]; then
    export PROJECT_ROOT="$SRC_DIR"
  fi

  export CONDA_CUDA_ROOT="$PREFIX/targets/x86_64-linux"
  export CUDA_LIB_PATH="$CONDA_CUDA_ROOT/lib/stubs"

  export CONDA_EXTRA_CFLAGS="--sysroot=$CONDA_BUILD_SYSROOT"
  export CFLAGS="$CONDA_EXTRA_CFLAGS $CFLAGS"
  export CXXFLAGS="$CONDA_EXTRA_CFLAGS $CXXFLAGS"

  export PROJECT_TOOLCHAIN_FILE="$PROJECT_ROOT/../toolchains/linux.cmake"

  export LINUX_BUILD_ENV_ACTIVE=1
fi
