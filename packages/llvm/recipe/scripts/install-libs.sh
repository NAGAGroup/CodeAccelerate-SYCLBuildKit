#!/bin/bash
set -exuo pipefail

mkdir -p "${PREFIX}/lib"
cp -r "${RECIPE_DIR}/../install/lib"/* "${PREFIX}/lib"
