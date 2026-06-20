#!/usr/bin/env bash
# Runs clang-tidy using the project's compile_commands.json. Output is saved
# to results/clang_tidy.log.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

ensure_build build -DCMAKE_BUILD_TYPE=Debug

run_logged clang_tidy clang-tidy "$PROJECT_ROOT"/src/*.cpp -p "$PROJECT_ROOT/build"
