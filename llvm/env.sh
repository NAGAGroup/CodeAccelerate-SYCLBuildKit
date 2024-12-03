set -e

if [ "$DPCPP_BUILD_ENV_ACTIVE" != "1" ]; then
  if [ -z "$SUBPROJECT_ROOT" ]; then
    export SUBPROJECT_ROOT="$PIXI_PROJECT_ROOT"
  fi
  if [ -z "$LLVM_SYCL_SOURCE_DIR" ]; then
    export LLVM_SYCL_SOURCE_DIR="$SUBPROJECT_ROOT/llvm"
    export LLVM_SYCL_BUILD_DIR="$LLVM_SYCL_SOURCE_DIR/build"
  fi

  gcc_version=$(gcc -dumpversion)
  gcc_install_dir="$PREFIX/lib/gcc/$CONDA_TOOLCHAIN_HOST/$gcc_version"
  export GCC_INSTALL_DIR="$gcc_install_dir"

  export OCL_ICD_VENDORS="$PREFIX/etc/OpenCL/vendors"

  export DPCPP_BUILD_ENV_ACTIVE=1
fi
