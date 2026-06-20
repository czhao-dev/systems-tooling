# LLDB

LLDB is the LLVM-based alternative to GDB, and the debugger that actually
works out of the box on macOS (no entitlement dance required). It's used the
same way GDB is here: breaking in `logforge::parse_line` and inspecting
`LogRecord` state, or getting a backtrace from `bugs/parser_crash.cpp`.

## Run it

```bash
./scripts/run_lldb.sh
```

Builds `build-debug/`, sets a breakpoint on `logforge::parse_line`, runs
`logforge --input logs/10k.log --status-counts`, prints a thread backtrace,
then continues. Output is saved to `results/lldb.log`.

## Run it by hand

```bash
lldb -- ./build-debug/logforge --input logs/10k.log --status-counts
```

```lldb
breakpoint set --name logforge::parse_line
run
next
step
frame variable line
thread backtrace
continue
```

Real captured output from a breakpoint hit (one worker thread, since
`--threads` defaults to 1):

```
Breakpoint 1: where = logforge`logforge::parse_line(...) + 52 at LogParser.cpp:45:15
(lldb) run
Process 44693 stopped
* thread #2, stop reason = breakpoint 1.1
    frame #0: ... logforge::parse_line(line="2026-06-19T10:00:02Z 192.168.5.71 GET /api/login 200 6ms") at LogParser.cpp:45:15
-> 45  	    if (!line.empty() && line.back() == '\r') {
```

## A crash, not a breakpoint: `bugs/parser_crash.cpp`

```bash
lldb -- ./build-debug/bugs/bug_parser_crash
```

```lldb
run
bt
```

This crashes via an *uncaught C++ exception* (`std::out_of_range` from
`tokens.at(5)`), not a signal raised directly by bad memory access. LLDB
reports it as `stop reason = signal SIGABRT` at `__pthread_kill`, because
`libc++abi` converts the uncaught exception into `abort()`.

**Caveat observed while writing this doc:** when `run` stops on an
*unexpected* signal (as opposed to a breakpoint you set), `lldb --batch` cuts
off the remaining queued `-o` commands — `bt` after `run` silently doesn't
execute in batch mode for this case, even though the process is still
stopped. `scripts/run_lldb.sh` avoids this by breaking on a known location
(`logforge::parse_line`) first; for the crash demo, drop `--batch` and debug
interactively instead.

## Platform note

LLDB occasionally failed to let the debuggee open `logs/10k.log` (a file that
demonstrably exists and opens fine outside the debugger) when this project
lives under `~/Documents`. This traces to macOS's per-process TCC (privacy)
permissions for the `debugserver` helper LLDB spawns, not a bug in the
program or scripts. If you hit `failed to open input file` under LLDB but the
binary works fine standalone, check System Settings → Privacy & Security →
Files and Folders for `debugserver`/`lldb`, or move the project outside a
TCC-protected folder.

## Lessons learned

* `frame variable` (LLDB) and `print` (GDB) serve the same purpose; LLDB's
  `bt`/`thread backtrace` and GDB's `backtrace` are likewise near-identical —
  the workflow transfers directly between the two.
* Batch-mode debugging is reliable for breakpoint-driven scripts, but not for
  "run until it crashes and inspect" sessions — use interactive mode for the
  latter.
