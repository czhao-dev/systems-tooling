#!/usr/bin/env bash
# Traces syscalls with strace (Linux) or falls back to dtruss (macOS,
# requires sudo). Output is saved to results/strace.log.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

ensure_build build -DCMAKE_BUILD_TYPE=Release
sample_log="$(ensure_sample_log)"

if command -v strace >/dev/null 2>&1; then
    run_logged strace strace -f -c "$PROJECT_ROOT/build/logforge" --input "$sample_log" --status-counts
elif command -v dtruss >/dev/null 2>&1; then
    echo "strace not found; falling back to dtruss (requires sudo)" >&2
    run_logged strace sudo dtruss -c "$PROJECT_ROOT/build/logforge" --input "$sample_log" --status-counts
else
    echo "Neither strace nor dtruss is available on this system." >&2
    exit 1
fi
