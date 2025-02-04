set -e

if [ "${LINUX_BUILD_ENV_ACTIVE:-0}" != "1" ]; then
  if [ -z "${SRC_DIR:-}" ]; then
    SRC_DIR="${PROJECT_ROOT}"
  fi
  source "$SRC_DIR/activation/linux.sh"
fi

if [ "${DPCPP_BUILD_ENV_ACTIVE:-0}" != "1" ]; then
  if [ -z "$DPCPP_HOME" ]; then
    export DPCPP_HOME="$PROJECT_ROOT"
  fi
  if [ -z "$DPCPP_BIN_DIR" ]; then
    export DPCPP_BIN_DIR="$DPCPP_HOME/build"
  fi

  gcc_version=$(gcc -dumpversion)
  gcc_install_dir="$PREFIX/lib/gcc/$CONDA_TOOLCHAIN_HOST/$gcc_version"
  export GCC_INSTALL_DIR="$gcc_install_dir"

  export OCL_ICD_VENDORS="$PREFIX/etc/OpenCL/vendors"

  export DPCPP_BUILD_ENV_ACTIVE=1
fi
