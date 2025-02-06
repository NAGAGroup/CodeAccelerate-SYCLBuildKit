#!/bin/bash
set -exuo pipefail

if [[ ${CONDA_BUILD_CROSS_COMPILATION:-0} == "1" ]]; then
  echo "Cross-compilation is not supported at the moment."
  exit 1
fi

conda_extra_cflags="--sysroot=${CONDA_BUILD_SYSROOT} --gcc-install-dir=$GCC_INSTALL_DIR"
clang_ldflags="-Wl,-rpath,${PREFIX}/lib -Wl,-rpath-link,${PREFIX}/lib -L${PREFIX}/lib -Wl,-rpath,${DPCPP_BUILD}/lib -Wl,-rpath-link,${DPCPP_BUILD}/lib -L${DPCPP_BUILD}/lib -L${CONDA_CUDA_ROOT}/lib -L${CONDA_CUDA_ROOT}/lib/stubs"

mkdir -p "${DPCPP_BUILD}/bin"
cd "${DPCPP_BUILD}"
find "${DPCPP_BUILD}" -type f -name 'CMakeCache.txt' -exec rm -f {} \;

echo "$conda_extra_cflags" >"${DPCPP_BUILD}/bin/${CONDA_TOOLCHAIN_HOST}-clang++.cfg"
echo "$conda_extra_cflags" >"${DPCPP_BUILD}/bin/${CONDA_TOOLCHAIN_HOST}-clang-cpp.cfg"
echo "$conda_extra_cflags" >"${DPCPP_BUILD}/bin/${CONDA_TOOLCHAIN_HOST}-clang.cfg"

echo "$clang_ldflags" >>"${DPCPP_BUILD}/bin/${CONDA_TOOLCHAIN_HOST}-clang++.cfg"
echo "$clang_ldflags" >>"${DPCPP_BUILD}/bin/${CONDA_TOOLCHAIN_HOST}-clang-cpp.cfg"
echo "$clang_ldflags" >>"${DPCPP_BUILD}/bin/${CONDA_TOOLCHAIN_HOST}-clang.cfg"

cmake_args=(
  -DCMAKE_INSTALL_PREFIX="${CMAKE_INSTALL_PREFIX}"
  -DCMAKE_C_COMPILER_LAUNCHER=ccache
  -DCMAKE_CXX_COMPILER_LAUNCHER=ccache
  -DLLVM_DEFAULT_TARGET_TRIPLE="${CONDA_TOOLCHAIN_HOST}"
  -DLLVM_HOST_TRIPLE="${CONDA_TOOLCHAIN_HOST}"
  -DLLVM_INSTALL_UTILS=ON
  -DLLVM_UTILS_INSTALL_DIR=libexec/llvm
  -DLLVM_LIBDIR_SUFFIX="")

# iterate through $CMAKE_ARGS and convert to --cmake-opt format
cmake_opts=""
for arg in "${cmake_args[@]}"; do
  cmake_opt="--cmake-opt=${arg}"
  cmake_opts="${cmake_opts} ${cmake_opt}"
done

# for arg in ${CMAKE_ARGS}; do
#   cmake_opt="--cmake-opt=${arg}"
#   cmake_opts="${cmake_opts} ${cmake_opt}"
# done

configure_cmd="python ${SRC_DIR}/buildbot/configure.py -w ${DPCPP_HOME} -s ${SRC_DIR} -o ${DPCPP_BUILD} 
    --enable-all-llvm-targets 
    --shared-libs 
    --llvm-external-projects=clang-tools-extra 
    --use-lld 
    --cuda 
    --native_cpu 
    --cmake-gen=Ninja ${cmake_opts}"

echo "Running: ${configure_cmd}"

$configure_cmd
