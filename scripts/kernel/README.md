# SableLinux Canonical Kernel Build

## Purpose

Establish a reproducible kernel-build pipeline on the canonical
Z890 SableLinux system.

The working Linux 6.16.1 GPU Test 2 installation remains the
protected reference implementation.

## Current implementation

`build-kernel.sh` currently implements only:

    scripts/kernel/build-kernel.sh check

The check operation verifies:

- Canonical Z890 hostname.
- SableLinux development branch.
- Authenticated Linux 6.16.1 source archive SHA256.
- Version-controlled GPU Test 2 configuration SHA256.
- Canonical workspace layout version.
- Required kernel-build tools.
- Minimum 200 GiB available workspace capacity.

The source archive's expected SHA256 was established through
earlier upstream kernel.org signature verification.

The check operation does not independently repeat that
signature verification.

## Verified inputs

Source archive:

    /sources/linux-6.16.1.tar.xz

SHA256:

    ea43491bc7ace1e414b3b2d957f8cf96e7049155123f0acce798accf8da1acba

Configuration:

    docs/release-validation/gpu-test2-2026-10-08/kernel.config

SHA256:

    1271404d28cc2eb66f9cf2222c4b2f7406cff4a85f57c3ba4ced8d1d45d22fd5

## Regression tests

Run:

    scripts/kernel/test-build-kernel.sh

Tests cover successful preflight, invalid command handling,
missing source input, incorrect source hash, and explicit
failure-message verification.

Negative tests modify disposable script copies, not canonical
source archives or configuration files.

## Limitations

This implementation does not yet:

- Extract kernel sources.
- Generate a kernel candidate configuration.
- Compile a kernel or modules.
- Stage kernel artifacts.
- Generate kernel-build manifests.
- Perform QEMU validation.
- Integrate kernel artifacts into release builds.

Passing preflight does not establish binary reproducibility.

## Planned next stages

1. Document isolated kernel-build workspace allocation.
2. Implement authenticated source extraction.
3. Derive a versioned kernel configuration from GPU Test 2.
4. Enable SquashFS XATTR in an isolated candidate.
5. Build kernel and modules without installing them.
6. Generate provenance metadata and SHA256 manifests.
7. Validate the candidate through Tier 1 QEMU boot testing.
8. Integrate validated artifacts into the release pipeline.

## Safety

Do not overwrite the running GPU Test 2 kernel.

Do not install candidate modules into the host system.

Do not modify the bootloader during kernel-build development.

Only the canonical Z890 system produces authoritative
SableLinux release artifacts.
