#!/bin/bash
# Configure Intel LLVM/DPC++ for rattler-build
# Uses the upstream buildbot/configure.py script

set -exuo pipefail

# Block cross-compilation (not supported)
if [[ ${CONDA_BUILD_CROSS_COMPILATION:-0} == "1" ]]; then
    echo "Cross-compilation is not supported."
    exit 1
fi

# Create build directory
mkdir -p "${DPCPP_BUILD}"
cd "${DPCPP_BUILD}"

# Clean any stale CMake cache
find "${DPCPP_BUILD}" -type f -name 'CMakeCache.txt' -exec rm -f {} \; 2>/dev/null || true

# CMake arguments
cmake_args=(
    -DCMAKE_INSTALL_PREFIX="${CMAKE_INSTALL_PREFIX}"
    -DCMAKE_C_COMPILER_LAUNCHER=ccache
    -DCMAKE_CXX_COMPILER_LAUNCHER=ccache
    -DLLVM_DEFAULT_TARGET_TRIPLE="${CONDA_TOOLCHAIN_HOST}"
    -DLLVM_HOST_TRIPLE="${CONDA_TOOLCHAIN_HOST}"
    -DLLVM_INSTALL_UTILS=ON
    -DLLVM_UTILS_INSTALL_DIR=libexec/llvm
    -DLLVM_LIBDIR_SUFFIX=
    -DCUDAToolkit_ROOT="${CUDA_ROOT}"
)

# Convert to --cmake-opt format for configure.py
cmake_opts=""
for arg in "${cmake_args[@]}"; do
    cmake_opts="${cmake_opts} --cmake-opt=${arg}"
done

# Build the configure command
configure_cmd="python ${SRC_DIR}/buildbot/configure.py \
    -w ${DPCPP_HOME} \
    -s ${SRC_DIR} \
    -o ${DPCPP_BUILD} \
    --enable-all-llvm-targets \
    --shared-libs \
    --llvm-external-projects=clang-tools-extra \
    --use-lld \
    --use-zstd \
    --cuda \
    --native_cpu \
    --cmake-gen=Ninja \
    ${cmake_opts}"

echo "Running: ${configure_cmd}"
${configure_cmd}
