#!/usr/bin/env nu
# Test the AdaptiveCpp toolchain installation

def main [
    --quick (-q)  # Run quick smoke tests only
] {
    let install_prefix = $env.INSTALL_PREFIX
    let build_dir = $env.ADAPTIVECPP_BUILD_DIR
    
    # Verify installation exists
    if not ($install_prefix | path exists) {
        print $"Error: Install prefix not found at ($install_prefix)"
        print "Run: pixi run -e adaptivecpp install"
        exit 1
    }

    let bin_dir = $"($install_prefix)/bin"
    let acpp = $"($bin_dir)/acpp"
    let acpp_info = $"($bin_dir)/acpp-info"

    if not ($acpp | path exists) {
        print $"Error: acpp not found at ($acpp)"
        exit 1
    }

    print "="
    print "Testing AdaptiveCpp Toolchain"
    print $"  Install prefix: ($install_prefix)"
    print "="

    # Set up environment
    let test_env = {
        PATH: $"($bin_dir):($env.PATH)"
        LD_LIBRARY_PATH: $"($install_prefix)/lib:($env.LD_LIBRARY_PATH? | default '')"
    }

    # ========================================================================
    # Basic smoke tests
    # ========================================================================
    print "\n[1/4] Checking compiler version..."
    with-env $test_env {
        run-external $acpp "--version"
    }

    print "\n[2/4] Checking SYCL support..."
    if ($acpp_info | path exists) {
        with-env $test_env {
            run-external $acpp_info
        }
    } else {
        print "Warning: acpp-info not found"
    }

    # ========================================================================
    # Compile test: simple SYCL program
    # ========================================================================
    print "\n[3/4] Compiling SYCL test program..."
    
    let test_dir = $"($env.PIXI_PROJECT_ROOT)/build/test"
    mkdir $test_dir
    
    let test_source = $"($test_dir)/acpp_test.cpp"
    let test_binary = $"($test_dir)/acpp_test"
    
    # Write test program using heredoc-style
    let test_code = '#include <sycl/sycl.hpp>
#include <iostream>
#include <vector>

int main() {
    std::cout << "SYCL Devices:\n";
    for (auto& platform : sycl::platform::get_platforms()) {
        std::cout << "  Platform: " << platform.get_info<sycl::info::platform::name>() << "\n";
        for (auto& device : platform.get_devices()) {
            std::cout << "    Device: " << device.get_info<sycl::info::device::name>() << "\n";
        }
    }

    constexpr size_t N = 1024;
    std::vector<float> a(N, 1.0f);
    std::vector<float> b(N, 2.0f);
    std::vector<float> c(N, 0.0f);

    {
        sycl::queue q;
        std::cout << "\nUsing device: " << q.get_device().get_info<sycl::info::device::name>() << "\n";
        
        sycl::buffer<float> buf_a(a.data(), sycl::range<1>(N));
        sycl::buffer<float> buf_b(b.data(), sycl::range<1>(N));
        sycl::buffer<float> buf_c(c.data(), sycl::range<1>(N));
        
        q.submit([&](sycl::handler& h) {
            auto acc_a = buf_a.get_access<sycl::access::mode::read>(h);
            auto acc_b = buf_b.get_access<sycl::access::mode::read>(h);
            auto acc_c = buf_c.get_access<sycl::access::mode::write>(h);
            
            h.parallel_for<class vector_add>(sycl::range<1>(N), [=](sycl::id<1> i) {
                acc_c[i] = acc_a[i] + acc_b[i];
            });
        });
    }

    bool passed = true;
    for (size_t i = 0; i < N; ++i) {
        if (c[i] != 3.0f) {
            std::cerr << "Mismatch at index " << i << ": " << c[i] << " != 3.0\n";
            passed = false;
            break;
        }
    }

    if (passed) {
        std::cout << "Vector addition test PASSED!\n";
        return 0;
    } else {
        std::cerr << "Vector addition test FAILED!\n";
        return 1;
    }
}
'

    $test_code | save -f $test_source

    # Compile the test
    with-env $test_env {
        run-external $acpp "-o" $test_binary $test_source
    }

    if not ($test_binary | path exists) {
        print "Error: Failed to compile SYCL test program"
        exit 1
    }
    print "Compilation successful!"

    # ========================================================================
    # Run test program
    # ========================================================================
    print "\n[4/4] Running SYCL test program..."
    
    with-env $test_env {
        run-external $test_binary
    }

    print "\n=========================================="
    print "All tests completed!"
    print "=========================================="
}

main
