# CMake Systems Build Lab

[![CMake](https://img.shields.io/badge/build-CMake%20%2B%20Ninja-064F8C?logo=cmake&logoColor=white)](CMakePresets.json)
[![C](https://img.shields.io/badge/C-11-555555?logo=c)](https://en.wikipedia.org/wiki/C11_(C_standard_revision))
[![C++](https://img.shields.io/badge/C%2B%2B-17-00599C?logo=cplusplus&logoColor=white)](https://en.cppreference.com/w/cpp/17)
[![CI](https://github.com/czhao-dev/cmake-systems-build-lab/actions/workflows/ci.yml/badge.svg)](https://github.com/czhao-dev/cmake-systems-build-lab/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

A modern CMake build engineering lab for C/C++ systems projects.

This project demonstrates production-style build infrastructure using CMake presets, target-based CMake, compiler warnings, sanitizers, coverage, CTest, dependency management, packaging, install/export targets, toolchain files, and CI.

The goal is not to build a large application. The goal is to show how a clean, scalable C/C++ build system can be structured for real-world systems software development.

## Overview

`cmake-systems-build-lab` is a small multi-component C/C++ project designed around a professional build system.

It includes:

* modern target-based CMake
* `CMakePresets.json`
* debug and release build presets
* AddressSanitizer, UndefinedBehaviorSanitizer, and ThreadSanitizer presets
* code coverage support
* CTest-based test integration
* optional benchmark target
* compiler warning profiles
* static analysis hooks
* install rules
* exported CMake package targets
* CPack packaging support
* GitHub Actions CI matrix
* optional GNU Make wrapper for common commands

This repository is intended to demonstrate build-system knowledge useful for systems engineering, backend infrastructure, compiler/tooling development, and large C/C++ codebases.

## Motivation

Large systems projects depend heavily on reliable build infrastructure. A good build system should make it easy to:

* build debug and release binaries
* run tests consistently
* enable sanitizers
* collect coverage
* switch compilers
* support static and shared libraries
* install and package artifacts
* integrate with CI
* expose reusable library targets to downstream projects

This project collects those ideas into one compact, easy-to-study repository.

## Features

### Modern CMake

* [x] Target-based CMake
* [x] Per-target include directories
* [x] Per-target compile features
* [x] Per-target compile options
* [x] Static and shared library options
* [x] Clean project options module
* [x] Custom CMake helper modules

### Build Presets

* [x] Debug preset
* [x] Release preset
* [x] RelWithDebInfo preset
* [x] ASan preset
* [x] UBSan preset
* [x] TSan preset
* [x] Coverage preset
* [x] Benchmark preset

### Testing and Quality

* [x] CTest integration
* [x] Unit test target
* [x] Integration test target
* [x] Compiler warning profiles
* [x] Optional `clang-tidy`
* [x] Optional `cppcheck`
* [x] Sanitizer builds
* [x] Coverage builds

### Packaging and Installation

* [x] Install rules
* [x] Exported CMake targets
* [x] Package config generation
* [x] CPack package support
* [x] Downstream usage example

### CI

* [x] GitHub Actions workflow
* [x] GCC build
* [x] Clang build
* [x] Debug build
* [x] Release build
* [x] Sanitizer build
* [x] Test execution
* [x] Optional coverage upload

## Demo Project Structure

The demo code is intentionally small. The build system is the main focus.

Example components:

```text
core        C library with small utility functions
net         C++ library with simple networking-style helpers
cli         command-line executable using core and net
tests       unit and integration tests
benchmarks  simple benchmark target
examples    downstream package usage examples
```

## Repository Layout

```text
cmake-systems-build-lab/
├── README.md
├── LICENSE
├── CMakeLists.txt
├── CMakePresets.json
├── Makefile
├── cmake/
│   ├── CompilerWarnings.cmake
│   ├── ProjectOptions.cmake
│   ├── Sanitizers.cmake
│   ├── Coverage.cmake
│   ├── StaticAnalysis.cmake
│   ├── PackageConfig.cmake.in
│   └── toolchains/
│       ├── linux-gcc.cmake
│       ├── linux-clang.cmake
│       └── macos-clang.cmake
├── include/
│   └── buildlab/
│       ├── core.h
│       └── net.hpp
├── src/
│   ├── core/
│   │   ├── CMakeLists.txt
│   │   └── core.c
│   ├── net/
│   │   ├── CMakeLists.txt
│   │   └── net.cpp
│   └── cli/
│       ├── CMakeLists.txt
│       └── main.cpp
├── tests/
│   ├── CMakeLists.txt
│   ├── test_core.cpp
│   └── test_net.cpp
├── benchmarks/
│   ├── CMakeLists.txt
│   └── bench_main.cpp
├── examples/
│   └── downstream-project/
│       ├── CMakeLists.txt
│       └── main.cpp
├── packaging/
│   └── README.md
├── scripts/
│   ├── format.sh
│   ├── run-clang-tidy.sh
│   └── coverage.sh
└── .github/
    └── workflows/
        └── ci.yml
```

## Quick Start

Clone the repository:

```bash
git clone https://github.com/czhao-dev/cmake-systems-build-lab.git
cd cmake-systems-build-lab
```

Configure a debug build:

```bash
cmake --preset debug
```

Build:

```bash
cmake --build --preset debug
```

Run tests:

```bash
ctest --preset debug
```

Run the CLI executable:

```bash
./build/debug/src/cli/buildlab-cli
```

## Build Presets

This project uses `CMakePresets.json` to provide reproducible build configurations.

### Debug

```bash
cmake --preset debug
cmake --build --preset debug
ctest --preset debug
```

### Release

```bash
cmake --preset release
cmake --build --preset release
ctest --preset release
```

### RelWithDebInfo

```bash
cmake --preset relwithdebinfo
cmake --build --preset relwithdebinfo
ctest --preset relwithdebinfo
```

### AddressSanitizer

```bash
cmake --preset asan
cmake --build --preset asan
ctest --preset asan
```

### UndefinedBehaviorSanitizer

```bash
cmake --preset ubsan
cmake --build --preset ubsan
ctest --preset ubsan
```

### ThreadSanitizer

```bash
cmake --preset tsan
cmake --build --preset tsan
ctest --preset tsan
```

### Coverage

```bash
cmake --preset coverage
cmake --build --preset coverage
ctest --preset coverage
./scripts/coverage.sh
```

## Optional Makefile Wrapper

A small `Makefile` is included as a convenience wrapper around common CMake commands.

```bash
make configure-debug
make build-debug
make test-debug

make configure-release
make build-release
make test-release

make asan
make ubsan
make tsan
make coverage
make clean
```

The Makefile is intentionally thin. CMake remains the source of truth for the build.

## CMake Design

This project follows modern CMake practices:

* use targets instead of global variables
* prefer `target_include_directories`
* prefer `target_compile_features`
* prefer `target_compile_options`
* keep compiler warnings target-scoped
* avoid global include paths
* avoid global compiler flags when possible
* separate project options into reusable modules
* keep install and export rules explicit

Example target:

```cmake
add_library(buildlab_core src/core/core.c)

target_include_directories(buildlab_core
    PUBLIC
        $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/include>
        $<INSTALL_INTERFACE:include>
)

target_compile_features(buildlab_core
    PUBLIC
        c_std_11
)

target_link_libraries(buildlab_core
    PRIVATE
        buildlab_project_options
        buildlab_project_warnings
)
```

## Architecture

A few design decisions recur throughout this codebase. They're called out
here once instead of being re-explained at each call site.

**Why six separate `cmake/` modules instead of one large `CMakeLists.txt`.**
Options, warnings, sanitizers, coverage, static analysis, and package
export are independent concerns: each is toggled by its own cache
variables, each can be reasoned about (and tested) in isolation, and each
is small enough to be copied into another project wholesale. A single
monolithic file would still work, but every concern would be entangled
with every other one.

**Why flags are attached to `INTERFACE` targets instead of set globally.**
`buildlab_project_options` and `buildlab_project_warnings` are empty
`INTERFACE` libraries that carry compiler/linker flags; every first-party
target links them `PRIVATE`. This is deliberately *not* `add_compile_options()`
at the top of the tree. Because GoogleTest is fetched via `FetchContent` and
built as part of this project's CMake tree, a global flag would also apply
to GoogleTest's own sources -- enabling sanitizers or `-Werror` globally
would then fail on warnings this project doesn't own. Scoping flags to two
named targets keeps the blast radius limited to `buildlab_core`,
`buildlab_net`, and `buildlab_cli`.

**Why `buildlab::core` / `buildlab::net` exist as `ALIAS` targets even
before installation.** In-tree consumers (`tests/`, `benchmarks/`,
`src/cli/`) link against the exact same `buildlab::` spelling that a
downstream project uses after `find_package(buildlab)`. There's one
mental model for "how do I depend on this library" regardless of whether
you're inside this repository or consuming an installed copy of it. The
`EXPORT_NAME` target property (see `src/core/CMakeLists.txt`) is what
makes the *installed* import target land on `buildlab::core` rather than
the raw `buildlab::buildlab_core`.

**Why presets instead of remembered `-D` flags.** Every sanitizer/coverage
combination this project supports is a fixed set of cache variables (see
`CMakePresets.json`). Presets make those combinations reproducible across
contributors and CI without anyone needing to memorize flag combinations,
and `CMakePresets.json` is itself a CMake-native file -- it reinforces
that CMake, not a wrapper script, drives the build.

## CMake Modules

### `ProjectOptions.cmake`

Defines project-wide options:

```cmake
option(BUILDLAB_BUILD_TESTS "Build tests" ON)
option(BUILDLAB_BUILD_BENCHMARKS "Build benchmarks" OFF)
option(BUILDLAB_ENABLE_WARNINGS "Enable compiler warnings" ON)
option(BUILDLAB_ENABLE_SANITIZERS "Enable sanitizers" OFF)
option(BUILDLAB_ENABLE_COVERAGE "Enable coverage" OFF)
option(BUILDLAB_BUILD_SHARED_LIBS "Build shared libraries" OFF)
```

### `CompilerWarnings.cmake`

Defines warning flags for supported compilers:

```text
GCC
Clang
AppleClang
MSVC, optional
```

Example warning policy:

```text
-Wall
-Wextra
-Wpedantic
-Wconversion
-Wshadow
-Werror, optional
```

### `Sanitizers.cmake`

Adds sanitizer support:

```text
AddressSanitizer
UndefinedBehaviorSanitizer
ThreadSanitizer
LeakSanitizer, optional
```

### `Coverage.cmake`

Adds coverage flags for supported compilers and generates coverage reports.

### `StaticAnalysis.cmake`

Adds optional hooks for:

```text
clang-tidy
cppcheck
include-what-you-use, optional
```

## Testing

The project uses CTest, with test cases written against GoogleTest (fetched
automatically via CMake's `FetchContent` -- see `tests/CMakeLists.txt`).
This is the project's concrete demonstration of the "dependency
management" feature: a real third-party dependency, fetched, built, and
linked entirely through CMake, isolated from this project's own
compiler-warning and sanitizer flags (see [Architecture](#architecture)).

Run all tests:

```bash
ctest --preset debug
```

Run with verbose output:

```bash
ctest --preset debug --output-on-failure
```

Example test layout:

```text
tests/
├── test_core.cpp
├── test_net.cpp
└── CMakeLists.txt
```

Test goals:

* verify library behavior
* verify CLI behavior
* verify install/export functionality
* verify sanitizer builds
* verify downstream package usage

## Test Results

Results from the most recent local end-to-end verification (Apple Clang
21, macOS arm64, CMake 4.3.2, Ninja). All 32 GoogleTest cases pass on
every preset; sanitizer presets reported zero issues on both the test
binary and the CLI binary exercised manually.

| Preset           | Configure | Build | Tests        | Notes                              |
| ---------------- | --------- | ----- | ------------ | ----------------------------------- |
| `debug`          | OK        | OK    | 32/32 passed |                                      |
| `release`        | OK        | OK    | 32/32 passed |                                      |
| `relwithdebinfo` | OK        | OK    | 32/32 passed |                                      |
| `asan`           | OK        | OK    | 32/32 passed | 0 sanitizer reports                 |
| `ubsan`          | OK        | OK    | 32/32 passed | 0 sanitizer reports                 |
| `tsan`           | OK        | OK    | 32/32 passed | 0 sanitizer reports                 |
| `coverage`       | OK        | OK    | 32/32 passed | see coverage table below            |
| `benchmark`      | OK        | OK    | n/a          | `buildlab-bench` runs, see Benchmarks |

Also verified end-to-end on this machine: `cmake --install` + `cpack`
(TGZ/ZIP) package generation and content layout, the `examples/downstream-project`
`find_package(buildlab)` consumption flow, `scripts/format.sh` (idempotent
on a second run), `scripts/run-clang-tidy.sh`, direct `cppcheck`, and the
full `Makefile` wrapper.

Coverage (Clang source-based coverage via `scripts/coverage.sh`, line
coverage column):

| File           | Lines covered |
| -------------- | -------------- |
| `src/core/core.c` | 100% |
| `src/net/net.cpp` | 100% |
| `src/cli/main.cpp` | 0% (exercised manually, not by the automated test suite) |
| **Total**      | **58%**        |

The CLI's argument-dispatch code is deliberately not part of the automated
coverage number above -- it's covered by the manual verification pass
described in this README, not by `buildlab_tests`. The two libraries that
ship to downstream consumers (`buildlab_core`, `buildlab_net`) are fully
covered.

GitHub Actions CI matrix (see badge at the top of this file for current
status): `ubuntu-latest`×{gcc-debug, gcc-release, clang-debug, clang-asan,
clang-ubsan}, `macos-latest`×{clang-release}, plus separate
`static-analysis` (clang-tidy) and `coverage` (lcov/gcov) jobs -- 8/8 jobs
passing as of the most recent push.

## Benchmarks

Benchmarks are optional and can be enabled through the benchmark preset.

```bash
cmake --preset benchmark
cmake --build --preset benchmark
./build/benchmark/benchmarks/buildlab-bench
```

Example benchmark areas:

* simple parsing helper
* string processing helper
* lightweight networking helper
* CLI startup overhead

The benchmark code is intentionally small because the focus of this repository is build infrastructure.

## Static Analysis

Run `clang-tidy`:

```bash
./scripts/run-clang-tidy.sh
```

Apple Clang does not ship `clang-tidy`. On macOS with Homebrew LLVM
installed, point the script at it explicitly:

```bash
CLANG_TIDY=/opt/homebrew/opt/llvm/bin/clang-tidy ./scripts/run-clang-tidy.sh build/debug
```

Run `cppcheck`:

```bash
cppcheck --enable=all --inconclusive --std=c++17 src include
```

Run formatting:

```bash
./scripts/format.sh
```

## Installation

Install the project locally:

```bash
cmake --preset release
cmake --build --preset release
cmake --install build/release --prefix install
```

Installed layout:

```text
install/
├── include/
│   └── buildlab/
├── lib/
│   ├── libbuildlab_core.a
│   └── libbuildlab_net.a
└── lib/cmake/buildlab/
    ├── buildlabConfig.cmake
    ├── buildlabConfigVersion.cmake
    └── buildlabTargets.cmake
```

## Downstream Usage

After installation, another CMake project can consume this package with:

```cmake
find_package(buildlab CONFIG REQUIRED)

add_executable(app main.cpp)

target_link_libraries(app
    PRIVATE
        buildlab::core
        buildlab::net
)
```

A full downstream example is included under:

```text
examples/downstream-project/
```

It is a standalone CMake project (its own `cmake_minimum_required`/`project()`),
deliberately not built as part of this repository's own preset-driven
build. Try it after installing the main project:

```bash
# 1. Build and install the main project
cmake --preset release
cmake --build --preset release
cmake --install build/release --prefix "$PWD/install"

# 2. Configure and build the downstream example against the installed package
cmake -S examples/downstream-project -B examples/downstream-project/build \
      -G Ninja -DCMAKE_PREFIX_PATH="$PWD/install"
cmake --build examples/downstream-project/build

# 3. Run it
./examples/downstream-project/build/downstream_app
```

## Packaging

Generate a package with CPack:

```bash
cmake --preset release
cmake --build --preset release
cpack --config build/release/CPackConfig.cmake
```

Possible package formats:

```text
TGZ
ZIP
DEB, optional
RPM, optional
```

## Toolchain Files

The `cmake/toolchains/` directory includes example toolchain files for selecting compilers and build environments.

Example:

```bash
cmake --preset linux-clang-debug
cmake --build --preset linux-clang-debug
```

Example toolchain file:

```cmake
set(CMAKE_C_COMPILER clang)
set(CMAKE_CXX_COMPILER clang++)
```

## Continuous Integration

The GitHub Actions workflow (`.github/workflows/ci.yml`) builds and tests
the project across multiple configurations, then runs static analysis and
coverage as separate jobs.

CI matrix (`build` job):

```text
Ubuntu + GCC + Debug
Ubuntu + GCC + Release
Ubuntu + Clang + Debug
Ubuntu + Clang + ASan
Ubuntu + Clang + UBSan
macOS + AppleClang + Release
```

Additional jobs:

* `static-analysis` -- configures the `debug` preset on Ubuntu and runs
  `scripts/run-clang-tidy.sh` against it.
* `coverage` -- configures the `coverage` preset on Ubuntu (real GCC,
  exercising the `lcov`/`gcov` path of `scripts/coverage.sh`) and uploads
  the HTML report as a build artifact.

ThreadSanitizer is intentionally not part of the CI matrix (it remains
available locally via the `tsan` preset).

See [Example GitHub Actions Workflow](.github/workflows/ci.yml) for the
full workflow file.

## Build Profiles

| Profile          | Purpose                              |
| ---------------- | ------------------------------------ |
| `debug`          | Development build with debug symbols |
| `release`        | Optimized build                      |
| `relwithdebinfo` | Optimized build with debug symbols   |
| `asan`           | Detect memory errors                 |
| `ubsan`          | Detect undefined behavior            |
| `tsan`           | Detect data races                    |
| `coverage`       | Generate test coverage report        |
| `benchmark`      | Build benchmark targets              |

## Example Commands

```bash
# Configure and build debug
cmake --preset debug
cmake --build --preset debug

# Run tests
ctest --preset debug --output-on-failure

# Run ASan build
cmake --preset asan
cmake --build --preset asan
ctest --preset asan --output-on-failure

# Install release build
cmake --preset release
cmake --build --preset release
cmake --install build/release --prefix install

# Generate package
cpack --config build/release/CPackConfig.cmake
```

## What This Project Demonstrates

This project demonstrates:

* modern CMake
* build presets
* C/C++ library organization
* target-based build design
* compiler warnings
* sanitizer integration
* coverage integration
* static analysis hooks
* CTest testing
* package installation
* exported CMake targets
* CPack packaging
* CI build matrix
* reproducible build workflows
* build engineering for systems projects

## Non-Goals

This project is not intended to be a large application or library.

Non-goals:

* implementing a complex C++ product
* replacing package managers such as Conan or vcpkg
* supporting every platform and compiler combination
* creating a full monorepo build system
* hiding CMake behind custom scripts
* maximizing demo application complexity

## Suggested Learning Path

If you are studying the project, review it in this order:

```text
1. Root CMakeLists.txt
2. CMakePresets.json
3. cmake/ProjectOptions.cmake
4. cmake/CompilerWarnings.cmake
5. src/core/CMakeLists.txt
6. src/net/CMakeLists.txt
7. tests/CMakeLists.txt
8. install/export rules
9. GitHub Actions workflow
```

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.
