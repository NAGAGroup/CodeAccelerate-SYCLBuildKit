#!/bin/bash
set -exuo pipefail

source "${RECIPE_DIR}/build-activation/llvm.sh"

mkdir -p "${PREFIX}/bin"
mkdir -p "${PREFIX}/libexec"
mkdir -p "${PREFIX}/share"
mkdir -p "${PREFIX}/etc"

cp -r "${CMAKE_INSTALL_PREFIX}/bin"/* "${PREFIX}/bin"
cp -r "${CMAKE_INSTALL_PREFIX}/libexec"/* "${PREFIX}/libexec"
cp -r "${CMAKE_INSTALL_PREFIX}/share"/* "${PREFIX}/share"
cp -r "${CMAKE_INSTALL_PREFIX}/etc"/* "${PREFIX}/etc"
