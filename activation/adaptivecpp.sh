#!/bin/bash
# AdaptiveCpp build environment activation for local development
# (Not used by rattler-build recipe - only for `pixi run -e adaptivecpp` tasks)

# Source base linux environment first
source "${PIXI_PROJECT_ROOT}/activation/linux.sh"

if [ "${ADAPTIVECPP_BUILD_ENV_ACTIVE:-0}" != "1" ]; then
    # AdaptiveCpp source and build directories
    export ADAPTIVECPP_SOURCE_DIR="${ADAPTIVECPP_SOURCE_DIR:-${PROJECT_ROOT}/packages/adaptivecpp/repo}"
    export ADAPTIVECPP_BUILD_DIR="${ADAPTIVECPP_BUILD_DIR:-${PROJECT_ROOT}/build/adaptivecpp}"

    # Default backend configuration
    export ACPP_BACKENDS="${ACPP_BACKENDS:-cuda;omp}"
    export ACPP_TARGETS="${ACPP_TARGETS:-cuda:sm_80;generic}"

    export ADAPTIVECPP_BUILD_ENV_ACTIVE=1
fi
