#!/usr/bin/env nu
# Install AdaptiveCpp toolchain

def main [] {
    let build_dir = $env.ADAPTIVECPP_BUILD_DIR
    let install_prefix = $env.INSTALL_PREFIX
    let jobs = ($env.BUILD_JOBS? | default "" | if ($in | is-empty) { (nproc) } else { $in | into int })

    if not ($build_dir | path exists) {
        print $"Error: Build directory not found at ($build_dir)"
        print "Run: pixi run -e adaptivecpp build"
        exit 1
    }

    print "="
    print "Installing AdaptiveCpp Toolchain"
    print $"  Build dir: ($build_dir)"
    print $"  Install prefix: ($install_prefix)"
    print "="

    # Create install directory
    mkdir $install_prefix

    # Run cmake install
    print "Running cmake install..."
    cmake --build $build_dir --target install -j $jobs

    # Verify installation
    let acpp_info = $"($install_prefix)/bin/acpp-info"
    if ($acpp_info | path exists) {
        print ""
        print "Installation successful!"
        print $"Toolchain installed to: ($install_prefix)"
        print ""
        print "To use the toolchain, add to your environment:"
        print $"  export PATH=($install_prefix)/bin:$PATH"
        print $"  export LD_LIBRARY_PATH=($install_prefix)/lib:$LD_LIBRARY_PATH"
    } else {
        print "Warning: acpp-info not found in install directory"
        print "Installation may be incomplete"
    }
}

main
