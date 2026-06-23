# systems-dev-tools

A collection of systems engineering and developer tooling projects spanning build infrastructure, systems debugging and performance profiling, Linux diagnostics, and git tooling. Each subdirectory is a self-contained project with its own build system, tests, and CI; this top-level README is a map of what's here.

| Project | Stack | Description |
|---|---|---|
| [cmake-systems-build-lab](cmake-systems-build-lab/README.md) | C/C++17, CMake | Build-engineering lab demonstrating production-style CMake infrastructure: presets, sanitizers, coverage, CTest, dependency management, packaging, and CI. |
| [git-commit-report-generator](git-commit-report-generator/README.md) | Perl | CLI tool that analyzes local git commit history and generates activity reports by author, date, directory, file type, and change size. |
| [linux-sys-report-cli](linux-sys-report-cli/README.md) | Bash | Linux system diagnostics tool that collects CPU, memory, disk, network, service, log, and container data into text, Markdown, or JSON reports. |
| [systems-debugging-lab](systems-debugging-lab/README.md) | C++17 | "LogForge" — a multithreaded log analytics engine used as a sandbox for systems debugging, profiling, and tracing workflows (GDB, LLDB, Valgrind, sanitizers, strace, perf). |

## cmake-systems-build-lab

A modern CMake build-engineering lab for C/C++ systems projects. The application code (a small `core`/`net`/`cli` set of libraries and an executable) is intentionally minimal — the point of the project is the build system around it.

- Target-based CMake with `CMakePresets.json` covering debug, release, relwithdebinfo, ASan, UBSan, TSan, coverage, and benchmark configurations
- Compiler warning profiles, `clang-tidy`/`cppcheck` static analysis hooks, and `clang-format` integration
- CTest-driven unit/integration tests against GoogleTest (fetched via `FetchContent`, isolated from the project's own warning/sanitizer flags)
- Install rules, exported CMake package targets (`find_package(buildlab)`), and CPack packaging (TGZ/ZIP)
- GitHub Actions CI matrix across GCC/Clang, Linux/macOS, debug/release/sanitizer builds, plus separate static-analysis and coverage jobs

```bash
cd cmake-systems-build-lab
cmake --preset debug && cmake --build --preset debug && ctest --preset debug
```

## git-commit-report-generator

A Perl CLI that turns local git history into engineering activity reports — commits by author, changed files by directory/extension, largest and "risky" commits, and optional commit-type classification (feature/bugfix/refactor/test/docs/build) by commit-message keyword.

- Filters by date range, author, branch, and path
- Output as text, Markdown, CSV, or JSON; reports can be written to a file
- Driven by `git log` / `git show` / `git diff --stat` output, parsed into structured records by `lib/GitCommitReport/Parser.pm` and summarized by `Analyzer.pm`
- Optional YAML config file for classification keywords and thresholds
- Unit tests under `t/`, run via `prove -l t/`

```bash
cd git-commit-report-generator
perl bin/git_commit_report.pl --since "7 days ago" --format markdown
```

## linux-sys-report-cli

A dependency-free Bash tool for Linux system health checks and incident triage — CPU, memory, disk, network, systemd services, logs, and Docker containers, rolled up into a single report with a summary and exit code suitable for cron/CI gates.

- Per-category checks (`--cpu`, `--memory`, `--disk`, `--network`, `--services`, `--logs`, `--docker`, or `--full` for everything), each degrading to `UNKNOWN` rather than failing if a required tool (`systemctl`, `docker`, `ss`, ...) isn't present
- Output as text, Markdown, or JSON; exit codes `0`/`1`/`2`/`3` map to OK/WARNING/CRITICAL/UNKNOWN
- Configurable thresholds (disk/inode/memory) and targets (ping host, DNS test host, HTTP endpoint) via an allowlisted `KEY=VALUE` config file
- Read-only by design — never restarts services, kills processes, or modifies configuration
- ShellCheck-clean, 34 Bats tests, CI runs ShellCheck + Bats + smoke tests of all three output formats

```bash
cd linux-sys-report-cli
./linux-sys-report-cli.sh --full --format markdown
```

## systems-debugging-lab

"LogForge" — a multithreaded C++17 log analytics engine (status-code aggregation, top-IP/top-path queries, latency percentiles, optional query index) built specifically as a hands-on sandbox for systems debugging and performance work, paired with `bugs/` demos and `docs/` write-ups for each tool.

- Interactive debugging: GDB and LLDB
- Memory/correctness: Valgrind Memcheck, AddressSanitizer, LeakSanitizer, ThreadSanitizer, UndefinedBehaviorSanitizer
- Tracing and profiling: strace/dtruss, perf, gprof, gprofng, Valgrind Massif, heaptrack, Cachegrind, Callgrind
- Quality tooling: clang-tidy, cppcheck, clang-format, gcov/lcov/llvm-cov coverage
- Each `bugs/*.cpp` file is an isolated, intentionally flawed implementation used to demonstrate one specific tool/technique; `docs/*.md` documents the problem → tool → root cause → fix → result for each
- A Docker dev environment (`docker/`) provides Linux-only tools (Valgrind, perf, gprof/gprofng, heaptrack) on any host

```bash
cd systems-debugging-lab
cmake -B build -DCMAKE_BUILD_TYPE=Release && cmake --build build
./build/logforge --input logs/server.log --status-counts
```

## License

This repository is licensed under the [MIT License](LICENSE).
