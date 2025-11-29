#!/usr/bin/env nu
# Configure oneMath (formerly oneMKL Interfaces) for building
# Requires a pre-built DPC++ toolchain

def main [] {
    let source_dir = $env.ONEMATH_SOURCE_DIR
    let build_dir = $env.ONEMATH_BUILD_DIR
    let install_prefix = $env.INSTALL_PREFIX
    let dpcpp_root = ($env.DPCPP_ROOT? | default $install_prefix)

    # Verify source exists
    if not ($source_dir | path exists) {
        print $"Error: oneMath source not found at ($source_dir)"
        print "Run: pixi run -e onemath submodule-init"
        exit 1
    }

    # Verify DPC++ is available
    let clang = $"($dpcpp_root)/bin/clang++"
    if not ($clang | path exists) {
        print $"Error: DPC++ not found at ($dpcpp_root)"
        print "Either:"
        print "  1. Build and install DPC++ first: pixi run -e llvm install"
        print "  2. Set DPCPP_ROOT to an existing DPC++ installation"
        exit 1
    }

    # Create build directory
    mkdir $build_dir

    # Backend configuration from environment
    let blas_backends = ($env.ONEMATH_BLAS_BACKENDS? | default "cublas")
    let lapack_backends = ($env.ONEMATH_LAPACK_BACKENDS? | default "cusolver")
    let rng_backends = ($env.ONEMATH_RNG_BACKENDS? | default "curand")
    let dft_backends = ($env.ONEMATH_DFT_BACKENDS? | default "cufft")
    let sparse_backends = ($env.ONEMATH_SPARSE_BACKENDS? | default "cusparse")

    # CUDA root from conda environment
    let cuda_root = ($env.CUDA_ROOT? | default $"($env.CONDA_PREFIX)/targets/x86_64-linux")

    print "="
    print "Configuring oneMath"
    print $"  Source: ($source_dir)"
    print $"  Build:  ($build_dir)"
    print $"  Install: ($install_prefix)"
    print $"  DPC++: ($dpcpp_root)"
    print ""
    print "  Backends:"
    print $"    BLAS:   ($blas_backends)"
    print $"    LAPACK: ($lapack_backends)"
    print $"    RNG:    ($rng_backends)"
    print $"    DFT:    ($dft_backends)"
    print $"    SPARSE: ($sparse_backends)"
    print "="

    # CMake configuration
    let cmake_args = [
        "-S" $source_dir
        "-B" $build_dir
        "-G" "Ninja"
        $"-DCMAKE_INSTALL_PREFIX=($install_prefix)"
        $"-DCMAKE_C_COMPILER=($dpcpp_root)/bin/clang"
        $"-DCMAKE_CXX_COMPILER=($dpcpp_root)/bin/clang++"
        "-DCMAKE_CXX_COMPILER_LAUNCHER=ccache"
        "-DCMAKE_C_COMPILER_LAUNCHER=ccache"
        
        # SYCL configuration
        "-DSYCL_IMPLEMENTATION=dpc++"
        "-DENABLE_SYCL=ON"
        
        # Target device (NVIDIA GPU via CUDA)
        "-DTARGET_DOMAINS=blas;lapack;rng;dft;sparse_blas"
        
        # Backend selection
        $"-DENABLE_CUBLAS_BACKEND=($blas_backends | str contains 'cublas')"
        $"-DENABLE_CUSOLVER_BACKEND=($lapack_backends | str contains 'cusolver')"
        $"-DENABLE_CURAND_BACKEND=($rng_backends | str contains 'curand')"
        $"-DENABLE_CUFFT_BACKEND=($dft_backends | str contains 'cufft')"
        $"-DENABLE_CUSPARSE_BACKEND=($sparse_backends | str contains 'cusparse')"
        
        # CUDA configuration
        $"-DCUDAToolkit_ROOT=($cuda_root)"
        
        # Build options
        "-DBUILD_SHARED_LIBS=ON"
        "-DBUILD_FUNCTIONAL_TESTS=OFF"
        "-DBUILD_EXAMPLES=OFF"
        "-DBUILD_DOC=OFF"
    ]

    # Set up environment for cmake
    with-env {
        PATH: $"($dpcpp_root)/bin:($env.PATH)"
        LD_LIBRARY_PATH: $"($dpcpp_root)/lib:($env.LD_LIBRARY_PATH? | default '')"
    } {
        cmake ...$cmake_args
    }

    print "Configuration complete!"
}

main
