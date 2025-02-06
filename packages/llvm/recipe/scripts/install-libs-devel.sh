#!/bin/bash
set -exuo pipefail

source "${RECIPE_DIR}/build-activation/llvm.sh"

mkdir -p "${PREFIX}/include"
cp -r "${CMAKE_INSTALL_PREFIX}/include"/* "${PREFIX}/include"
