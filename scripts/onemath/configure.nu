#!/usr/bin/env nu
# Configure oneMath (formerly oneMKL Interfaces) for building
# Supports both DPC++ and AdaptiveCpp SYCL implementations

def main [] {
    let source_dir = $env.ONEMATH_SOURCE_DIR
    let build_dir = $env.ONEMATH_BUILD_DIR
    let install_prefix = $env.INSTALL_PREFIX
    
    # Detect SYCL implementation
    let sycl_impl = ($env.SYCL_IMPLEMENTATION? | default "dpcpp")
    let dpcpp_root = ($env.DPCPP_ROOT? | default $install_prefix)

    # Find compiler based on implementation
    let sycl_compiler = if $sycl_impl == "adaptivecpp" {
        $"($dpcpp_root)/bin/acpp"
    } else {
        $"($dpcpp_root)/bin/clang++"
    }
    
    let sycl_c_compiler = if $sycl_impl == "adaptivecpp" {
        $"($dpcpp_root)/bin/acpp"
    } else {
        $"($dpcpp_root)/bin/clang"
    }

    # Verify source exists
    if not ($source_dir | path exists) {
        print $"Error: oneMath source not found at ($source_dir)"
        print "Run: pixi run -e oneapi submodule-init"
        exit 1
    }

    # Verify SYCL compiler is available
    if not ($sycl_compiler | path exists) {
        print $"Error: SYCL compiler not found at ($sycl_compiler)"
        print $"Implementation: ($sycl_impl)"
        print "Either:"
        if $sycl_impl == "adaptivecpp" {
            print "  1. Build and install AdaptiveCpp first: pixi run -e adaptivecpp install"
        } else {
            print "  1. Build and install DPC++ first: pixi run -e llvm install"
        }
        print "  2. Set DPCPP_ROOT to an existing installation"
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
    
    # CMake SYCL implementation flag
    let cmake_sycl_impl = if $sycl_impl == "adaptivecpp" {
        "acpp"
    } else {
        "dpc++"
    }

    print "="
    print "Configuring oneMath"
    print $"  Source: ($source_dir)"
    print $"  Build:  ($build_dir)"
    print $"  Install: ($install_prefix)"
    print $"  SYCL Implementation: ($sycl_impl)"
    print $"  SYCL Compiler: ($sycl_compiler)"
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
        $"-DCMAKE_C_COMPILER=($sycl_c_compiler)"
        $"-DCMAKE_CXX_COMPILER=($sycl_compiler)"
        "-DCMAKE_CXX_COMPILER_LAUNCHER=ccache"
        "-DCMAKE_C_COMPILER_LAUNCHER=ccache"
        
        # SYCL configuration
        $"-DSYCL_IMPLEMENTATION=($cmake_sycl_impl)"
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
