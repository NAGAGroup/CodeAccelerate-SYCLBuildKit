set -e

if [ "$DPCPP_BUILD_ENV_ACTIVE" != "1" ]; then
  if [ -z "$SUBPROJECT_ROOT" ]; then
    export SUBPROJECT_ROOT="$PIXI_PROJECT_ROOT"
  fi
  if [ -z "$LLVM_SYCL_SOURCE_DIR" ]; then
    export LLVM_SYCL_SOURCE_DIR="$SUBPROJECT_ROOT/llvm"
  fi
  export DPCPP_BUILD_ENV_ACTIVE=1
fi
