# Kernel Candidate Verification

## Purpose

Verify isolated kernel-build artifacts before they are accepted
as inputs to the SableLinux release pipeline.

The canonical build authority is the Z890 SableLinux system.

## Implementation

Verifier:

scripts/release/verify-kernel-candidate.py

Regression tests:

tests/release/test_verify_kernel_candidate.py
tests/release/test_kernel_candidate_tree.py

## Validated candidate

Candidate ID:

20261028T212705Z-622d439-linux-6.16.1-xattr-test1

Kernel release:

6.16.1-sable-xattr-test1

Kernel preparation commit:

622d43977f97b6142462055c031defef31a0f868

Compilation commit:

bb2592ce2354126787598cc00d8cd7749ec4f003

## Validation

The verifier currently checks:

- Candidate identity and built state
- Canonical build-host metadata
- Kernel release identification
- Three kernel artifact SHA256 entries
- Nonempty, dynamically sized module manifest
- SHA256 integrity of listed module files and indexes
- Complete regular-file coverage of the module tree
- Expected kernel build-directory symlink
- Rejection of unexpected module-tree symlinks

The kernel build-directory symlink is a development artifact.
Its absolute Z890 path must not be imported unchanged into
a release rootfs.

## Test results

2026-10-29:

- Permanent regression tests: 12 PASS
- Canonical kernel artifacts: 3 verified
- Canonical module files: 57 verified
- Candidate verification: PASS

## Known limitations

The verifier is not yet a complete release-security gate.

Future work includes:

- Directory-component symlink and filesystem-boundary checks
- Unmanifested kernel artifact rejection
- Additional build-metadata consistency checks
- Verification of all relevant kernel input manifests
- Explicit handling of development-only module symlinks
- Validation of kernel artifacts after release staging
- Integration with release-build initialization

The current implementation does not install kernels, change
host modules, modify GRUB, or produce release artifacts.
