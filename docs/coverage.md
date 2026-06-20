# Test Coverage: gcov / lcov

`lcov` (driven by `gcov`, or Apple Clang's LLVM-gcov-compatible emulation on
macOS) turns `--coverage`-instrumented test runs into line/function coverage
reports.

## Run it

```bash
./scripts/run_coverage.sh
```

Builds `build-coverage/` (`-DENABLE_COVERAGE=ON`), runs `ctest`, captures
coverage with `lcov`, strips system/test-file noise, and generates an HTML
report. Output is saved to `results/coverage.log` and
`results/coverage_html/index.html`; the raw `.info` file is
`results/coverage.info`.

## Run it by hand

```bash
cmake -B build-coverage -DCMAKE_BUILD_TYPE=Debug -DENABLE_COVERAGE=ON
cmake --build build-coverage
ctest --test-dir build-coverage
lcov --capture --directory build-coverage --output-file coverage.info
lcov --remove coverage.info '/usr/*' '*/tests/*' --output-file coverage.info
genhtml coverage.info --output-directory coverage_html
```

## Real captured result

Running the four unit test suites (`test_parser`, `test_aggregator`,
`test_query_engine`, `test_thread_pool`) against `src/` and `include/`:

```text
Overall coverage rate:
  source files: 8
  lines.......: 90.0% (199 of 221 lines)
  functions...: 97.7% (43 of 44 functions)

Filename                    |Rate     Num|Rate    Num
=====================================================
include/Aggregator.h        | 100%     13| 100%    11
include/LogRecord.h         | 100%      3| 100%     8
include/ThreadPool.h        | 100%      2|    -     0
src/Aggregator.cpp          |95.7%     47| 100%     6
src/LogIndex.cpp            |85.0%     20|75.0%     4
src/LogParser.cpp           |93.6%     47| 100%     3
src/QueryEngine.cpp         |70.5%     44| 100%     2
src/ThreadPool.cpp          |97.8%     45| 100%    10
```

`src/QueryEngine.cpp` is the weakest spot (70.5%) — `test_query_engine.cpp`
exercises `status=`/`ip=`/`path=` queries with and without an index, but not
every branch in `execute_query`'s `path` field handling. `src/main.cpp` and
`src/ReportWriter.cpp` don't appear at all: there's no test exercising
`main()` or the `write_*` output formatters directly (they're only checked
indirectly via the CLI smoke tests in this conversation, not `ctest`).
Closing that gap would mean adding a `test_report_writer.cpp` and/or a
script-driven CLI test, not just more unit tests.

## Platform note

**On macOS, Apple Clang's LLVM-gcov emulation trips `lcov`'s consistency
checks** over system `<functional>` header internals (lambda destructor line
ranges it can't resolve), failing the whole capture with
`lcov: ERROR: (inconsistent) ... Cannot derive function end line`.
`scripts/run_coverage.sh` works around this with
`--ignore-errors inconsistent,unsupported` on every `lcov` invocation
(capture, remove, list). GCC's `gcov` on Linux doesn't have this problem, so
if you hit different/worse warnings in Docker, the ignore-errors flags are
still harmless there.

## Lessons learned

* `lcov --list` after capture is worth running even when you generate HTML —
  it's the fastest way to see the per-file numbers in a terminal without
  opening `coverage_html/index.html`.
* A coverage gap that lines up with "no test calls this at all" (here,
  `main.cpp`/`ReportWriter.cpp`) is a different finding than "this function
  is tested but one branch isn't" (here, `QueryEngine.cpp`) — the report
  doesn't distinguish them, so check function counts (`hit`/total) alongside
  line percentages before deciding where to add tests.
