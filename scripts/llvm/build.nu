#!/usr/bin/env nu
# Build Intel LLVM/DPC++ using the configured build directory

def main [] {
    let build_dir = $env.LLVM_BUILD_DIR
    let jobs = ($env.BUILD_JOBS? | default "" | if ($in | is-empty) { (nproc) } else { $in | into int })

    if not ($build_dir | path exists) {
        print $"Error: Build directory not found at ($build_dir)"
        print "Run: pixi run configure"
        exit 1
    }

    if not ($"($build_dir)/build.ninja" | path exists) {
        print $"Error: build.ninja not found in ($build_dir)"
        print "Configuration may have failed. Run: pixi run configure"
        exit 1
    }

    print "="
    print $"Building Intel LLVM/DPC++"
    print $"  Build dir: ($build_dir)"
    print $"  Parallel jobs: ($jobs)"
    print "="

    # Build the main target
    cmake --build $build_dir -j $jobs

    print "Build complete!"
}

main
