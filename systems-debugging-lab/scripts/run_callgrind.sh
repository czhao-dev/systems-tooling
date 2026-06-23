#!/usr/bin/env bash
# Profiles call paths with Valgrind Callgrind (Linux-only). The
# callgrind_annotate report is saved to results/callgrind.log.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

ensure_build build -DCMAKE_BUILD_TYPE=Release
sample_log="$(ensure_sample_log)"

pushd "$RESULTS_DIR" >/dev/null
rm -f callgrind.out.*
valgrind --tool=callgrind "$PROJECT_ROOT/build/logforge" --input "$sample_log" --top-paths 10
run_logged callgrind callgrind_annotate callgrind.out.*
popd >/dev/null
