# Packaging

This project uses CPack to generate distributable packages from a release
build. This document covers packaging specifically; see the root
[README.md](../README.md) for the rest of the build system.

## Supported formats

| Format | Platforms        | Status                  |
| ------ | ---------------- | ------------------------ |
| TGZ    | all               | always enabled            |
| ZIP    | all               | always enabled            |
| DEB    | Linux             | enabled only when `CMAKE_SYSTEM_NAME` is `Linux` |
| RPM    | Linux             | not enabled (possible to add via `CPACK_GENERATOR`) |

## Generating a package locally

```bash
cmake --preset release
cmake --build --preset release
cpack --config build/release/CPackConfig.cmake
```

This produces `buildlab-<version>-<system>.tar.gz` and `.zip` archives in
the repository root.

## Package contents

The package mirrors the install layout documented in the root README:

```text
buildlab-<version>-<system>/
├── bin/
│   └── buildlab-cli
├── include/
│   └── buildlab/
├── lib/
│   ├── libbuildlab_core.a
│   └── libbuildlab_net.a
└── lib/cmake/buildlab/
    ├── buildlabConfig.cmake
    ├── buildlabConfigVersion.cmake
    └── buildlabTargets.cmake
```

## Verifying a package without installing it

```bash
tar tzf buildlab-0.1.0-Darwin.tar.gz
```

## CI

CI does not currently run `cpack` -- packaging is exercised locally only.
The GitHub Actions matrix focuses on build/test/static-analysis/coverage;
see `.github/workflows/ci.yml`.
