# systems-tooling

A collection of systems engineering and developer tooling projects spanning build infrastructure, debugging and performance profiling, Linux diagnostics, git history analysis, and supply-chain vulnerability scanning. Each subdirectory is a self-contained project with its own build system, tests, and CI.

| Project | Stack | Description |
|---|---|---|
| [cmake-systems-build-lab](cmake-systems-build-lab/README.md) | C/C++17, CMake | Production-style CMake build infrastructure: presets, sanitizers, coverage, CTest, packaging, and CI. |
| [git-commit-report-generator](git-commit-report-generator/README.md) | Perl | CLI tool that parses local git history and generates activity reports by author, date, directory, file type, and commit classification. |
| [linux-sys-report-cli](linux-sys-report-cli/README.md) | Bash | Dependency-free Linux diagnostics tool: CPU, memory, disk, network, services, logs, and Docker — output as text, Markdown, or JSON. |
| [osv-dep-scanner-cli](osv-dep-scanner-cli/README.md) | Ruby | Supply-chain vulnerability scanner: discovers npm/PyPI/Cargo/Go lockfiles, queries the OSV.dev API, and reports findings with a CI-gateable exit code. |
| [systems-debugging-lab](systems-debugging-lab/README.md) | C++17 | "LogForge" — a multithreaded log analytics engine used as a hands-on sandbox for GDB, LLDB, Valgrind, sanitizers, strace, perf, and more. |

## cmake-systems-build-lab

A modern CMake build-engineering lab for C/C++ systems projects. The application code (a small `core`/`net`/`cli` set of libraries and an executable) is intentionally minimal — the build system is the focus.

- Target-based CMake with `CMakePresets.json` covering debug, release, relwithdebinfo, ASan, UBSan, TSan, coverage, and benchmark configurations
- Compiler warning profiles, `clang-tidy`/`cppcheck` static-analysis hooks, and `clang-format` integration
- CTest-driven tests against GoogleTest fetched via `FetchContent`, isolated from the project's own sanitizer and warning flags
- Install rules, exported CMake package targets (`find_package(buildlab)`), and CPack packaging (TGZ/ZIP)
- GitHub Actions CI matrix across GCC/Clang on Linux/macOS, plus separate static-analysis and coverage jobs

```bash
cd cmake-systems-build-lab
cmake --preset debug && cmake --build --preset debug && ctest --preset debug
```

## git-commit-report-generator

A Perl CLI that turns local git history into engineering activity reports — commits by author, changed files by directory/extension, largest and risky commits, and optional commit-type classification by message keyword.

- Filters by date range, author, branch, and path prefix
- Output as text, Markdown, CSV, or JSON; reports can be written to a file
- Driven by `git log`/`git show`/`git diff --stat`, parsed by `lib/GitCommitReport/Parser.pm` and summarized by `Analyzer.pm`
- YAML config file for classification keywords and thresholds; unit tests under `t/` run via `prove`

```bash
cd git-commit-report-generator
perl bin/git_commit_report.pl --since "7 days ago" --format markdown
```

## linux-sys-report-cli

A dependency-free Bash tool for Linux system health checks and incident triage — CPU, memory, disk, network, systemd services, logs, and Docker containers, rolled into a single report with an exit code suitable for cron/CI gates.

- Per-category flags (`--cpu`, `--memory`, `--disk`, `--network`, `--services`, `--logs`, `--docker`, or `--full`), each degrading to `UNKNOWN` rather than failing if a required tool isn't present
- Output as text, Markdown, or JSON; exit codes `0`/`1`/`2`/`3` map to OK/WARNING/CRITICAL/UNKNOWN
- Configurable thresholds and targets via an allowlisted `KEY=VALUE` config file; read-only by design
- ShellCheck-clean, 34 Bats tests, CI on every push

```bash
cd linux-sys-report-cli
./linux-sys-report-cli.sh --full --format markdown
```

## osv-dep-scanner-cli

A Ruby CLI that discovers dependency lockfiles across four ecosystems (npm, PyPI, Cargo, Go modules), queries the [OSV.dev](https://osv.dev) vulnerability database, and reports known vulnerabilities as text, Markdown, or JSON — with a CI-gateable exit code.

- Zero runtime gem dependencies; parses `package-lock.json`, `requirements.txt`, `Cargo.lock`, and `go.mod` using only Ruby's standard library
- Batch-queries OSV.dev's `/v1/querybatch` endpoint, then hydrates unique vulnerability IDs concurrently via `/v1/vulns/{id}`
- Derives severity from CVSS vectors and database-specific fields; deduplicates findings across shared vulnerability IDs
- Duck-typed OSV client for network-free unit tests; 52 Minitest cases; RuboCop and live CI smoke test

```bash
cd osv-dep-scanner-cli
bundle install && ./bin/osv-dep-scanner --path examples --format markdown
```

## systems-debugging-lab

"LogForge" — a multithreaded C++17 log analytics engine (status-code aggregation, top-IP/top-path queries, latency percentiles, optional query index) built as a hands-on sandbox for systems debugging and performance engineering.

- Interactive debugging with GDB and LLDB
- Memory and correctness checking with Valgrind Memcheck, AddressSanitizer, LeakSanitizer, ThreadSanitizer, and UndefinedBehaviorSanitizer
- CPU and heap profiling with strace/dtruss, perf, gprof, gprofng, Valgrind Massif, heaptrack, Cachegrind, and Callgrind
- Quality tooling: clang-tidy, cppcheck, clang-format, gcov/lcov/llvm-cov coverage
- `bugs/` contains isolated, intentionally flawed implementations; `docs/` documents each tool's problem → root cause → fix → result workflow
- Docker dev environment provides Linux-only tools (Valgrind, perf, gprofng, heaptrack) on any host

```bash
cd systems-debugging-lab
cmake -B build -DCMAKE_BUILD_TYPE=Release && cmake --build build
./build/logforge --input logs/server.log --status-counts
```

## References

### Build Infrastructure
- [CMake Documentation](https://cmake.org/cmake/help/latest/)
- [CMake Presets Reference](https://cmake.org/cmake/help/latest/manual/cmake-presets.7.html)
- [GoogleTest](https://github.com/google/googletest)
- [CPack](https://cmake.org/cmake/help/latest/module/CPack.html)

### Debugging and Profiling
- [GDB Documentation](https://sourceware.org/gdb/current/onlinedocs/gdb/)
- [LLDB Documentation](https://lldb.llvm.org/use/tutorial.html)
- [Valgrind Manual](https://valgrind.org/docs/manual/manual.html)
- [Linux perf](https://perf.wiki.kernel.org/index.php/Main_Page)
- [AddressSanitizer (Clang)](https://clang.llvm.org/docs/AddressSanitizer.html)

### Static Analysis and Tooling
- [clang-tidy](https://clang.llvm.org/extra/clang-tidy/)
- [cppcheck](https://cppcheck.sourceforge.io/)
- [ShellCheck](https://www.shellcheck.net/)
- [RuboCop](https://rubocop.org/)

### Vulnerability Data
- [OSV.dev API Reference](https://google.github.io/osv.dev/api/)
- [OSV Schema](https://ossf.github.io/osv-schema/)

### Testing
- [Bats — Bash Automated Testing System](https://bats-core.readthedocs.io/)
- [Test::More (Perl)](https://perldoc.perl.org/Test::More)
- [Minitest (Ruby)](https://github.com/minitest/minitest)

## License

This repository is licensed under the [MIT License](LICENSE).
