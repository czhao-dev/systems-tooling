# systems-dev-tools

A collection of systems engineering and developer tooling projects — build infrastructure, debugging/profiling workflows, system diagnostics, and git tooling.

| Project | Stack | Description |
|---|---|---|
| [cmake-systems-build-lab](cmake-systems-build-lab/README.md) | C/C++17, CMake | Build-engineering lab demonstrating production-style CMake infrastructure: presets, sanitizers, coverage, CTest, dependency management, packaging, and CI. |
| [git-commit-report-generator](git-commit-report-generator/README.md) | Perl | CLI tool that analyzes local git commit history and generates activity reports by author, date, directory, file type, and change size. |
| [linux-sys-report-cli](linux-sys-report-cli/README.md) | Bash | Linux system diagnostics tool that collects CPU, memory, disk, network, service, log, and container data into text, Markdown, or JSON reports. |
| [systems-debugging-lab](systems-debugging-lab/README.md) | C++17 | "LogForge" — a multithreaded log analytics engine used as a sandbox for systems debugging, profiling, and tracing workflows (GDB, LLDB, Valgrind, sanitizers, strace, perf). |

Each project keeps its own README with detailed setup and usage instructions.

## License

This repository is licensed under the [MIT License](LICENSE).
