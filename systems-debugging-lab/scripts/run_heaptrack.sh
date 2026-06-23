#!/usr/bin/env bash
# Profiles allocation hot spots with heaptrack. The analysis report is saved
# to results/heaptrack.log.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

ensure_build build -DCMAKE_BUILD_TYPE=Release
sample_log="$(ensure_sample_log)"

pushd "$RESULTS_DIR" >/dev/null
rm -f heaptrack.logforge.*.gz
heaptrack "$PROJECT_ROOT/build/logforge" --input "$sample_log" --top-paths 10
run_logged heaptrack heaptrack --analyze heaptrack.logforge.*.gz
popd >/dev/null
