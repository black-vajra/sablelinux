# Linux 6.16.1 SableLinux XATTR Test 1 — Build Procedure

## Authority

Canonical build host: Z890 SableLinux.
Repository branch: development.
Repository location: /home/pepper/sablelinux.

The installed GPU Test 2 kernel must remain untouched.

## Candidate

Candidate ID:

20261028T212705Z-622d439-linux-6.16.1-xattr-test1

Canonical candidate location:

/srv/sablelinux/kernel-builds/20261028T212705Z-622d439-linux-6.16.1-xattr-test1

Expected kernel release:

6.16.1-sable-xattr-test1

Preparation commit:

622d43977f97b6142462055c031defef31a0f868

## Verified inputs

Upstream source: /sources/linux-6.16.1.tar.xz

Upstream archive SHA256:

ea43491bc7ace1e414b3b2d957f8cf96e7049155123f0acce798accf8da1acba

Baseline configuration:

docs/release-validation/gpu-test2-2026-10-08/kernel.config

Only two configuration changes are intended:

- CONFIG_LOCALVERSION="-sable-xattr-test1"
- CONFIG_SQUASHFS_XATTR=y

The source-integrity verifier successfully compared 89,684
regular source files against the authenticated archive.

## Commands

Read-only candidate validation:

scripts/kernel/build-kernel.sh build \
  20261028T212705Z-622d439-linux-6.16.1-xattr-test1

Compilation command (not yet executed):

scripts/kernel/build-kernel.sh compile \
  20261028T212705Z-622d439-linux-6.16.1-xattr-test1

Compilation uses eight parallel jobs and an isolated output
directory.

Module installation must use INSTALL_MOD_PATH pointing to the
candidate's modules directory.

No host modules_install or GRUB modification is permitted.

## Expected output locations

- obj/: compiled objects and kernel image
- modules/: isolated kernel module staging
- artifacts/: kernel image, System.map, configuration
- metadata/: checksums and compilation metadata
- logs/: compilation and module-install logs

## Candidate states

- prepared: candidate validated and ready for compilation
- building: compilation in progress
- built: compilation and artifact validation succeeded
- build-failed: compilation or artifact generation failed
- build-interrupted: interrupted compilation

Failed or interrupted candidates must be retained for analysis.
They must not be automatically overwritten or retried.

## Validation status

2026-10-28:

- Authenticated source verification: PASS
- Kernel preflight regressions: PASS
- Preparation regression tests: PASS
- Source-integrity regression tests: PASS
- Directory-locking behavior: PASS
- Invalid compilation requests: rejected
- Production compilation: NOT RUN
- QEMU boot validation: NOT RUN
- Hardware deployment: NOT RUN

The compilation success, failure-state, and complete module-staging
paths remain unverified until further testing.

This candidate is an engineering test, not a release artifact.
