set -e

if [ "$DPCPP_BUILD_ENV_ACTIVE" != "1" ]; then
  if [ -z "$SUBPROJECT_ROOT" ]; then
    export SUBPROJECT_ROOT="$PIXI_PROJECT_ROOT"
  fi
  if [ -z "$LLVM_SYCL_SOURCE_DIR" ]; then
    export LLVM_SYCL_SOURCE_DIR="$SUBPROJECT_ROOT/llvm"
    export LLVM_SYCL_BUILD_DIR="$LLVM_SYCL_SOURCE_DIR/build"
  fi

  export OCL_ICD_VENDORS="$PREFIX/etc/OpenCL/vendors"

  export DPCPP_BUILD_ENV_ACTIVE=1
fi
