# ripgrep 15.2.0 — canonical source installation

Installed on canonical Z890 from the upstream 15.2.0 tag.
Executable: `/usr/local/bin/rg`.
Retained source and build log:
`/home/pepper/src/ripgrep-15.2.0-build.B6V3cL`.

## Build and validation

- Built as pepper with `cargo build --release --locked`.
- `cargo test --release --locked` completed successfully.
- Final reported test group: 332 passed, zero failed.
- Literal-search smoke test passed.
- Installed with `sudo install -Dm755`.
- Installed executable matched the built executable using `cmp`.
- Default features; optional PCRE2 support was not enabled.

This records a host-tool installation, not an ISO acceptance result.

## Recorded source, toolchain and binary provenance

```text
BUILD_TIME=2026-11-07T23:57:25Z
SOURCE_URL=https://github.com/BurntSushi/ripgrep.git
SOURCE_TAG=15.2.0
e89fff89ac9af12e8d4ce9d5fd07beb408ca730f
rustc 1.99.0 (b940084d7 2026-09-28)
cargo 1.99.0 (5f94df478 2026-08-27)
7a7d39cda8a03930e578f1dbb724e055771901842eca239e03b01e19da946a64  Cargo.lock
510a1212ea2643d3a2909cc24b49837e13a9ba1b63a889747ab2ff12c4151ace  target/release/rg
```

## Installed version

```text
ripgrep 15.2.0 (rev e89fff89ac)

features:-pcre2
simd(compile):+SSE2,-SSSE3,-AVX2
simd(runtime):+SSE2,+SSSE3,+AVX2

PCRE2 is not available in this build of ripgrep.
```
