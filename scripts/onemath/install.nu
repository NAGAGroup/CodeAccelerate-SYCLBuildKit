#!/usr/bin/env nu
# Install oneMath

def main [] {
    let build_dir = $env.ONEMATH_BUILD_DIR
    let install_prefix = $env.INSTALL_PREFIX
    let dpcpp_root = ($env.DPCPP_ROOT? | default $install_prefix)
    let jobs = ($env.BUILD_JOBS? | default "" | if ($in | is-empty) { (nproc) } else { $in | into int })

    if not ($build_dir | path exists) {
        print $"Error: Build directory not found at ($build_dir)"
        print "Run: pixi run -e onemath build"
        exit 1
    }

    print "="
    print "Installing oneMath"
    print $"  Build dir: ($build_dir)"
    print $"  Install prefix: ($install_prefix)"
    print "="

    # Set up environment for install
    with-env {
        PATH: $"($dpcpp_root)/bin:($env.PATH)"
        LD_LIBRARY_PATH: $"($dpcpp_root)/lib:($env.LD_LIBRARY_PATH? | default '')"
    } {
        cmake --build $build_dir --target install -j $jobs
    }

    # Verify installation
    let onemath_lib = $"($install_prefix)/lib/libonemath.so"
    if ($onemath_lib | path exists) {
        print ""
        print "Installation successful!"
        print $"oneMath installed to: ($install_prefix)"
    } else {
        # Check for onemkl naming (project may still use old name)
        let onemkl_lib = $"($install_prefix)/lib/libonemkl.so"
        if ($onemkl_lib | path exists) {
            print ""
            print "Installation successful!"
            print $"oneMath installed to: ($install_prefix)"
            print "(Note: library is named libonemkl.so for backwards compatibility)"
        } else {
            print "Warning: oneMath library not found in install directory"
            print "Installation may be incomplete"
        }
    }
}

main
