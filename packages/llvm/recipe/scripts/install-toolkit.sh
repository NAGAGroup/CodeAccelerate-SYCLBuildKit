#!/bin/bash
# Install full toolkit for sycl-dpcpp-toolkit package
set -exuo pipefail

INSTALL_DIR="${RECIPE_DIR}/../install"

# Create target directories
mkdir -p "${PREFIX}/bin"
mkdir -p "${PREFIX}/libexec"
mkdir -p "${PREFIX}/share"
mkdir -p "${PREFIX}/etc"

# Copy binaries (compiler, tools)
if [ -d "${INSTALL_DIR}/bin" ]; then
    cp -r "${INSTALL_DIR}/bin"/* "${PREFIX}/bin/"
fi

# Copy libexec (LLVM utilities)
if [ -d "${INSTALL_DIR}/libexec" ]; then
    cp -r "${INSTALL_DIR}/libexec"/* "${PREFIX}/libexec/"
fi

# Copy share (clang resources, etc.)
if [ -d "${INSTALL_DIR}/share" ]; then
    cp -r "${INSTALL_DIR}/share"/* "${PREFIX}/share/"
fi

# Copy etc (activation scripts, OpenCL vendors)
if [ -d "${INSTALL_DIR}/etc" ]; then
    cp -r "${INSTALL_DIR}/etc"/* "${PREFIX}/etc/"
fi

# Fix clang config files to use conda prefix
for cfg in "${PREFIX}/bin"/*.cfg; do
    if [ -f "$cfg" ]; then
        sed -i "s|@PREFIX@|\${CONDA_PREFIX}|g" "$cfg"
        sed -i "s|@SYSROOT@|\${CONDA_BUILD_SYSROOT}|g" "$cfg"
    fi
done

echo "Installed toolkit to ${PREFIX}"
