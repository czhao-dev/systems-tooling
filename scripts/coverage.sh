#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

BUILD_DIR="${1:-build/coverage}"

if [ ! -d "$BUILD_DIR" ]; then
    echo "error: $BUILD_DIR not configured. Run:" >&2
    echo "  cmake --preset coverage && cmake --build --preset coverage" >&2
    exit 1
fi

COMPILER_FILE=$(find "$BUILD_DIR/CMakeFiles" -maxdepth 2 -name 'CMakeCXXCompiler.cmake' | head -1)

if grep -qi "Clang" "$COMPILER_FILE"; then
    echo "Detected Clang -- using source-based coverage (llvm-profdata/llvm-cov)."

    LLVM_PROFDATA="${LLVM_PROFDATA:-xcrun llvm-profdata}"
    LLVM_COV="${LLVM_COV:-xcrun llvm-cov}"

    PROFRAW_DIR="$(cd "$BUILD_DIR" && pwd)/profraw"
    mkdir -p "$PROFRAW_DIR"
    rm -f "$PROFRAW_DIR"/*.profraw

    # Re-run tests with a per-process profile path so parallel test binaries
    # don't clobber each other's profraw output. Uses an absolute path
    # because CTest runs each test with its own executable's directory as
    # the working directory, not $BUILD_DIR itself.
    ( cd "$BUILD_DIR" && LLVM_PROFILE_FILE="$PROFRAW_DIR/%p-%m.profraw" ctest --output-on-failure )

    PROFRAW_FILES=("$PROFRAW_DIR"/*.profraw)
    if [ ! -e "${PROFRAW_FILES[0]}" ]; then
        echo "error: no .profraw files were produced; did the coverage preset build run?" >&2
        exit 1
    fi

    $LLVM_PROFDATA merge -sparse "${PROFRAW_FILES[@]}" -o "$BUILD_DIR/coverage.profdata"

    OBJECT_ARGS=()
    for binary in "$BUILD_DIR/tests/buildlab_tests" "$BUILD_DIR/src/cli/buildlab-cli"; do
        if [ -x "$binary" ]; then
            OBJECT_ARGS+=("-object=$binary")
        fi
    done

    $LLVM_COV report "${OBJECT_ARGS[@]}" \
        -instr-profile="$BUILD_DIR/coverage.profdata" \
        --ignore-filename-regex='(_deps|tests)/'

    $LLVM_COV show "${OBJECT_ARGS[@]}" \
        -instr-profile="$BUILD_DIR/coverage.profdata" \
        --ignore-filename-regex='(_deps|tests)/' \
        --format=html --output-dir="$BUILD_DIR/coverage-html"

    echo "HTML report: $BUILD_DIR/coverage-html/index.html"

elif grep -qi "GNU" "$COMPILER_FILE"; then
    echo "Detected GCC -- using lcov/gcov."

    lcov --directory "$BUILD_DIR" --capture --output-file "$BUILD_DIR/coverage.info" \
        --rc lcov_branch_coverage=1
    lcov --remove "$BUILD_DIR/coverage.info" '*/_deps/*' '*/tests/*' '/usr/*' \
        --output-file "$BUILD_DIR/coverage.filtered.info"
    genhtml "$BUILD_DIR/coverage.filtered.info" --output-directory "$BUILD_DIR/coverage-html"

    echo "HTML report: $BUILD_DIR/coverage-html/index.html"
else
    echo "error: could not determine compiler from $COMPILER_FILE" >&2
    exit 1
fi
