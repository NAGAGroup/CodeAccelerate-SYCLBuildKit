#!/usr/bin/env nu
# Install Intel LLVM/DPC++ toolchain

def main [] {
    let build_dir = $env.LLVM_BUILD_DIR
    let install_prefix = $env.INSTALL_PREFIX
    let jobs = ($env.BUILD_JOBS? | default "" | if ($in | is-empty) { (nproc) } else { $in | into int })

    if not ($build_dir | path exists) {
        print $"Error: Build directory not found at ($build_dir)"
        print "Run: pixi run build"
        exit 1
    }

    print "="
    print $"Installing Intel LLVM/DPC++ Toolchain"
    print $"  Build dir: ($build_dir)"
    print $"  Install prefix: ($install_prefix)"
    print "="

    # Create install directory
    mkdir $install_prefix

    # Build deploy-sycl-toolchain target (includes all runtime components)
    print "Building deploy-sycl-toolchain..."
    cmake --build $build_dir --target deploy-sycl-toolchain -j $jobs

    # Run cmake install
    print "Running cmake install..."
    cmake --build $build_dir --target install -j $jobs

    # Verify installation
    let sycl_ls = $"($install_prefix)/bin/sycl-ls"
    if ($sycl_ls | path exists) {
        print ""
        print "Installation successful!"
        print $"Toolchain installed to: ($install_prefix)"
        print ""
        print "To use the toolchain, add to your environment:"
        print $"  export PATH=($install_prefix)/bin:$PATH"
        print $"  export LD_LIBRARY_PATH=($install_prefix)/lib:$LD_LIBRARY_PATH"
    } else {
        print "Warning: sycl-ls not found in install directory"
        print "Installation may be incomplete"
    }
}

main
