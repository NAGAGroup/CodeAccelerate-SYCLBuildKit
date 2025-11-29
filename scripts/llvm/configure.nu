#!/usr/bin/env nu
# Configure Intel LLVM/DPC++ for building
# Uses the upstream buildbot/configure.py script with appropriate flags

def main [] {
    let source_dir = $env.LLVM_SOURCE_DIR
    let build_dir = $env.LLVM_BUILD_DIR
    let install_prefix = $env.INSTALL_PREFIX

    # Ensure source exists
    if not ($source_dir | path exists) {
        print $"Error: LLVM source not found at ($source_dir)"
        print "Run: pixi run submodule-init"
        exit 1
    }

    # Create build directory
    mkdir $build_dir

    # Parse backend configuration
    let backends = ($env.SYCL_BACKENDS? | default "opencl;cuda;native_cpu" | split row ";")
    let targets = ($env.LLVM_TARGETS? | default "X86;NVPTX;SPIRV")

    # Build configure.py arguments
    mut args = [
        $"($source_dir)/buildbot/configure.py"
        "-o" $build_dir
        "--cmake-gen=Ninja"
        "--shared-libs"
        "--use-lld"
        "--enable-all-llvm-targets"
    ]

    # Add backend flags
    if "cuda" in $backends {
        $args = ($args | append "--cuda")
    }
    if "native_cpu" in $backends {
        $args = ($args | append "--native_cpu")
    }
    if "hip" in $backends {
        $args = ($args | append "--hip")
    }

    # CMake options (use mut since we may add CUDA path)
    mut cmake_opts = [
        $"-DCMAKE_INSTALL_PREFIX=($install_prefix)"
        "-DCMAKE_C_COMPILER_LAUNCHER=ccache"
        "-DCMAKE_CXX_COMPILER_LAUNCHER=ccache"
        "-DLLVM_INSTALL_UTILS=ON"
        "-DLLVM_UTILS_INSTALL_DIR=libexec/llvm"
        "-DLLVM_LIBDIR_SUFFIX="
    ]

    # Add CUDA path if available
    if ($env.CONDA_PREFIX? | default "" | str length) > 0 {
        let cuda_root = $"($env.CONDA_PREFIX)/targets/x86_64-linux"
        if ($cuda_root | path exists) {
            $cmake_opts = ($cmake_opts | append $"-DCUDAToolkit_ROOT=($cuda_root)")
        }
    }

    # Convert cmake opts to --cmake-opt format
    for opt in $cmake_opts {
        $args = ($args | append $"--cmake-opt=($opt)")
    }

    print "=" 
    print $"Configuring Intel LLVM/DPC++"
    print $"  Source: ($source_dir)"
    print $"  Build:  ($build_dir)"
    print $"  Install: ($install_prefix)"
    print $"  Backends: ($backends | str join ', ')"
    print "="

    # Run configure
    cd $source_dir
    python ...$args

    print "Configuration complete!"
}

main
