#!/usr/bin/env bash
# Shared helpers for scripts/run_*.sh. Source this file; do not execute it
# directly.

set -euo pipefail

SCRIPT_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_LIB_DIR/.." && pwd)"
RESULTS_DIR="$PROJECT_ROOT/results"
LOGS_DIR="$PROJECT_ROOT/logs"

mkdir -p "$RESULTS_DIR" "$LOGS_DIR"

# run_logged <tool-name> <command...>
#
# Runs the command, streaming combined stdout+stderr to the terminal while
# also saving it to results/<tool-name>.log (overwritten on every run).
# Returns the command's own exit status, but only after the log has been
# fully written, so a tool that "fails" by design (e.g. ASan aborting on a
# detected bug) still leaves behind a complete log.
run_logged() {
    local tool_name="$1"
    shift
    local log_file="$RESULTS_DIR/${tool_name}.log"
    echo "==> Logging ${tool_name} output to ${log_file}"

    set +e
    {
        echo "# ${tool_name} run at $(date -u +%Y-%m-%dT%H:%M:%SZ)"
        echo "# command: $*"
        echo
        "$@"
    } 2>&1 | tee "$log_file"
    local status="${PIPESTATUS[0]}"
    set -e

    if [ "$status" -ne 0 ]; then
        echo "==> ${tool_name} exited with status ${status} (see ${log_file})"
    fi
    return "$status"
}

# ensure_build <build-dir> <cmake-args...>
#
# Configures and builds <build-dir> if needed. Idempotent: cmake/ninja-style
# incremental builds make repeated calls cheap.
ensure_build() {
    local build_dir="$1"
    shift
    cmake -S "$PROJECT_ROOT" -B "$PROJECT_ROOT/$build_dir" "$@" >/dev/null
    cmake --build "$PROJECT_ROOT/$build_dir" -j >/dev/null
}

# ensure_sample_log
#
# Generates logs/10k.log via bench/generate_logs.py if it doesn't already
# exist, and prints its path (so callers can do: log="$(ensure_sample_log)").
ensure_sample_log() {
    local log_file="$LOGS_DIR/10k.log"
    if [ ! -f "$log_file" ]; then
        python3 "$PROJECT_ROOT/bench/generate_logs.py" --records 10000 --output "$log_file" >&2
    fi
    echo "$log_file"
}
