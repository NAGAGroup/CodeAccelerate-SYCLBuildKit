set -e

if [ "${LINUX_BUILD_ENV_ACTIVE:-0}" != "1" ]; then
  export PROJECT_ROOT="$DPCPP_HOME"
  source "$DPCPP_HOME/activation/linux.sh"
fi

if [ "${DPCPP_BUILD_ENV_ACTIVE:-0}" != "1" ]; then
  if [ -z "$DPCPP_BIN_DIR" ]; then
    export DPCPP_BIN_DIR="$DPCPP_HOME/repo/build"
  fi

  gcc_version=$(gcc -dumpversion)
  gcc_install_dir="$PREFIX/lib/gcc/$CONDA_TOOLCHAIN_HOST/$gcc_version"
  export GCC_INSTALL_DIR="$gcc_install_dir"

  export OCL_ICD_VENDORS="$PREFIX/etc/OpenCL/vendors"

  export DPCPP_BUILD_ENV_ACTIVE=1
fi
