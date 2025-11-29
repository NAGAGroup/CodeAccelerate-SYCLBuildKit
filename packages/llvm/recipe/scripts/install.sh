#!/bin/bash
# Install Intel LLVM/DPC++ for rattler-build

set -exuo pipefail

JOBS="${BUILD_JOBS:-$(nproc)}"

echo "Installing Intel LLVM/DPC++ toolchain..."

# Build deploy-sycl-toolchain target (includes all runtime components)
cmake --build "${DPCPP_BUILD}" --target deploy-sycl-toolchain -j "${JOBS}"

# Run cmake install
cmake --build "${DPCPP_BUILD}" --target install -j "${JOBS}"

echo "Install complete!"
