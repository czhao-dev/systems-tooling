#!/usr/bin/env bash
# Runs GDB in batch mode against a debug build, breaking in the parser and
# printing a backtrace. Output is saved to results/gdb.log.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

ensure_build build-debug -DCMAKE_BUILD_TYPE=Debug
sample_log="$(ensure_sample_log)"

run_logged gdb gdb --batch \
    -ex "break logforge::parse_line" \
    -ex "run" \
    -ex "backtrace" \
    -ex "continue" \
    --args "$PROJECT_ROOT/build-debug/logforge" --input "$sample_log" --status-counts
