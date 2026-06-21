# CMake Systems Build Lab

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

Update this checklist as implementation progresses.

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

The project uses CTest.

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

The GitHub Actions workflow builds and tests the project across multiple configurations.

Example CI matrix:

```text
Ubuntu + GCC + Debug
Ubuntu + GCC + Release
Ubuntu + Clang + Debug
Ubuntu + Clang + ASan
Ubuntu + Clang + UBSan
macOS + AppleClang + Release
```

Example workflow steps:

```text
checkout
install dependencies
configure preset
build preset
run CTest
run sanitizer tests
run static analysis
generate coverage, optional
```

## Example GitHub Actions Workflow

```yaml
name: CI

on:
  push:
  pull_request:

jobs:
  build:
    strategy:
      fail-fast: false
      matrix:
        include:
          - os: ubuntu-latest
            preset: debug
          - os: ubuntu-latest
            preset: release
          - os: ubuntu-latest
            preset: asan
          - os: ubuntu-latest
            preset: ubsan
          - os: macos-latest
            preset: release

    runs-on: ${{ matrix.os }}

    steps:
      - uses: actions/checkout@v4

      - name: Configure
        run: cmake --preset ${{ matrix.preset }}

      - name: Build
        run: cmake --build --preset ${{ matrix.preset }}

      - name: Test
        run: ctest --preset ${{ matrix.preset }} --output-on-failure
```

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

## Roadmap

### Phase 1: Core CMake Structure

* [ ] Add root `CMakeLists.txt`
* [ ] Add `CMakePresets.json`
* [ ] Add small C library target
* [ ] Add small C++ library target
* [ ] Add CLI executable target
* [ ] Add basic tests with CTest

### Phase 2: Build Profiles

* [ ] Add debug preset
* [ ] Add release preset
* [ ] Add ASan preset
* [ ] Add UBSan preset
* [ ] Add TSan preset
* [ ] Add coverage preset

### Phase 3: Quality Tooling

* [ ] Add compiler warnings module
* [ ] Add `clang-tidy` support
* [ ] Add `cppcheck` support
* [ ] Add formatting script
* [ ] Add CI workflow

### Phase 4: Packaging

* [ ] Add install rules
* [ ] Add exported targets
* [ ] Add package config generation
* [ ] Add downstream usage example
* [ ] Add CPack package generation

### Phase 5: Polish

* [ ] Add benchmark target
* [ ] Add Makefile wrapper
* [ ] Add toolchain file examples
* [ ] Add architecture diagram
* [ ] Add documentation for each build profile

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
