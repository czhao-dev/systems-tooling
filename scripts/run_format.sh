#!/usr/bin/env bash
# Checks formatting with --dry-run first (saved to results/format.log), then
# applies clang-format in place.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

files=("$PROJECT_ROOT"/include/*.h "$PROJECT_ROOT"/src/*.cpp "$PROJECT_ROOT"/tests/*.cpp)

run_logged format clang-format --dry-run --Werror "${files[@]}" || true
clang-format -i "${files[@]}"
echo "Formatted ${#files[@]} file(s); dry-run diff saved to $RESULTS_DIR/format.log"
