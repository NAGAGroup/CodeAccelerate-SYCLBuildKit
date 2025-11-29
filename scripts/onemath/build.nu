#!/usr/bin/env nu
# Build oneMath

def main [] {
    let build_dir = $env.ONEMATH_BUILD_DIR
    let dpcpp_root = ($env.DPCPP_ROOT? | default $env.INSTALL_PREFIX)
    let jobs = ($env.BUILD_JOBS? | default "" | if ($in | is-empty) { (nproc) } else { $in | into int })

    if not ($build_dir | path exists) {
        print $"Error: Build directory not found at ($build_dir)"
        print "Run: pixi run -e onemath configure"
        exit 1
    }

    if not ($"($build_dir)/build.ninja" | path exists) {
        print $"Error: build.ninja not found in ($build_dir)"
        print "Configuration may have failed. Run: pixi run -e onemath configure"
        exit 1
    }

    print "="
    print "Building oneMath"
    print $"  Build dir: ($build_dir)"
    print $"  Parallel jobs: ($jobs)"
    print "="

    # Set up environment for build
    with-env {
        PATH: $"($dpcpp_root)/bin:($env.PATH)"
        LD_LIBRARY_PATH: $"($dpcpp_root)/lib:($env.LD_LIBRARY_PATH? | default '')"
    } {
        cmake --build $build_dir -j $jobs
    }

    print "Build complete!"
}

main
