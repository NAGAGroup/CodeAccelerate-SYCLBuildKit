#!/bin/bash
set -exuo pipefail

mkdir -p "${PREFIX}/include"
cp -r "${RECIPE_DIR}/../install/include"/* "${PREFIX}/include"
