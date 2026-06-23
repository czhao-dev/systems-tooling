#!/usr/bin/env bash
# Builds and runs logforge with UndefinedBehaviorSanitizer enabled. Output is
# saved to results/ubsan.log.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

ensure_build build-ubsan -DCMAKE_BUILD_TYPE=Debug -DENABLE_UBSAN=ON
sample_log="$(ensure_sample_log)"

run_logged ubsan "$PROJECT_ROOT/build-ubsan/logforge" --input "$sample_log" --latency-stats
