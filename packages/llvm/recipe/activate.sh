if [ -n "${CONDA_CUDA_ROOT:-}" ]; then
  export CONDA_BACKUP_CUDA_ROOT="$CONDA_CUDA_ROOT"
fi
if [ -n "${CUDA_LIB_PATH:-}" ]; then
  export CONDA_BACKUP_CUDA_LIB_PATH="$CUDA_LIB_PATH"
fi
export CONDA_CUDA_ROOT="$PREFIX/targets/x86_64-linux"
export CUDA_LIB_PATH="$CONDA_CUDA_ROOT/lib/stubs"

if [ "${CONDA_BUILD:-0}" == "1" ]; then
  export CC="${BUILD_PREFIX}/bin/clang"
  export CXX="${BUILD_PREFIX}/bin/clang++"

  sed -i "s|@BUILD_PREFIX@|$BUILD_PREFIX|g" "${BUILD_PREFIX}/bin/${CONDA_TOOLCHAIN_HOST}-clang.cfg"
  sed -i "s|@BUILD_PREFIX@|$BUILD_PREFIX|g" "${BUILD_PREFIX}/bin/${CONDA_TOOLCHAIN_HOST}-clang++.cfg"

  sed -i "s|@PREFIX@|$PREFIX|g" "${BUILD_PREFIX}/bin/${CONDA_TOOLCHAIN_HOST}-clang.cfg"
  sed -i "s|@PREFIX@|$PREFIX|g" "${BUILD_PREFIX}/bin/${CONDA_TOOLCHAIN_HOST}-clang++.cfg"

  sed -i "s|@SYSROOT@|$CONDA_BUILD_SYSROOT|g" "${BUILD_PREFIX}/bin/${CONDA_TOOLCHAIN_HOST}-clang.cfg"
  sed -i "s|@SYSROOT@|$CONDA_BUILD_SYSROOT|g" "${BUILD_PREFIX}/bin/${CONDA_TOOLCHAIN_HOST}-clang++.cfg"
else
  export CC="${CONDA_PREFIX}/bin/clang"
  export CXX="${CONDA_PREFIX}/bin/clang++"

  sed -i "s|@BUILD_PREFIX@|$CONDA_PREFIX|g" "${CONDA_PREFIX}/bin/${CONDA_TOOLCHAIN_HOST}-clang.cfg"
  sed -i "s|@BUILD_PREFIX@|$CONDA_PREFIX|g" "${CONDA_PREFIX}/bin/${CONDA_TOOLCHAIN_HOST}-clang++.cfg"

  sed -i "s|@PREFIX@|$CONDA_PREFIX|g" "${CONDA_PREFIX}/bin/${CONDA_TOOLCHAIN_HOST}-clang.cfg"
  sed -i "s|@PREFIX@|$CONDA_PREFIX|g" "${CONDA_PREFIX}/bin/${CONDA_TOOLCHAIN_HOST}-clang++.cfg"

  sed -i "s|@SYSROOT@|$CONDA_BUILD_SYSROOT|g" "${CONDA_PREFIX}/bin/${CONDA_TOOLCHAIN_HOST}-clang.cfg"
  sed -i "s|@SYSROOT@|$CONDA_BUILD_SYSROOT|g" "${CONDA_PREFIX}/bin/${CONDA_TOOLCHAIN_HOST}-clang++.cfg"
fi
