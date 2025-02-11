#!/bin/bash

set -e

mkdir -p "$SUBPROJECT_ROOT/onemkl/build"
cd "$SUBPROJECT_ROOT/onemkl/build"
cmake --build . -- -j8
cmake --install .
