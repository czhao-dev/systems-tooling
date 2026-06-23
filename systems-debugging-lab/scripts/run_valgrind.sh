#!/usr/bin/env bash
# Runs Valgrind Memcheck against a debug build. Linux-only (use the Docker
# dev environment on macOS). Output is saved to results/valgrind.log.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

ensure_build build-debug -DCMAKE_BUILD_TYPE=Debug
sample_log="$(ensure_sample_log)"

run_logged valgrind valgrind --leak-check=full --track-origins=yes \
    "$PROJECT_ROOT/build-debug/logforge" --input "$sample_log" --status-counts
