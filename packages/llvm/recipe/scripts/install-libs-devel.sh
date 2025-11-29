#!/bin/bash
# Install development files for sycl-dpcpp-libs-devel package
set -exuo pipefail

INSTALL_DIR="${RECIPE_DIR}/../install"

# Create target directories
mkdir -p "${PREFIX}/include"
mkdir -p "${PREFIX}/lib"

# Copy headers
if [ -d "${INSTALL_DIR}/include" ]; then
    cp -r "${INSTALL_DIR}/include"/* "${PREFIX}/include/"
fi

# Copy static libraries and CMake/pkg-config files
if [ -d "${INSTALL_DIR}/lib" ]; then
    # Static libraries
    find "${INSTALL_DIR}/lib" -maxdepth 1 -name "*.a" -exec cp {} "${PREFIX}/lib/" \;
    
    # CMake modules
    if [ -d "${INSTALL_DIR}/lib/cmake" ]; then
        mkdir -p "${PREFIX}/lib/cmake"
        cp -r "${INSTALL_DIR}/lib/cmake"/* "${PREFIX}/lib/cmake/"
    fi
    
    # pkg-config files
    if [ -d "${INSTALL_DIR}/lib/pkgconfig" ]; then
        mkdir -p "${PREFIX}/lib/pkgconfig"
        cp -r "${INSTALL_DIR}/lib/pkgconfig"/* "${PREFIX}/lib/pkgconfig/"
    fi
fi

echo "Installed development files to ${PREFIX}"
