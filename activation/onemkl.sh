set -e

if [ -z "$DPCPP_ROOT" ]; then
  export DPCPP_ROOT="$HOME/dpcpp"
fi

if [ -z "$PIXI_DPCPP_ACTIVE" ]; then
  if [ -z "$SUBPROJECT_ROOT" ]; then
    export SUBPROJECT_ROOT="$PIXI_PROJECT_ROOT/onemkl"
  fi

  source "$DPCPP_ROOT/conda-activate.sh"
  export MKLROOT="$PREFIX"

  export CC="$BUILD_PREFIX/bin/clang"
  export CXX="$BUILD_PREFIX/bin/clang++"
  export CXXFLAGS="$CXXFLAGS -isystem $PREFIX/include/sycl"
  export CFLAGS="$CFLAGS -isystem $PREFIX/include/sycl"

  export OCL_ICD_VENDORS="$PREFIX/etc/OpenCL/vendors"
  export OCL_ICD_FILENAMES=
  export PIXI_DPCPP_ACTIVE=1
fi
