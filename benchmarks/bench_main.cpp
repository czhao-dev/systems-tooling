#include "buildlab/core.h"
#include "buildlab/net.hpp"

#include <chrono>
#include <cstring>
#include <iostream>
#include <string>
#include <vector>

namespace {

// Tiny manual benchmark harness: runs `fn` `iterations` times and reports
// total and per-iteration wall time. No external dependency (Google
// Benchmark is deliberately not used here -- this project's benchmarks are
// illustrative, not rigorous microbenchmarking).
template <typename Fn> void run_benchmark(const std::string &name, int iterations, Fn fn) {
    const auto start = std::chrono::steady_clock::now();
    for (int i = 0; i < iterations; ++i) {
        fn();
    }
    const auto end = std::chrono::steady_clock::now();
    const auto total_ns = std::chrono::duration_cast<std::chrono::nanoseconds>(end - start).count();
    std::cout << name << ": " << iterations << " iterations, " << total_ns << " ns total, "
              << (total_ns / iterations) << " ns/iter\n";
}

} // namespace

int main() {
    constexpr int kIterations = 100000;

    // Parsing helper.
    run_benchmark("buildlab_trim", kIterations, [] {
        char buffer[] = "    the quick brown fox jumps over the lazy dog    ";
        buildlab_trim(buffer);
    });

    // String processing helper.
    run_benchmark("buildlab_count_occurrences", kIterations, [] {
        static const char haystack[] =
            "the quick brown fox jumps over the lazy dog the quick brown fox";
        (void)buildlab_count_occurrences(haystack, "fox");
    });

    // Lightweight networking helper (encode + decode round trip).
    run_benchmark("net::frame_message + try_decode_frame", kIterations, [] {
        auto buffer = buildlab::net::frame_message("hello buildlab");
        (void)buildlab::net::try_decode_frame(buffer);
    });

    // CLI startup overhead proxy: spawning the real buildlab-cli binary
    // per-iteration would be platform-specific process-spawn code, so this
    // approximates the cost of the version path it exercises instead.
    run_benchmark("cli startup overhead (proxy)", kIterations, [] {
        (void)buildlab_core_version();
        (void)buildlab::net::net_version();
    });

    return 0;
}
