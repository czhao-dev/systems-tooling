#!/usr/bin/env bash
# Profiles heap usage over time with Valgrind Massif (Linux-only). The
# ms_print report is saved to results/massif.log.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

ensure_build build -DCMAKE_BUILD_TYPE=Release
sample_log="$(ensure_sample_log)"

pushd "$RESULTS_DIR" >/dev/null
rm -f massif.out.*
valgrind --tool=massif "$PROJECT_ROOT/build/logforge" --input "$sample_log" --build-index
run_logged massif ms_print massif.out.*
popd >/dev/null
