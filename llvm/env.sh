set -e

if [ "$DPCPP_BUILD_ENV_ACTIVE" != "1" ]; then
  if [ -z "$SUBPROJECT_ROOT" ]; then
    export SUBPROJECT_ROOT="$PIXI_PROJECT_ROOT"
  fi
  if [ -z "$LLVM_SYCL_SOURCE_DIR" ]; then
    export LLVM_SYCL_SOURCE_DIR="$SUBPROJECT_ROOT/llvm"
    export LLVM_SYCL_BUILD_DIR="$PREFIX"
  fi

  # cflags="${CFLAGS/-fno-plt /}"
  # export CFLAGS="$cflags"
  # cxxflags="${CXXFLAGS/-fno-plt /}"
  # export CXXFLAGS="$cxxflags"
  # export CFLAGS="-isystem $PREFIX/include -isystem $CONDA_CUDA_ROOT/include"
  # export CXXFLAGS="$CFLAGS"
  # export LDFLAGS="-Wl,-rpath,$PREFIX/lib -Wl,-rpath-link,$PREFIX/lib -L $PREFIX/lib -L $CONDA_CUDA_ROOT/lib -L $CONDA_CUDA_ROOT/lib/stubs"

  export OCL_ICD_VENDORS="$PREFIX/etc/OpenCL/vendors"

  export DPCPP_BUILD_ENV_ACTIVE=1
fi
