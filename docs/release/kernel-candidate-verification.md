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

## Release-build preflight integration

The canonical release initializer supports:

    --kernel-candidate CANDIDATE_ID
    --verify-candidate-only

Verification-only mode invokes the kernel-candidate verifier
without creating a release-build directory.

A valid candidate must pass SHA256 verification of its kernel
artifacts and module manifest before preflight succeeds.

The following cases have been tested on Z890:

- Valid kernel candidate: PASS
- Invalid kernel candidate: rejected
- Candidate release creation before staging support: blocked
- Argument handling: five regression tests PASS

The release initializer continues to use the running host kernel
for its existing build-creation path.

Candidate-based release creation remains deliberately disabled
until kernel-artifact staging is implemented.

The verification-only interface does not replace the complete
canonical release-build safeguards.

Regression tests:

    tests/release/test_create_build_preflight.py

The running Z890 kernel and GRUB are unaffected.

## Candidate selection in release initialization

The release initializer now distinguishes:

- HOST_KERNEL_RELEASE: kernel currently running on Z890
- KERNEL_RELEASE: kernel selected for release generation

When a kernel candidate is supplied, the initializer verifies
the candidate and reads its release identifier from the
candidate's compilation metadata.

Kernel preparation and compilation commits are also retrieved
for future release provenance.

Candidate-based release creation remains explicitly blocked
until artifact staging is integrated.

The repository cleanliness gate is enforced before candidate
selection. This prevents testing uncommitted release code
through the production initialization path.

Validation:

- Release regression tests: 24 PASS
- Bash syntax: PASS
- Repository cleanliness rejection: PASS

No release build was created during this validation.

## Release initialization state publication

Release initialization uses two states:

- initializing: build directory creation and input verification are underway.
- initialized: required initialization work has completed.

The BUILD_STATE file is the authoritative completion marker.

During initialization, BUILD_STATE and metadata/build.env initially record
the initializing state.

After kernel input verification, metadata generation, and permission handling
complete, metadata/build.env is updated first. BUILD_STATE is then updated
to initialized, followed by publication of state/current-build-id.

A failed initialization must not be treated as a completed build merely
because its directory exists.

The current implementation does not yet provide fully atomic publication
or automated recovery from interruption. These remain release-engineering
requirements.

Regression coverage verifies source ordering and preservation of the
candidate release-creation safety gate. It does not yet simulate
initialization failures.

Validation: 29 release regression tests passed.
