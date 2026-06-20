#!/usr/bin/env bash
# Runs LLDB in batch mode against a debug build, breaking in the parser and
# printing a backtrace. Output is saved to results/lldb.log.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

ensure_build build-debug -DCMAKE_BUILD_TYPE=Debug
sample_log="$(ensure_sample_log)"

run_logged lldb lldb --batch \
    -o "breakpoint set --name logforge::parse_line" \
    -o "run" \
    -o "thread backtrace" \
    -o "continue" \
    -- "$PROJECT_ROOT/build-debug/logforge" --input "$sample_log" --status-counts
