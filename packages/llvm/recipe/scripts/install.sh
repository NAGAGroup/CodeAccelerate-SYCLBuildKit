#!/bin/bash
set -exuo pipefail

cmake --build ${DPCPP_BUILD}

cmake --build ${DPCPP_BUILD} --target deploy-sycl-toolchain
cmake --build ${DPCPP_BUILD} --target install
