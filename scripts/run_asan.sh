#!/usr/bin/env bash
# Builds and runs logforge with AddressSanitizer enabled. Output is saved to
# results/asan.log.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

ensure_build build-asan -DCMAKE_BUILD_TYPE=Debug -DENABLE_ASAN=ON
sample_log="$(ensure_sample_log)"

# LeakSanitizer (detect_leaks) only runs on Linux; macOS's ASan build aborts
# if asked for it. See scripts/run_lsan.sh for the dedicated leak-check run.
if [ "$(uname -s)" = "Linux" ]; then
    export ASAN_OPTIONS="detect_leaks=1${ASAN_OPTIONS:+:$ASAN_OPTIONS}"
fi
run_logged asan "$PROJECT_ROOT/build-asan/logforge" --input "$sample_log" --status-counts
