# GDB

GDB is used for interactive, source-level debugging of crashes and incorrect
program state. In this repo it's the primary tool for stepping through
`LogParser::parse_line` and inspecting `LogRecord` values, and for getting a
backtrace out of the crash demo in `bugs/parser_crash.cpp`.

## Run it

```bash
./scripts/run_gdb.sh
```

This builds `build-debug/` (`-DCMAKE_BUILD_TYPE=Debug`), sets a breakpoint on
`logforge::parse_line`, runs `logforge --input logs/10k.log --status-counts`,
prints a backtrace, then continues. Combined output is saved to
`results/gdb.log`.

## Run it by hand

```bash
cmake -B build-debug -DCMAKE_BUILD_TYPE=Debug
cmake --build build-debug
gdb --args ./build-debug/logforge --input logs/10k.log --status-counts
```

```gdb
break logforge::parse_line
run
next
step
print line
backtrace
continue
```

To debug the crash demo instead:

```bash
gdb --args ./build-debug/bugs/bug_parser_crash
```

```gdb
run
backtrace
frame 1
print tokens
```

`tokens.at(5)` throws `std::out_of_range` because `parse_unsafe()` assumes six
whitespace-separated fields are always present; the backtrace lands in
`std::vector::at`, with frame 1 showing the call site and the (too-short)
`tokens` vector.

## Platform note

**Homebrew's GDB does not work out of the box on macOS.** It isn't
code-signed with the `get-task-allow` entitlement, so the kernel refuses to
let it attach to or launch a process:

```
Don't know how to run.  Try "help target".
No stack.
```

`scripts/run_gdb.sh` still runs and logs this failure faithfully — the
logging mechanism works, but the debugging session doesn't. To actually use
GDB, either self-sign the binary with a `get-task-allow` entitlement (see
GDB's own `wiki/PermissionsDarwin`), or — simpler — run it inside the Docker
dev environment (`docs/docker_dev_environment.md`), which is Linux and needs
no special entitlements (the compose file already grants `SYS_PTRACE`).

## Lessons learned

* `--batch` mode with breakpoint commands is good for scripted, repeatable
  debugging sessions (see `run_gdb.sh`); it's a poor fit for chasing an
  *unexpected* crash, since the interesting part is exploring state
  interactively once stopped.
* GDB on macOS is a trap for portfolio purposes: it installs and runs the
  *gdb* process fine, but can't actually control a target without extra
  signing steps most people skip. Default to LLDB locally and GDB inside
  Docker/Linux.
