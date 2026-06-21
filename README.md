# SysDoctor

A Bash-based Linux system diagnostics and health report tool.

`sysdoctor` collects CPU, memory, disk, network, process, service, log, and container diagnostics, then generates a readable Markdown or JSON report. It is designed for quick troubleshooting, incident triage, Linux administration practice, and systems/backend portfolio demonstration.

## Overview

SysDoctor is a standalone shell tool for inspecting the health of a Linux machine.

It can answer questions such as:

* Is the system under CPU or memory pressure?
* Is disk space or inode usage close to full?
* Which processes are consuming the most resources?
* Which ports are listening?
* Are important services running?
* Are there recent system errors?
* Is DNS and outbound network connectivity working?
* Are Docker containers healthy?
* What should be checked next?

The goal is not to replace full observability platforms such as Prometheus, Grafana, Datadog, or New Relic. Instead, this project implements a practical command-line diagnostics tool using standard Linux utilities and defensive Bash scripting.

## Features

### System Diagnostics

* [x] OS and kernel information
* [x] Hostname and uptime
* [x] CPU load average
* [x] CPU core count
* [x] Memory usage
* [x] Swap usage
* [x] Disk usage
* [x] Inode usage
* [x] Top processes by CPU
* [x] Top processes by memory

### Network Diagnostics

* [x] Network interface summary
* [x] Listening ports
* [x] Default gateway
* [x] DNS resolution check
* [x] Internet connectivity check
* [x] HTTP endpoint check
* [x] Optional latency check with `ping`

### Service Diagnostics

* [x] Check systemd service status
* [x] Show failed systemd units
* [x] Show recent service logs
* [x] Detect unavailable `systemctl` gracefully

### Log Diagnostics

* [x] Scan recent system logs
* [x] Detect common error patterns
* [x] Count warnings and errors
* [x] Show recent critical log entries
* [x] Support both `journalctl` and fallback log files

### Docker Diagnostics, Optional

* [x] List running containers
* [x] Show unhealthy containers
* [x] Show restart counts
* [x] Show container resource usage, if available
* [x] Detect unavailable Docker gracefully

### Reports

* [x] Human-readable terminal output
* [x] Markdown report
* [x] JSON report
* [x] Summary recommendations
* [x] Configurable output path

### Developer Experience

* [x] Strict Bash mode
* [x] ShellCheck-compatible scripts
* [x] Modular script layout
* [x] Bats tests
* [x] GitHub Actions CI
* [x] Sample reports

Update the checklist as implementation progresses.

## Motivation

When debugging Linux systems, engineers often run many commands manually:

```bash
top
free -h
df -h
ss -tulpen
journalctl -p err
systemctl --failed
docker ps
```

SysDoctor automates this workflow and turns the results into a structured report. It is useful for learning Linux operations, practicing Bash scripting, and demonstrating practical systems troubleshooting skills.

## Example Output

```text
SysDoctor Health Report
Generated: 2026-06-21 14:30:12

System:
  Hostname: devbox
  OS: Ubuntu 24.04
  Kernel: 6.8.0
  Uptime: 5 days, 3 hours

CPU:
  Load average: 0.52 0.61 0.58
  CPU cores: 8
  Status: OK

Memory:
  Used: 6.2 GiB / 16.0 GiB
  Swap: 0.0 GiB / 2.0 GiB
  Status: OK

Disk:
  /: 68% used
  /var: 82% used
  Status: WARNING

Network:
  Default gateway: 192.168.1.1
  DNS check: OK
  Internet check: OK

Services:
  Failed units: 1
  nginx: active
  postgresql: active
  docker: active

Recommendations:
  - Check disk usage under /var.
  - Investigate failed systemd unit: backup.service.
```

## Quick Start

Clone the repository:

```bash
git clone https://github.com/czhao-dev/sysdoctor.git
cd sysdoctor
```

Make the script executable:

```bash
chmod +x sysdoctor.sh
```

Run a full diagnostic report:

```bash
./sysdoctor.sh --full
```

Generate a Markdown report:

```bash
./sysdoctor.sh --full --format markdown --output report.md
```

Generate a JSON report:

```bash
./sysdoctor.sh --full --format json --output report.json
```

## Usage

```text
Usage:
  sysdoctor.sh [options]

Options:
  --full                         Run all diagnostics
  --system                       Run system diagnostics
  --cpu                          Show CPU diagnostics
  --memory                       Show memory diagnostics
  --disk                         Show disk diagnostics
  --network                      Show network diagnostics
  --services                     Show service diagnostics
  --logs                         Show recent log diagnostics
  --docker                       Show Docker diagnostics
  --service NAME                 Check a specific systemd service
  --url URL                      Check an HTTP endpoint
  --format text|markdown|json    Output format
  --output PATH                  Write report to file
  --verbose                      Print detailed diagnostics
  --quiet                        Print only summary
  --help                         Show help message
```

## Example Commands

Run all checks:

```bash
./sysdoctor.sh --full
```

Check CPU, memory, and disk only:

```bash
./sysdoctor.sh --cpu --memory --disk
```

Check network and DNS:

```bash
./sysdoctor.sh --network
```

Check a service:

```bash
./sysdoctor.sh --service nginx
```

Check an HTTP endpoint:

```bash
./sysdoctor.sh --url https://example.com/health
```

Write a Markdown report:

```bash
./sysdoctor.sh --full --format markdown --output reports/health-report.md
```

Write a JSON report:

```bash
./sysdoctor.sh --full --format json --output reports/health-report.json
```

## Project Structure

```text
sysdoctor/
├── README.md
├── LICENSE
├── sysdoctor.sh
├── lib/
│   ├── common.sh
│   ├── system.sh
│   ├── cpu.sh
│   ├── memory.sh
│   ├── disk.sh
│   ├── network.sh
│   ├── services.sh
│   ├── logs.sh
│   ├── docker.sh
│   ├── report_text.sh
│   ├── report_markdown.sh
│   └── report_json.sh
├── tests/
│   ├── common.bats
│   ├── parsing.bats
│   ├── report.bats
│   └── fixtures/
├── examples/
│   ├── sample-report.md
│   └── sample-report.json
├── scripts/
│   ├── install.sh
│   └── run-shellcheck.sh
└── .github/
    └── workflows/
        └── ci.yml
```

## Design Principles

### Defensive Bash

SysDoctor uses strict Bash settings:

```bash
set -euo pipefail
```

The script is designed to handle missing commands, permission issues, and platform differences gracefully.

### Portable Linux Tooling

SysDoctor relies on common Linux tools when available:

```text
uname
uptime
free
df
du
ps
ss
ip
ping
curl
systemctl
journalctl
docker
```

When a tool is missing, SysDoctor reports the missing dependency instead of failing unexpectedly.

### Human-Readable Reports

The default output is intended for terminal use. Markdown reports are useful for incident notes, pull requests, tickets, and documentation. JSON reports are useful for automation and future integrations.

### No Destructive Actions

SysDoctor is read-only by default. It does not delete files, restart services, change system settings, or modify firewall rules.

## Diagnostics Details

### CPU Checks

CPU diagnostics include:

* load average
* CPU core count
* load-per-core estimate
* top CPU-consuming processes

Example warning rule:

```text
If 1-minute load average > number of CPU cores, report CPU pressure.
```

### Memory Checks

Memory diagnostics include:

* total memory
* used memory
* available memory
* swap usage
* top memory-consuming processes

Example warning rule:

```text
If available memory is below 10%, report memory pressure.
```

### Disk Checks

Disk diagnostics include:

* filesystem usage
* inode usage
* largest mount points
* warning threshold
* critical threshold

Example warning rules:

```text
Disk usage >= 80%: warning
Disk usage >= 90%: critical
Inode usage >= 80%: warning
Inode usage >= 90%: critical
```

### Network Checks

Network diagnostics include:

* network interfaces
* default route
* DNS lookup
* outbound connectivity
* listening ports
* optional HTTP endpoint checks

Example checks:

```bash
getent hosts google.com
curl -I --max-time 5 https://example.com
ss -tulpen
```

### Service Checks

Service diagnostics include:

* failed systemd units
* specific service status
* recent logs for selected services

Example:

```bash
./sysdoctor.sh --service postgresql
```

### Log Checks

Log diagnostics scan recent logs for common error patterns:

```text
error
failed
critical
panic
timeout
out of memory
permission denied
connection refused
```

SysDoctor prefers `journalctl` when available and falls back to common log files such as `/var/log/syslog` or `/var/log/messages`.

### Docker Checks

Docker diagnostics include:

* running containers
* stopped containers
* unhealthy containers
* restart counts
* container resource usage, if available

Docker checks are skipped if Docker is not installed or the user does not have permission to access the Docker daemon.

## Configuration

SysDoctor can optionally read a simple configuration file:

```bash
./sysdoctor.sh --config sysdoctor.conf --full
```

Example `sysdoctor.conf`:

```bash
DISK_WARNING_THRESHOLD=80
DISK_CRITICAL_THRESHOLD=90
MEMORY_WARNING_THRESHOLD=90
PING_TARGET="8.8.8.8"
DNS_TEST_HOST="google.com"
HTTP_TEST_URL="https://example.com"
LOG_LOOKBACK="1h"
```

## Testing

This project uses Bats for shell tests.

Run tests:

```bash
bats tests/
```

Run ShellCheck:

```bash
shellcheck sysdoctor.sh lib/*.sh
```

Run all checks:

```bash
./scripts/run-shellcheck.sh
bats tests/
```

## CI

The GitHub Actions workflow runs:

* ShellCheck
* Bats tests
* basic execution smoke tests

Example CI workflow:

```yaml
name: CI

on:
  push:
  pull_request:

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Install dependencies
        run: |
          sudo apt-get update
          sudo apt-get install -y shellcheck bats

      - name: Run ShellCheck
        run: shellcheck sysdoctor.sh lib/*.sh

      - name: Run tests
        run: bats tests/
```

## Example Markdown Report

```markdown
# SysDoctor Health Report

Generated: 2026-06-21 14:30:12

## Summary

| Category | Status |
|---|---|
| CPU | OK |
| Memory | OK |
| Disk | WARNING |
| Network | OK |
| Services | WARNING |
| Logs | WARNING |

## Recommendations

- Check disk usage under `/var`.
- Investigate failed systemd unit `backup.service`.
- Review recent error logs from the last hour.
```

## Roadmap

### Phase 1: Core Diagnostics

* [ ] Add system summary
* [ ] Add CPU diagnostics
* [ ] Add memory diagnostics
* [ ] Add disk diagnostics
* [ ] Add text output

### Phase 2: Network and Services

* [ ] Add network interface summary
* [ ] Add DNS check
* [ ] Add HTTP endpoint check
* [ ] Add listening port report
* [ ] Add systemd service checks

### Phase 3: Logs and Docker

* [ ] Add journal log scanning
* [ ] Add error-pattern detection
* [ ] Add Docker diagnostics
* [ ] Add container health checks

### Phase 4: Reports

* [ ] Add Markdown output
* [ ] Add JSON output
* [ ] Add configurable thresholds
* [ ] Add sample reports

### Phase 5: Quality and Polish

* [ ] Add Bats tests
* [ ] Add ShellCheck CI
* [ ] Add installation script
* [ ] Add architecture notes
* [ ] Add demo screenshots or terminal recordings

## What This Project Demonstrates

This project demonstrates:

* Bash scripting
* Linux diagnostics
* systems troubleshooting
* process inspection
* disk and memory analysis
* network debugging
* log analysis
* Docker inspection
* defensive shell scripting
* report generation
* CLI design
* testable shell code with Bats
* CI for shell projects

## Limitations

SysDoctor is intended as a lightweight diagnostics helper.

Limitations:

* It is not a continuous monitoring system.
* It does not replace centralized logging or metrics platforms.
* Some checks require Linux-specific tools.
* Some service and log checks may require elevated permissions.
* Docker checks require Docker access.
* Output may vary across Linux distributions.

## Safety

SysDoctor is designed to be read-only. It does not:

* delete files
* restart services
* kill processes
* change firewall rules
* modify system configuration
* install packages automatically

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.
