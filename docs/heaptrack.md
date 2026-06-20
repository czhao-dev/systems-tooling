# heaptrack

`heaptrack` records every allocation and deallocation with call stacks and
then lets you analyze allocation *count* and *volume* hot spots after the
fact — complementary to Massif's "peak usage at a point in time" view.
Linux-only; use the Docker dev environment.

## Run it

```bash
docker compose -f docker/docker-compose.yml run --rm devtools \
    ./scripts/run_heaptrack.sh
```

Runs `heaptrack ./build/logforge --input logs/10k.log --top-paths 10` from
inside `results/`, then runs `heaptrack --analyze` against the resulting
`.gz` trace. Output is saved to `results/heaptrack.log`.

## Run it by hand

```bash
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build
cd results
heaptrack ../build/logforge --input ../logs/1m.log --top-paths 10
heaptrack --analyze heaptrack.logforge.*.gz
```

## What to look for

For `--top-paths`, the allocation-heavy work is per-line parsing: each parsed
`LogRecord` owns four `std::string` fields (`timestamp`, `ip`, `method`,
`path`), each a separate small heap allocation unless it fits in the
implementation's SSO buffer. `heaptrack --analyze`'s "most allocations"
ranking should point straight at `LogRecord` construction inside
`logforge::parse_line`/`Aggregator::add` as the dominant allocation site —
this is the allocation cost the README's `string_view`-parser comparison is
about: a `string_view`-based parser that only materializes `std::string`s for
fields actually kept around would cut this dramatically.

## Lessons learned

* heaptrack's GUI (`heaptrack_gui`, not installed in this Docker image) is
  much easier to read than the text `--analyze` output once allocation
  counts run into the millions; the text mode here is enough to identify the
  top call stack but not to explore interactively.
* Allocation *count* and allocation *volume* are different rankings — a
  site doing a few huge allocations and a site doing millions of tiny ones
  can both show up as "expensive" depending on which ranking you read; check
  both before deciding what to optimize.
