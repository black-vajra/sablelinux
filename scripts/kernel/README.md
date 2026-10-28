# SableLinux Canonical Kernel Build

## Purpose

Establish a reproducible kernel-build pipeline on the canonical
Z890 SableLinux system.

The working Linux 6.16.1 GPU Test 2 installation remains the
protected reference implementation.

## Current implementation

`build-kernel.sh` provides two operations:

    scripts/kernel/build-kernel.sh check
    scripts/kernel/build-kernel.sh prepare

### check

Performs read-only validation of:

- Canonical Z890 hostname and development branch.
- Authenticated Linux 6.16.1 source archive SHA256.
- Version-controlled GPU Test 2 configuration SHA256.
- Canonical workspace layout version.
- Required kernel-build tools.
- Minimum 200 GiB available workspace capacity.

The expected source hash was established through upstream
kernel.org signature verification. The check operation does
not independently repeat signature verification.

### prepare

Requires a clean tracked Git worktree and execution from
the canonical repository script.

Creates a uniquely identified candidate under:

    /srv/sablelinux/kernel-builds/<candidate-id>

Preparation:

- Extracts the authenticated Linux 6.16.1 source archive.
- Preserves the GPU Test 2 baseline configuration.
- Changes the local version to -sable-xattr-test1.
- Enables CONFIG_SQUASHFS_XATTR=y.
- Runs the kernel's olddefconfig target in an isolated
  output directory.
- Verifies the required configuration settings.
- Records Git revision, input hashes, candidate configuration
  hash, and build metadata.
- Records BUILD_STATE=prepared on success.
- Retains failed candidates with BUILD_STATE=failed for
  ordinary errors and handled termination signals.
- Refuses to overwrite an existing candidate directory.

Preparation does not compile or install a kernel.

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
    scripts/kernel/test-prepare.sh

The preflight suite tests valid and invalid inputs.

The preparation suite uses a disposable source archive,
synthetic configuration, temporary Git repository, and
isolated workspace.

Preparation tests cover:

- Successful candidate creation.
- Configuration derivation.
- Provenance metadata and SHA256 verification.
- Candidate-directory collision rejection.
- Preservation of existing candidate contents.
- Kconfig command failure.
- Failure-state recording.

The preparation suite uses a synthetic Makefile. It does
not establish compatibility with real Linux 6.16.1 Kconfig.

## Limitations

The implementation does not yet:

- Compile a kernel or modules.
- Stage compiled kernel artifacts.
- Generate complete kernel-build manifests.
- Perform QEMU boot validation.
- Integrate candidate kernels into release builds.

Passing preparation tests does not establish binary
reproducibility.

## Planned next stages

1. Execute authenticated-source preparation on Z890.
2. Verify actual Linux 6.16.1 Kconfig processing.
3. Implement isolated kernel and module compilation.
4. Generate artifact provenance and SHA256 manifests.
5. Validate through Tier 1 QEMU boot testing.
6. Integrate validated artifacts into the release pipeline.

## Safety

Do not overwrite the running GPU Test 2 kernel.

Do not install candidate modules into the host system.

Do not modify the bootloader during kernel-build development.

Only the canonical Z890 system produces authoritative
SableLinux release artifacts.
