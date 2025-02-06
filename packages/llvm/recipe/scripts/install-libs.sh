#!/bin/bash
set -exuo pipefail

source "${RECIPE_DIR}/build-activation/llvm.sh"

mkdir -p "${PREFIX}/lib"
cp -r "${CMAKE_INSTALL_PREFIX}/lib"/* "${PREFIX}/lib"
