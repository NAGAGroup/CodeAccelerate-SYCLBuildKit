set -e

if [ -z "$DPCPP_ROOT" ]; then
  export DPCPP_ROOT="$HOME/dpcpp"
fi

if [ -z "$PIXI_DPCPP_ACTIVE" ]; then
  source "$DPCPP_ROOT/conda-activate.sh"
  export CC="$BUILD_PREFIX/bin/clang"
  export CXX="$BUILD_PREFIX/bin/clang++"
  export OCL_ICD_VENDORS="$PREFIX/etc/OpenCL/vendors"
  export PIXI_DPCPP_ACTIVE=1
fi
