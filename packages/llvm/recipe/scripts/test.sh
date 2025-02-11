#!/bin/bash
set -x

source "${RECIPE_DIR}/activate-build.sh"

cd "${LLVM_SYCL_SOURCE_DIR}"

bash scripts/test.sh
