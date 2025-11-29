#!/bin/bash
# Build Intel LLVM/DPC++ for rattler-build

set -exuo pipefail

# Get number of parallel jobs
JOBS="${BUILD_JOBS:-$(nproc)}"

echo "Building Intel LLVM/DPC++ with ${JOBS} parallel jobs..."

# Build main target
cmake --build "${DPCPP_BUILD}" -j "${JOBS}"

echo "Build complete!"
