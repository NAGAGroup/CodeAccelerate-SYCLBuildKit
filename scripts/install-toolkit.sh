#!/bin/bash
set -exuo pipefail

pixi run -e default install
pixi run -e onemkl install
