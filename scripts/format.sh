#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

CLANG_FORMAT="${CLANG_FORMAT:-clang-format}"

if ! command -v "$CLANG_FORMAT" >/dev/null 2>&1; then
    echo "error: $CLANG_FORMAT not found (set CLANG_FORMAT=/path/to/clang-format)" >&2
    exit 1
fi

mapfile -t FILES < <(find src include tests benchmarks examples -type f \
    \( -name '*.c' -o -name '*.h' -o -name '*.hpp' -o -name '*.cpp' \))

echo "Formatting ${#FILES[@]} files with $CLANG_FORMAT..."
"$CLANG_FORMAT" -i "${FILES[@]}"
