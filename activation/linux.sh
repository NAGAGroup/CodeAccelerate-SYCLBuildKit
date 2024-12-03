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
    export PROJECT_ROOT="$PIXI_PROJECT_ROOT/.."
  fi

  export CONDA_CUDA_ROOT="$PREFIX/targets/x86_64-linux"
  export CUDA_LIB_PATH="$CONDA_CUDA_ROOT/lib/stubs"
  export LD_LIBRARY_PATH="$CONDA_CUDA_ROOT/lib:$CONDA_CUDA_ROOT/lib/stubs:$LD_LIBRARY_PATH"
  export LD_LIBRARY_PATH=${LD_LIBRARY_PATH%:}

  export CONDA_EXTRA_CFLAGS="--sysroot $CONDA_BUILD_SYSROOT -isystem $PREFIX/include -I$CONDA_CUDA_ROOT/include -I$CONDA_BUILD_SYSROOT/usr/include"
  export CFLAGS="$CONDA_EXTRA_CFLAGS"
  export CXXFLAGS="$CONDA_EXTRA_CFLAGS"
  export LDFLAGS="-Wl,-rpath,$PREFIX/lib -Wl,-rpath-link,$PREFIX/lib -L $PREFIX/lib -L $CONDA_CUDA_ROOT/lib -L $CONDA_CUDA_ROOT/lib/stubs -L$CONDA_BUILD_SYSROOT/usr/lib"

  export PROJECT_TOOLCHAIN_FILE="$PROJECT_ROOT/toolchains/linux.cmake"

  export LINUX_BUILD_ENV_ACTIVE=1
fi
