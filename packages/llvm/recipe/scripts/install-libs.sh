#!/bin/bash
# Install runtime libraries for sycl-dpcpp-libs package
set -exuo pipefail

INSTALL_DIR="${RECIPE_DIR}/../install"

# Create target directories
mkdir -p "${PREFIX}/lib"

# Copy shared libraries
if [ -d "${INSTALL_DIR}/lib" ]; then
    # Copy all .so files (runtime libraries)
    find "${INSTALL_DIR}/lib" -maxdepth 1 -name "*.so*" -exec cp -P {} "${PREFIX}/lib/" \;
    
    # Copy SYCL-specific library directories
    for subdir in sycl; do
        if [ -d "${INSTALL_DIR}/lib/${subdir}" ]; then
            cp -r "${INSTALL_DIR}/lib/${subdir}" "${PREFIX}/lib/"
        fi
    done
fi

echo "Installed runtime libraries to ${PREFIX}/lib"
