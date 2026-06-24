# osv-dep-scanner-cli

[![CI](https://github.com/czhao-dev/systems-dev-tools/actions/workflows/ci.yml/badge.svg)](https://github.com/czhao-dev/systems-dev-tools/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](../LICENSE)
[![Ruby](https://img.shields.io/badge/Ruby-3.1%2B-CC342D)](lib/osv_dep_scanner.rb)

A Ruby CLI that scans a directory for dependency manifests/lockfiles, queries the [OSV.dev](https://osv.dev) vulnerability database, and reports known vulnerabilities as text, Markdown, or JSON — with an exit code suitable for CI gating.

## Overview

osv-dep-scanner-cli answers one question: does this project pull in any dependency with a known published vulnerability, and how bad is it? It's built entirely on Ruby's standard library — `net/http`, `json`, `optparse`, `find` — with zero runtime gem dependencies, in the same "dependency-light" spirit as this monorepo's [linux-sys-report-cli](../linux-sys-report-cli).

## Supported ecosystems

| Ecosystem | File parsed | Notes |
|---|---|---|
| npm | `package-lock.json` | Only lockfile **v2/v3** (the `"packages"` map). v1's nested `dependencies` tree is rejected with a parse error. |
| PyPI | `requirements.txt` | Only lines pinned with `==`. Ranges (`>=`, `~=`), unpinned names, extras (`pkg[extra]==1.0`), and `-r`/`-e`/`--hash` options are skipped. |
| Cargo | `Cargo.lock` | `[[package]]` blocks, parsed with a small hand-rolled line parser (no TOML library needed — Cargo.lock never nests tables or uses multiline strings). |
| Go | `go.mod` | `require` lines, both single-line and block (`require (...)`) form. `replace`/`exclude` directives are ignored. |

**Not supported** (so the tool doesn't overclaim coverage): Perl/CPAN (OSV doesn't track it), `Pipfile.lock`/`poetry.lock`, bare `package.json` without a lockfile, `Cargo.toml` version ranges.

## Quick Start

```bash
cd osv-dep-scanner-cli
bundle install
./bin/osv-dep-scanner --path examples --format markdown
```

`examples/` bundles a small fixture set across all four ecosystems, including `lodash@4.17.15` (several real, published CVEs) so a fresh checkout has something to find immediately. Sample runs are checked in at [`examples/sample-report.txt`](examples/sample-report.txt), [`examples/sample-report.md`](examples/sample-report.md), and [`examples/sample-report.json`](examples/sample-report.json).

## Usage

```
osv-dep-scanner [options]
```

| Option | Description |
|---|---|
| `--path PATH` | Directory to scan (default `.`) |
| `--ecosystems LIST` | Comma-separated subset: `npm,pypi,cargo,gomod` (default: all) |
| `--format text\|markdown\|json` | Output format (default `text`) |
| `--output PATH` | Write the report to a file instead of stdout |
| `--fail-on none\|low\|medium\|high\|critical` | Minimum severity that fails the run (default `low`) |
| `--timeout SECONDS` | Overall scan timeout (default `60`) |
| `--osv-base-url URL` | Override the OSV API base URL |
| `--version` / `--help` | |

### Exit codes

| Code | Meaning |
|---|---|
| 0 | Clean — no vulnerabilities at/above `--fail-on` |
| 1 | Worst finding is LOW (or severity couldn't be determined) |
| 2 | Worst finding is MEDIUM |
| 3 | Worst finding is HIGH |
| 4 | Worst finding is CRITICAL |
| 5 | Scan error: no supported manifests found, a manifest failed to parse, or the OSV API errored |
| 64 | CLI usage error (bad flags) |

A scan error (code 5) always takes precedence over a severity code, even if some manifests were scanned successfully — "the scan might be incomplete" is treated as the most important signal to surface, ahead of any specific finding.

## How it works

1. **Discover** — walk `--path`, skip noise directories (`.git`, `node_modules`, `vendor`, `target`, `dist`, `build`, `.bundle`), and parse every recognized manifest into `{ecosystem, name, version}` triples.
2. **Query** — `POST /v1/querybatch` to OSV.dev with all dependencies at once; this returns only vulnerability IDs, never details.
3. **Hydrate** — `GET /v1/vulns/{id}` for each *unique* vulnerability ID (deduplicated, fetched concurrently) to get the summary, severity fields, and references.
4. **Aggregate** — one `Finding` per unique vulnerability ID, even if it affects several manifest entries.
5. **Derive severity** — OSV has no single guaranteed severity field. Precedence: `database_specific.severity` string → `affected[].ecosystem_specific.severity` string (highest, if several) → if only a CVSS vector is present, treat as `medium` (see Limitations) → otherwise `unknown`.

The OSV client is duck-typed (`#query_batch` / `#get_vuln`) so orchestration tests inject a fake with no HTTP involved at all; the client's own tests spin up a local `WEBrick` server.

## Project Structure

- `bin/osv-dep-scanner` — entrypoint
- `lib/osv_dep_scanner/manifest/` — `npm.rb`, `pypi.rb`, `cargo.rb`, `gomod.rb` parsers, tied together by `manifest.rb`'s discovery
- `lib/osv_dep_scanner/osv/` — `client.rb` (HTTP), `severity.rb` (derivation)
- `lib/osv_dep_scanner/scan.rb`, `aggregate.rb` — orchestration and finding/report model
- `lib/osv_dep_scanner/report/` — `text.rb`, `markdown.rb`, `json.rb` formatters
- `lib/osv_dep_scanner/cli.rb` — flag parsing and exit-code mapping
- `test/` — Minitest suite, mirrored package-by-package, with fixtures under `test/fixtures/`
- `examples/` — bundled multi-ecosystem fixture set used for the quick start and the CI smoke test

## Testing & Quality

- **Minitest** (bundled with Ruby, like this monorepo's [git-commit-report-generator](../git-commit-report-generator) uses core `Test::More`) — 52 tests across parsers, severity derivation, the HTTP client, scan orchestration, report formatters, and CLI option parsing/exit codes.
- **Zero network calls in `rake test`** — the OSV client's own tests run against a local `WEBrick` server with canned responses; orchestration tests inject a hand-written fake client.
- **RuboCop**, configured via `.rubocop.yml`.
- **CI** runs RuboCop, `rake test`, then exercises the real binary against `examples/` in all three formats — the JSON smoke step makes the one live call to OSV.dev in the whole suite and asserts the known lodash CVE is found (allowed to fail independently of the rest of CI on an OSV.dev outage).

Run locally:

```bash
bundle exec rubocop
bundle exec rake test
```

## Limitations

- No real CVSS vector scoring — a vulnerability with only a CVSS vector and no GHSA-style severity string is bucketed as `medium` rather than computed precisely. This is a known simplification, not a bug.
- No transitive dependency resolution beyond what's already encoded in the lockfile.
- OSV.dev coverage can lag very recent disclosures.
- No private registry or authenticated-feed support.
- See the ecosystem table above for unsupported manifest variants.

## License

This project is licensed under the MIT License. See the [top-level LICENSE](../LICENSE).
