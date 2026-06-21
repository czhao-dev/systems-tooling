#!/usr/bin/env bash
# Runs ShellCheck over the project's shell scripts.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! command -v shellcheck >/dev/null 2>&1; then
    echo "shellcheck is not installed. See https://github.com/koalaman/shellcheck#installing" >&2
    exit 1
fi

cd "$ROOT_DIR"
echo "Running ShellCheck on sysdoctor.sh and lib/*.sh ..."
shellcheck -x sysdoctor.sh lib/*.sh
echo "ShellCheck passed."
