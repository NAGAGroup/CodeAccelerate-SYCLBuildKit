#!/bin/bash
set -exuo pipefail

source "${RECIPE_DIR}/build-activation/llvm.sh"
cp "${DPCPP_HOME}/repo/LICENSE.TXT" "${SRC_DIR}/LICENSE.TXT"

if [ ! -d "${CMAKE_INSTALL_PREFIX}" ]; then
  bash "${DPCPP_HOME}/recipe/scripts/configure.sh"
  bash "${DPCPP_HOME}/recipe/scripts/install.sh"

  # Copy the [de]activate scripts to $PREFIX/etc/conda/[de]activate.d.
  # This will allow them to be run on environment activation.
  CHANGE="activate"
  for CHANGE in "activate" "deactivate"; do
    mkdir -p "${CMAKE_INSTALL_PREFIX}/etc/conda/${CHANGE}.d"
    cp "${RECIPE_DIR}/${CHANGE}.sh" "${CMAKE_INSTALL_PREFIX}/etc/conda/${CHANGE}.d/~100-open-dpcpp-toolkit-${CHANGE}.sh"
  done

  echo "--cuda-path=@PREFIX@/targets/x86_64-linux --sysroot=@SYSROOT@" >"${CMAKE_INSTALL_PREFIX}/bin/${CONDA_TOOLCHAIN_HOST}-clang.cfg"
  echo "--cuda-path=@PREFIX@/targets/x86_64-linux --sysroot=@SYSROOT@" >"${CMAKE_INSTALL_PREFIX}/bin/${CONDA_TOOLCHAIN_HOST}-clang++.cfg"
fi
