# gprof

`gprof` is the traditional GNU flat-profile and call-graph tool. It needs the
binary built with `-pg` instrumentation (which inserts counting/timing calls
at every function entry) and produces a `gmon.out` sample file when the
instrumented binary runs. Not part of Apple Clang's toolchain — use the
Docker dev environment.

## Run it

```bash
docker compose -f docker/docker-compose.yml run --rm devtools \
    ./scripts/run_gprof.sh
```

Builds `build-gprof/` (`-DENABLE_GPROF=ON`), runs
`logforge --input logs/10k.log --top-paths 10` to produce `gmon.out`, then
runs `gprof` against it. Output is saved to `results/gprof.log`.

## Run it by hand

```bash
cmake -B build-gprof -DCMAKE_BUILD_TYPE=Release -DENABLE_GPROF=ON
cmake --build build-gprof
./build-gprof/logforge --input logs/1m.log --top-paths 10
gprof ./build-gprof/logforge gmon.out > results/gprof.txt
```

## What to look for

The flat profile ranks functions by self time — for `--top-paths`, expect
`logforge::parse_line`, `Aggregator::add`, and the `unordered_map` hashing it
does internally near the top. The call graph below it shows *who* calls the
hot functions and how often, which is what tells you whether a function is
hot because it's slow per-call or because it's called an enormous number of
times (parsing 1M+ lines, it's almost always the latter).

## Lessons learned

* `-pg` instrumentation has real overhead and changes inlining decisions
  versus a plain `-O2`/`-O3` build — treat gprof's numbers as relative
  (which function dominates) rather than absolute wall-clock truth, and
  cross-check against `perf` or `gprofng`, which sample an unmodified binary.
* gprof only profiles the binary itself, not the C++ standard library
  internals it inlines into — if `parse_line` looks unexpectedly cheap but
  the program is slow, suspect the (inlined) hash map / string allocation
  machinery it calls into rather than the function body in isolation.
