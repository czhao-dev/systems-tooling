#!/usr/bin/env bash
# Profiles CPU time with perf stat (Linux-only). Output is saved to
# results/perf.log.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

ensure_build build -DCMAKE_BUILD_TYPE=Release
sample_log="$(ensure_sample_log)"

run_logged perf perf stat "$PROJECT_ROOT/build/logforge" --input "$sample_log" --threads 8 --status-counts
