#!/bin/bash
set -exuo pipefail

mkdir -p "${PREFIX}/bin"
mkdir -p "${PREFIX}/libexec"
mkdir -p "${PREFIX}/share"
mkdir -p "${PREFIX}/etc"

cp -r "${RECIPE_DIR}/../install/bin"/* "${PREFIX}/bin"
cp -r "${RECIPE_DIR}/../install/libexec"/* "${PREFIX}/libexec"
cp -r "${RECIPE_DIR}/../install/share"/* "${PREFIX}/share"
cp -r "${RECIPE_DIR}/../install/etc"/* "${PREFIX}/etc"
