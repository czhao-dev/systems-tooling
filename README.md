# SysDoctor

[![CI](https://github.com/czhao-dev/sysdoctor/actions/workflows/ci.yml/badge.svg)](https://github.com/czhao-dev/sysdoctor/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Shell: Bash](https://img.shields.io/badge/Shell-Bash-4EAA25)](sysdoctor.sh)

A Bash-based Linux system diagnostics and health report tool.

`sysdoctor` collects CPU, memory, disk, network, process, service, log, and container diagnostics, then generates a readable text, Markdown, or JSON report. It's built for quick troubleshooting, incident triage, and as a practical demonstration of systems/backend scripting skills.

## Overview

SysDoctor is a standalone shell tool for inspecting the health of a Linux machine. It answers questions such as:

- Is the system under CPU or memory pressure?
- Is disk space or inode usage close to full?
- Which processes are consuming the most resources?
- Which ports are listening?
- Are important services running?
- Are there recent system errors?
- Is DNS and outbound network connectivity working?
- Are Docker containers healthy?
- What should be checked next?

The goal isn't to replace observability platforms like Prometheus, Grafana, or Datadog. Instead, this project implements a single-file-friendly, dependency-free diagnostics tool using standard Linux utilities and defensive Bash scripting.

## Features

- **System** — OS, kernel, hostname, and uptime
- **CPU** — load average, core count, load-per-core, top consumers
- **Memory** — usage, swap, top consumers, configurable pressure thresholds
- **Disk** — filesystem and inode usage with warning/critical thresholds
- **Network** — interfaces, default gateway, DNS, internet connectivity, optional HTTP endpoint check, listening ports
- **Services** — failed systemd units, single-service status and logs
- **Logs** — scans `journalctl` or fallback log files for common error patterns
- **Docker** — running/stopped/unhealthy containers, restart counts, resource usage (optional, skipped gracefully if Docker isn't available)
- **Reports** — terminal, Markdown, or JSON output, with summary recommendations and a configurable output path

Every check degrades gracefully: if a tool (`systemctl`, `docker`, `ss`, ...) isn't available, that section reports `UNKNOWN` instead of crashing the whole run.

## Quick Start

Clone the repository, make the entrypoint executable, and run a full report straight from the working directory — no build step or dependencies beyond standard Bash and coreutils. A sample run looks like the reports checked into [`examples/`](examples/): a Markdown report at [`examples/sample-report.md`](examples/sample-report.md) and the equivalent JSON at [`examples/sample-report.json`](examples/sample-report.json).

For a system-wide `sysdoctor` command, run `scripts/install.sh`, which copies the project into a prefix (`/usr/local` by default, or pass `--prefix` for a user-local install) and symlinks the entrypoint onto `PATH`.

## Usage

Run `sysdoctor.sh [options]` from the project directory (or `sysdoctor [options]` if installed via `scripts/install.sh`).

| Option | Description |
|---|---|
| `--full` | Run all diagnostics |
| `--system`, `--cpu`, `--memory`, `--disk`, `--network`, `--services`, `--logs`, `--docker` | Run an individual diagnostic category |
| `--service NAME` | Check a specific systemd service |
| `--url URL` | Check an HTTP endpoint |
| `--format text\|markdown\|json` | Output format (default: `text`) |
| `--output PATH` | Write the report to a file instead of stdout |
| `--config PATH` | Load thresholds and targets from a config file |
| `--verbose` | Print more detail (more processes, more log lines, more ports) |
| `--quiet` | Print only the summary and recommendations |
| `--help` | Show the help message |

The process exits `0` (OK), `1` (WARNING), `2` (CRITICAL), or `3` (UNKNOWN), reflecting the worst status across every category that ran — handy for cron jobs or CI gates.

## Configuration

SysDoctor optionally reads a `KEY=VALUE` config file via `--config`, parsed defensively (no arbitrary code execution — only a fixed allowlist of keys is accepted). Supported keys: `DISK_WARNING_THRESHOLD`, `DISK_CRITICAL_THRESHOLD`, `INODE_WARNING_THRESHOLD`, `INODE_CRITICAL_THRESHOLD`, `MEMORY_WARNING_THRESHOLD`, `MEMORY_CRITICAL_THRESHOLD`, `PING_TARGET`, `DNS_TEST_HOST`, `HTTP_TEST_URL`, and `LOG_LOOKBACK`. See [`tests/fixtures/sample.conf`](tests/fixtures/sample.conf) for an example.

## Project Structure

- [`sysdoctor.sh`](sysdoctor.sh) — entrypoint: argument parsing, dispatch, exit-code mapping
- `lib/` — one module per concern: `common`, `system`, `cpu`, `memory`, `disk`, `network`, `services`, `logs`, `docker`, plus `report_text`, `report_markdown`, and `report_json` formatters
- `tests/` — Bats test suite (`common.bats`, `parsing.bats`, `report.bats`) and fixtures
- `examples/` — sample generated reports
- `scripts/` — `install.sh` and `run-shellcheck.sh`
- `.github/workflows/ci.yml` — GitHub Actions pipeline

## Design Principles

**Defensive Bash.** The entrypoint runs under `set -euo pipefail`, with care taken to avoid the classic pitfalls that strict mode introduces around pipelines and `SIGPIPE` (e.g. truncating process listings never closes a pipe early on an upstream producer).

**Portable where it can be, Linux-first where it matters.** Checks prefer Linux-native sources (`/proc/loadavg`, `/proc/meminfo`, `journalctl`, `systemctl`) and fall back to portable equivalents where reasonable, but service and log diagnostics are inherently systemd/Linux-specific and report `UNKNOWN` elsewhere rather than guessing.

**Human-readable by default, structured on request.** Terminal output is for humans; Markdown is for incident notes and PRs; JSON is for automation.

**No destructive actions.** SysDoctor is read-only. It never deletes files, restarts services, kills processes, or changes system configuration.

## Testing & Quality

- **ShellCheck:** zero warnings across `sysdoctor.sh`, every file in `lib/`, and `scripts/` (run via `./scripts/run-shellcheck.sh`).
- **Bats:** 34 tests passing, covering shared helpers (status ranking, JSON escaping, config loading), CLI argument parsing, and all three report formatters (run via `bats tests/`).
- **CI:** every push and pull request runs ShellCheck, the full Bats suite, and end-to-end smoke tests of all three output formats on `ubuntu-latest` via GitHub Actions.

## What This Project Demonstrates

- Bash scripting and CLI design
- Linux systems troubleshooting and diagnostics
- Process, disk, memory, and network inspection
- Log analysis and Docker inspection
- Defensive shell scripting (strict mode, graceful degradation, safe config parsing)
- Report generation across multiple output formats
- Testable shell code with Bats, and CI for shell projects

## Limitations

SysDoctor is a lightweight diagnostics helper, not a continuous monitoring system:

- It does not replace centralized logging or metrics platforms.
- Some checks require Linux-specific tools and report `UNKNOWN` elsewhere.
- Some service and log checks may require elevated permissions.
- Docker checks require Docker daemon access.
- Output may vary across Linux distributions.

## Safety

SysDoctor is read-only by design. It does not delete files, restart services, kill processes, change firewall rules, modify system configuration, or install packages.

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.
