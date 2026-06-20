#!/usr/bin/env bash
# Runs cppcheck as an additional static-analysis pass. Output is saved to
# results/cppcheck.log.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

run_logged cppcheck cppcheck --enable=all --inconclusive --std=c++17 \
    -I"$PROJECT_ROOT/include" "$PROJECT_ROOT/src"
