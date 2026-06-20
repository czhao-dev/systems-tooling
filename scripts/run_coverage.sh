#!/usr/bin/env bash
# Builds with coverage instrumentation, runs the test suite, and generates an
# lcov report. Output is saved to results/coverage.log.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

ensure_build build-coverage -DCMAKE_BUILD_TYPE=Debug -DENABLE_COVERAGE=ON

log_file="$RESULTS_DIR/coverage.log"
set +e
{
    echo "# coverage run at $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo
    ctest --test-dir "$PROJECT_ROOT/build-coverage" --output-on-failure
    # --ignore-errors works around LLVM gcov (used by Apple Clang on macOS)
    # reporting function end-lines that confuse lcov's consistency checks;
    # GCC's gcov on Linux doesn't need this.
    lcov --capture --directory "$PROJECT_ROOT/build-coverage" \
        --ignore-errors inconsistent,unsupported --output-file "$RESULTS_DIR/coverage.info"
    lcov --remove "$RESULTS_DIR/coverage.info" '/usr/*' '*/tests/*' '/Library/*' \
        --ignore-errors inconsistent,unsupported --output-file "$RESULTS_DIR/coverage.info"
    genhtml "$RESULTS_DIR/coverage.info" --ignore-errors inconsistent,unsupported \
        --output-directory "$RESULTS_DIR/coverage_html"
    lcov --list "$RESULTS_DIR/coverage.info" --ignore-errors inconsistent,unsupported
} 2>&1 | tee "$log_file"
status="${PIPESTATUS[0]}"
set -e

echo "==> Logging coverage output to ${log_file}"
exit "$status"
