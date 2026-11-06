# M1.13 — Module Staging Integrity Validation

Date: 2026-11-05
Canonical host: Z890 SableLinux
Branch: development
Baseline commit: 73b14c4

## Objective

Harden the read-only kernel-module transaction inspector
before implementing controlled recovery operations.

## Validation

Module-staging regression suite:
13 tests passing.

Transaction-inspector regression suite:
16 tests passing.

Real release-kernel integrity inspection:
PUBLISHED_VERIFIED

Retained evidence:
/var/tmp/sable-m113-real-inspect-I8UZ2ZiX

## Verified behavior

- Conventional and merged-/usr module layouts
- Rejection of unsafe module-directory symlinks
- Shared nonblocking inspection lock
- Rejection while exclusive staging lock is held
- Abrupt publication interruption detection
- Rejection of unsafe manifest paths
- Detection of duplicate manifest entries
- Detection of inconsistent module metadata hashes
- SHA256 verification of published module files
- Detection of corrupted and missing modules
- Rejection of unexpected published files
- Exact module-file inventory comparison
- Successful inspection of real Z890 release-kernel artifacts

## Boundaries

- Inspector remains read-only.
- PUBLISHED_VERIFIED is an integrity classification,
  not proof of crash-safe publication.
- Inspector does not authorize automatic recovery.
- Filesystem race resistance and additional adversarial
  validation remain future hardening work.
- Controlled recovery and interrupted rootfs-finalization
  tests remain pending.
- Canonical build remains initialized.

## Next Work

1. Further harden transaction inspection and path safety.
2. Implement explicitly authorized, lock-protected recovery.
3. Test interrupted rootfs metadata publication.
4. Revalidate complete isolated rootfs generation.
5. Advance toward canonical rootfs production.

## Traversal-error hardening — 2026-11-06

The inspector now propagates os.walk traversal errors rather than
silently skipping inaccessible directories. The command-line handler
reports ERROR and returns status 1 when such an OSError occurs.

A deterministic regression injects PermissionError for an unexpected
directory containing an unlisted module while all manifest-listed
files remain readable. Before the fix, the expected exception was
not raised. After the fix, the regression passes.

Validation:
- Inspector regression suite: 17 tests passing.
- Module-staging regression suite: 13 tests passing.
- git diff --check: passed.

This change does not resolve filesystem races or establish crash-safe
publication. Recovery remains unimplemented. Tests used disposable
fixtures; canonical build state was not reverified in this checkpoint.

## Build-state consistency — 2026-11-06

The inspector now requires BUILD_STATE to be a regular, nonsymlinked
file whose text agrees with BUILD_STATE in metadata/build.env.
Missing, symlinked, and conflicting state markers are rejected.

A regression first demonstrated that a conflicting marker was ignored.
The noninitialized-build fixture now sets both state records to
rootfs-generated, preserving its original refusal check.

Validation:
- Inspector regression suite: 20 tests passing.
- Module-staging regression suite: 13 tests passing.
- git diff --check: passed.
- Canonical BUILD_STATE and metadata/build.env were read directly;
  both reported initialized, with KERNEL_MODULES_STAGED=false.

Rootfs finalization publishes staged-root metadata, authoritative
build.env, and BUILD_STATE separately. This change detects disagreement
between the two authoritative state records at inspection time; it
does not make publication atomic, synchronize concurrent finalization,
or validate staged-root metadata. Recovery remains unimplemented.

## Rootfs build locking — 2026-11-06

Rootfs generation now acquires a nonblocking exclusive flock on the
existing build directory before reading build metadata. The descriptor
remains open through capture, validation and finalization. Symlinked
build-directory targets are rejected; no lock file is created.

The self-contained harness imports the modified generator into its
disposable Git revision. Inside the isolated mount namespace, a
contention test holds the disposable build lock and requires the
generator's specific lock-refusal message. Before/after inventories
and file hashes confirm no build-content changes during refusal.
Normal generation then succeeds after the test lock is released.

Validation:
- Shell syntax and git diff --check passed.
- Build lock contention refused without build changes.
- Complete isolated rootfs generation passed.
- Candidate mounted read-only; final state and module checks passed.
- Canonical pointer, state, metadata and empty rootfs unchanged.
- SABLE_M112_SELFCONTAINED_E2E_PASS.

Retained evidence:
/var/tmp/sable-m112-e2e-7X91YNq8

The lock coordinates cooperating operations only. Existing standalone
module staging and inspection do not yet acquire this build lock.
Future recovery must acquire the build lock before the module-parent
lock. Recovery and crash-safe finalization remain pending.
