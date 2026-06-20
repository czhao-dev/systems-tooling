# UndefinedBehaviorSanitizer

UndefinedBehaviorSanitizer (UBSan) instruments operations whose behavior the
C++ standard leaves undefined — signed integer overflow, invalid shifts,
invalid enum values, misaligned/null pointer use — and reports them at
runtime instead of letting them silently corrupt results. Works on both
macOS and Linux.

## Run it

```bash
./scripts/run_ubsan.sh
```

Builds `build-ubsan/` (`-DENABLE_UBSAN=ON`) and runs
`logforge --input logs/10k.log --latency-stats`. Output is saved to
`results/ubsan.log`. The main binary is clean here too — `Aggregator`'s
latency values are plain `int` (matching the `latency_ms` field), and nothing
in the percentile computation overflows for realistic inputs.

## Run it by hand

```bash
cmake -B build-ubsan -DCMAKE_BUILD_TYPE=Debug -DENABLE_UBSAN=ON
cmake --build build-ubsan
./build-ubsan/bugs/bug_undefined_behavior
```

## Worked example: `bugs/undefined_behavior.cpp`

```cpp
int sum_latencies(int count) {
    int total = 0;  // Should be int64_t to hold sums over large inputs.
    for (int i = 0; i < count; ++i) {
        total += std::numeric_limits<int>::max() / 2;
    }
    return total;
}
```

Real captured output:

```text
bugs/undefined_behavior.cpp:8:15: runtime error: signed integer overflow:
2147483646 + 1073741823 cannot be represented in type 'int'
SUMMARY: UndefinedBehaviorSanitizer: undefined-behavior
bugs/undefined_behavior.cpp:8:15
total: 2147483638
```

Note the program *kept running and printed a wrong answer* (`2147483638`,
which is itself a UB-dependent wraparound value — a different compiler could
legally produce a different number, or miscompile the loop entirely) — UBSan
reports the violation but, unlike ASan on a memory error, doesn't abort by
default. This is exactly the class of bug that's easy to ship unnoticed: the
program "works," it just sometimes computes nonsense.

Fix: accumulate in `int64_t` (or `long long`) when the value being summed can
plausibly exceed `INT_MAX` over many iterations.

## Lessons learned

* UBSan failing to abort by default is a trap: wire `-fno-sanitize-recover`
  (or check exit codes against UBSan's halt-on-error options) into CI if you
  want a UB report to actually fail a build, rather than scrolling by in a
  log.
* This is the sanitizer most likely to catch bugs that *don't* crash —
  pair it with property-based or large-input tests (e.g. running against
  `logs/10m.log`) where overflow is more likely to be reachable than in small
  unit tests.
