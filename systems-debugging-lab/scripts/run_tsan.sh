#!/usr/bin/env bash
# Builds and runs logforge with ThreadSanitizer enabled across multiple
# worker threads. Output is saved to results/tsan.log.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

ensure_build build-tsan -DCMAKE_BUILD_TYPE=Debug -DENABLE_TSAN=ON
sample_log="$(ensure_sample_log)"

run_logged tsan "$PROJECT_ROOT/build-tsan/logforge" --input "$sample_log" --threads 8 --status-counts
