#!/usr/bin/env bash
# Collects a gprofng experiment and saves the function profile and call tree
# to results/gprofng.log.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

ensure_build build -DCMAKE_BUILD_TYPE=Release
sample_log="$(ensure_sample_log)"

experiment_dir="$RESULTS_DIR/gprofng.er"
rm -rf "$experiment_dir"
gprofng collect app -o "$experiment_dir" \
    "$PROJECT_ROOT/build/logforge" --input "$sample_log" --threads 8 --top-paths 10

log_file="$RESULTS_DIR/gprofng.log"
{
    echo "# gprofng run at $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo
    echo "## Function profile"
    gprofng display text -functions "$experiment_dir"
    echo
    echo "## Call tree"
    gprofng display text -calltree "$experiment_dir"
} 2>&1 | tee "$log_file"
echo "==> Logging gprofng output to ${log_file}"
