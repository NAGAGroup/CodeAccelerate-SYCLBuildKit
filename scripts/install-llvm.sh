#!/bin/bash
set -exuo pipefail

if [ ! -f "$INSTALL_PREFIX/dpcpp/bin/clang" ]; then
  pixi run -e default install
fi
