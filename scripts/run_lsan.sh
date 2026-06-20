#!/usr/bin/env bash
# Builds and runs logforge with leak detection enabled (via the ASan build,
# which bundles LeakSanitizer on Linux). Output is saved to results/lsan.log.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

ensure_build build-lsan -DCMAKE_BUILD_TYPE=Debug -DENABLE_ASAN=ON
sample_log="$(ensure_sample_log)"

# LeakSanitizer (detect_leaks) is Linux-only; on macOS it isn't available even
# via the ASan build, so this script's leak-check coverage only applies there.
if [ "$(uname -s)" != "Linux" ]; then
    echo "LeakSanitizer is Linux-only; run this inside the Docker dev environment (see docs/docker_dev_environment.md)." >&2
    exit 1
fi
export ASAN_OPTIONS="detect_leaks=1${ASAN_OPTIONS:+:$ASAN_OPTIONS}"
run_logged lsan "$PROJECT_ROOT/build-lsan/logforge" --input "$sample_log" --build-index
