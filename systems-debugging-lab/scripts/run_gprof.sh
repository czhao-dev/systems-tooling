#!/usr/bin/env bash
# Builds with gprof instrumentation, runs logforge to produce gmon.out, and
# saves the flat profile/call graph to results/gprof.log.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

ensure_build build-gprof -DCMAKE_BUILD_TYPE=Release -DENABLE_GPROF=ON
sample_log="$(ensure_sample_log)"

pushd "$PROJECT_ROOT" >/dev/null
./build-gprof/logforge --input "$sample_log" --top-paths 10
run_logged gprof gprof ./build-gprof/logforge gmon.out
popd >/dev/null
