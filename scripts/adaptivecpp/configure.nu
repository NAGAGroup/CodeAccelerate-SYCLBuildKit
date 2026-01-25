#!/usr/bin/env nu
# Configure AdaptiveCpp for building

def main [] {
    let source_dir = $env.ADAPTIVECPP_SOURCE_DIR
    let build_dir = $env.ADAPTIVECPP_BUILD_DIR
    let install_prefix = $env.INSTALL_PREFIX

    # Ensure source exists
    if not ($source_dir | path exists) {
        print $"Error: AdaptiveCpp source not found at ($source_dir)"
        print "Run: pixi run -e adaptivecpp submodule-init"
        exit 1
    }

    # Create build directory
    mkdir $build_dir

    # Parse backend configuration
    let targets = ($env.ACPP_TARGETS? | default "generic")
    
    # Extract relocatable compiler names (basename only, not absolute paths)
    # This allows AdaptiveCpp to find compilers in PATH at runtime
    # Force use of clang compilers (not gcc) for AdaptiveCpp
    let cxx_compiler = if ($env.CXX? | default "" | str contains "clang") {
        ($env.CXX | path basename)
    } else {
        # Force clang if CXX is not already clang
        "x86_64-conda-linux-gnu-clang++"
    }
    
    let c_compiler = if ($env.CC? | default "" | str contains "clang") {
        ($env.CC | path basename)
    } else {
        # Force clang if CC is not already clang
        "x86_64-conda-linux-gnu-clang"
    }

    print $"Using compilers: C=($c_compiler), CXX=($cxx_compiler)"

    # Detect LLVM installation (from conda environment)
    let llvm_dir = if ($env.CONDA_PREFIX? | default "" | str length) > 0 {
        let cmake_dir = $"($env.CONDA_PREFIX)/lib/cmake/llvm"
        if ($cmake_dir | path exists) {
            $cmake_dir
        } else {
            ""
        }
    } else {
        ""
    }
    
    # Find clang executable
    let clang_path = (which clang | get path.0? | default "")

    # CMake options
    mut cmake_opts = [
        "-S" $source_dir
        "-B" $build_dir
        "-G" "Ninja"
        $"-DCMAKE_INSTALL_PREFIX=($install_prefix)"
        $"-DCMAKE_C_COMPILER=($c_compiler)"
        $"-DCMAKE_CXX_COMPILER=($cxx_compiler)"
        "-DCMAKE_C_COMPILER_LAUNCHER=ccache"
        "-DCMAKE_CXX_COMPILER_LAUNCHER=ccache"
        "-DCMAKE_BUILD_TYPE=Release"
        
        # AdaptiveCpp-specific options - generic compilation mode only
        $"-DACPP_TARGETS=($targets)"
        "-DWITH_CUDA_BACKEND=ON"
        "-DWITH_SSCP_COMPILER=ON"  # Single-source compiler
        "-DACPP_COMPILER_FEATURE_PROFILE=full"  # Required for generic backend
        "-DWITH_ACCELERATED_CPU=ON"
        "-DWITH_STDPAR=ON"  # C++17 parallel algorithms
        
        # Use system LLVM for host compilation
        "-DWITH_LLVM_INTEGRATION=ON"
    ]
    
    # Add LLVM paths if found
    if ($llvm_dir | str length) > 0 {
        $cmake_opts = ($cmake_opts | append $"-DLLVM_DIR=($llvm_dir)")
        print $"  LLVM:   ($llvm_dir)"
    }
    
    if ($clang_path | str length) > 0 {
        $cmake_opts = ($cmake_opts | append $"-DCLANG_EXECUTABLE_PATH=($clang_path)")
        print $"  Clang:  ($clang_path)"
    }

    # Add CUDA path if available
    if ($env.CONDA_PREFIX? | default "" | str length) > 0 {
        let cuda_root = $"($env.CONDA_PREFIX)/targets/x86_64-linux"
        if ($cuda_root | path exists) {
            $cmake_opts = ($cmake_opts | append $"-DCUDAToolkit_ROOT=($cuda_root)")
        }
    }

    print "="
    print "Configuring AdaptiveCpp"
    print $"  Source: ($source_dir)"
    print $"  Build:  ($build_dir)"
    print $"  Install: ($install_prefix)"
    print $"  Targets: ($targets)"
    print "="

    # Run cmake
    cmake ...$cmake_opts

    print "Configuration complete!"
}

main
