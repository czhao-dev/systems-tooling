#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

BUILD_DIR="${1:-build/debug}"
CLANG_TIDY="${CLANG_TIDY:-clang-tidy}"

if [ ! -f "$BUILD_DIR/compile_commands.json" ]; then
    echo "error: $BUILD_DIR/compile_commands.json not found. Configure that preset first, e.g.:" >&2
    echo "  cmake --preset debug" >&2
    exit 1
fi

if ! command -v "$CLANG_TIDY" >/dev/null 2>&1; then
    echo "error: $CLANG_TIDY not found." >&2
    echo "Apple Clang does not ship clang-tidy. On macOS with Homebrew LLVM installed, run:" >&2
    echo "  CLANG_TIDY=/opt/homebrew/opt/llvm/bin/clang-tidy $0 $BUILD_DIR" >&2
    exit 1
fi

mapfile -t FILES < <(find src include -type f \( -name '*.c' -o -name '*.cpp' \))

EXTRA_ARGS=()
if [ "$(uname)" = "Darwin" ]; then
    # A clang-tidy built by a different vendor than the one that produced
    # compile_commands.json (e.g. Homebrew LLVM vs. Apple Clang) won't find
    # the Xcode SDK headers unless told where to look.
    EXTRA_ARGS+=("--extra-arg=--sysroot=$(xcrun --show-sdk-path)")
fi

echo "Running $CLANG_TIDY on ${#FILES[@]} files using $BUILD_DIR/compile_commands.json..."
"$CLANG_TIDY" -p "$BUILD_DIR" "${EXTRA_ARGS[@]}" "${FILES[@]}"
