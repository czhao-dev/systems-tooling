#!/usr/bin/env bash
# Profiles cache behavior with Valgrind Cachegrind (Linux-only). The
# cg_annotate report is saved to results/cachegrind.log.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

ensure_build build -DCMAKE_BUILD_TYPE=Release
sample_log="$(ensure_sample_log)"

pushd "$RESULTS_DIR" >/dev/null
rm -f cachegrind.out.*
valgrind --tool=cachegrind "$PROJECT_ROOT/build/logforge" --input "$sample_log" --status-counts
run_logged cachegrind cg_annotate cachegrind.out.*
popd >/dev/null
