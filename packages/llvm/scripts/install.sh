#!/bin/bash

set -e

cd "$DPCPP_HOME"
python repo/buildbot/compile.py -o "$DPCPP_BIN_DIR"
cmake --build "$DPCPP_BIN_DIR"
cmake --build "$DPCPP_BIN_DIR" --target install

touch "$DPCPP_HOME/build/install.stamp"
