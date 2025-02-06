set -e

export DPCPP_HOME=${RECIPE_DIR}/..
export DPCPP_BUILD="${DPCPP_HOME}/build"
if [ "${LINUX_BUILD_ENV_ACTIVE:-0}" != "1" ]; then
  source "${DPCPP_HOME}/recipe/build-activation/linux.sh"
fi

if [ "${DPCPP_BUILD_ENV_ACTIVE:-0}" != "1" ]; then
  gcc_version=$(gcc -dumpversion)
  gcc_install_dir="${PREFIX}/lib/gcc/${CONDA_TOOLCHAIN_HOST}/${gcc_version}"
  export GCC_INSTALL_DIR="${gcc_install_dir}"

  export OCL_ICD_VENDORS="${PREFIX}/etc/OpenCL/vendors"

  export DPCPP_BUILD_ENV_ACTIVE=1
fi
