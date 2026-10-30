# Kernel Artifact Staging

## Purpose

Stage verified kernel artifacts from an isolated canonical
kernel build into a release-owned directory.

The canonical build authority is the Z890 SableLinux system.

## Implementation

scripts/release/stage-kernel-artifacts.py

## Input

The helper accepts:

- --candidate-id CANDIDATE_ID
- --destination DESTINATION
- --workspace WORKSPACE (optional)

The destination's parent must exist.

The destination itself must not exist.

The selected kernel candidate must pass:

scripts/release/verify-kernel-candidate.py

## Output

The published directory contains:

- vmlinuz-KERNEL_RELEASE
- System.map-KERNEL_RELEASE
- config-KERNEL_RELEASE
- kernel-artifacts.sha256

All three staged artifacts are SHA256-verified.

## Publication behavior

The helper builds the output in a temporary sibling directory.

After copying and verifying the artifacts, it publishes
the completed directory using a filesystem rename.

An advisory lock on the destination's parent directory
serializes cooperating staging processes.

Existing destinations are rejected.

Temporary directories are cleaned after normal success
or handled failures.

## Validation evidence

Canonical candidate:

20261028T212705Z-622d439-linux-6.16.1-xattr-test1

Kernel release:

6.16.1-sable-xattr-test1

Successful staging evidence:

/srv/sablelinux/testing/kernel-atomic-ILs0VTe5

Validated behavior:

- Candidate verification: PASS
- Three staged artifact hashes: PASS
- Existing destination rejection: PASS
- Invalid candidate rejection: PASS
- Invalid destination rejection: PASS
- Temporary directory cleanup: PASS
- Cooperative lock contention rejection: PASS

Permanent tests:

tests/release/test_stage_kernel_artifacts.py

Full release regression suite: 24 tests PASS.

## Known limitations

- Atomic rename does not guarantee crash durability.
- The advisory lock coordinates cooperating processes only.
- Publication is not yet protected by a no-replace rename.
- Kernel modules are not staged by this helper.
- Release-build initialization does not yet invoke this helper.
- Additional artifact provenance metadata is required.
- Canonical candidate testing is currently tied to an
  existing Z890 test fixture and may skip elsewhere.

The helper must not install kernels, modify host modules,
alter GRUB, or overwrite existing release artifacts.
