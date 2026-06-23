# Static Analysis: clang-tidy and cppcheck

Two complementary static analyzers: **clang-tidy** uses Clang's own AST and
the project's `compile_commands.json`, so it understands templates and
overload resolution exactly like the real compiler and can suggest
modernizations; **cppcheck** uses its own lightweight parser, runs without a
full build, and is good at flagging suspicious-but-not-wrong patterns
(unused functions, always-true conditions) that aren't really "lints" in the
clang-tidy sense.

## clang-tidy

```bash
./scripts/run_clang_tidy.sh
```

Configures `build/` with `CMAKE_EXPORT_COMPILE_COMMANDS=ON` (already the
default in this project's `CMakeLists.txt`) and runs
`clang-tidy src/*.cpp -p build`, which picks up the exact include paths and
flags CMake used. Output is saved to `results/clang_tidy.log`.

Not installed via Homebrew on this machine (`clang-tidy not found`) — run it
inside the Docker dev environment, which has it.

Example checks worth paying attention to in this codebase:

```text
modernize-use-nullptr
modernize-use-override
performance-for-range-copy
performance-unnecessary-value-param
bugprone-use-after-move
```

`performance-unnecessary-value-param` in particular is the kind of thing
worth fixing on sight here — every `add(const LogRecord& record)`-style
function in `Aggregator`/`ReportWriter` is already reference-based, so a
clean clang-tidy run is good confirmation that pattern stayed consistent as
the codebase grew.

## cppcheck

```bash
./scripts/run_cppcheck.sh
```

Runs `cppcheck --enable=all --inconclusive --std=c++17 -Iinclude src/`.
Output is saved to `results/cppcheck.log`. This one *does* run locally
(installed via Homebrew). Real captured output against this project's actual
`src/`:

```text
Checking src/Aggregator.cpp ...
include/Aggregator.h:23:19: style: The function 'error_count' is never used. [unusedFunction]
    std::uint64_t error_count() const { return error_count_; }
```

This is a real, if minor, finding: `Aggregator::error_count()` is part of the
public API but `main.cpp` never calls it directly (errors are surfaced via
`--errors-only`'s record listing, not a count). It's a deliberate API
completeness choice here, not a bug — a good example of cppcheck's
`unusedFunction` check flagging something that needs a human judgment call
rather than an automatic fix. The rest of the output is `missingIncludeSystem`
informational noise (cppcheck not finding `<vector>` etc. on its internal
search path); pass `--check-config` or a `--suppress` list if you want to
quiet that in CI.

## Lessons learned

* clang-tidy needs a real build (`compile_commands.json`); cppcheck doesn't —
  reach for cppcheck first if you just want a fast sanity pass, and run
  clang-tidy when you actually want template-aware/modernization feedback.
* Don't auto-apply every `unusedFunction`/`unusedVariable` finding without
  reading it: `error_count()` above is intentionally-unused-by-`main`, not
  dead code to delete.
