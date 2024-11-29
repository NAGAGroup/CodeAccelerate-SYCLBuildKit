#!/bin/bash

set -e

cd "$PROJECT_ROOT" || exit
cd onemkl/build || exit
cmake --build . -- -j$(nproc)
