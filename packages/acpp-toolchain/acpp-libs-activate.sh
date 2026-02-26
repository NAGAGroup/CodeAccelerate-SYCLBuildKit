#!/usr/bin/env bash
# etc/conda/activate.d/acpp-device-libs.sh

ACPP_EXT_BITCODE="${CONDA_PREFIX}/lib/hipSYCL/ext/bitcode"

# CUDA libdevice
if [ -f "${CONDA_PREFIX}/nvvm/libdevice/libdevice.10.bc" ]; then
  mkdir -p "${ACPP_EXT_BITCODE}/ptx"
  ln -sf "${CONDA_PREFIX}/nvvm/libdevice/libdevice.10.bc" \
    "${ACPP_EXT_BITCODE}/ptx/libdevice.10.bc"
fi

# ROCm device libs
if [ -d "${CONDA_PREFIX}/lib/ockl.bc" ] || [ -f "${CONDA_PREFIX}/lib/ockl.bc" ]; then
  mkdir -p "${ACPP_EXT_BITCODE}/amdgcn"
  ln -sf "${CONDA_PREFIX}/lib/"*.bc "${ACPP_EXT_BITCODE}/amdgcn/"
fi
