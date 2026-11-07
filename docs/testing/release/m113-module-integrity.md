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

## Strict inspector metadata parsing — 2026-11-06

The inspector rejects duplicate metadata keys, nonblank lines without
an equals sign, and empty or whitespace-only keys. Blank lines remain
supported. Metadata is read explicitly as UTF-8.

A regression demonstrated that conflicting duplicate BUILD_STATE
entries previously allowed the final value to override earlier values.
The parser now raises ValueError instead.

Validation:
- Inspector regression suite: 23 tests passing.
- Module-staging regression suite: 13 tests passing.
- git diff --check: passed.

Tests used disposable fixtures. This change does not resolve metadata
parent-directory symlinks or concurrent modification. The inspector
remains read-only; recovery remains unimplemented.

## Controlled orphan-manifest recovery — 2026-11-06

Implemented a separate explicitly invoked recovery helper.
See docs/release/module-staging-recovery.md for its contract,
validation and limitations.

The helper acquires build then module-parent exclusive locks, rejects
unsafe paths and state, and preserves manifest bytes plus a JSON record
in unique evidence directories. It syncs evidence before removing the
source manifest name. Published module trees are never recovered.

Validation: 14 recovery tests, 23 inspector tests and 13 staging tests
passed. Disposable interrupted-staging recovery and staging retry passed.
No recovery was invoked against the canonical build.

Power-loss behavior, uncooperative-writer races and interrupted rootfs
finalization remain outside the verified recovery scope.

## Interrupted rootfs finalization

Run from the Z890 checkout:

    SABLE_TEST_FINALIZATION=interrupt-after-build-env \
        bash tests/release/run-rootfs-selfcontained.sh

The harness injects SIGKILL into the disposable generator immediately
after publication of metadata/build.env and before preparation of the
final BUILD_STATE marker. It checks for exit status 137 and confirms
that the injection point was reached.

The marker still reads initialized. Both build.env copies match and
report rootfs-generated with KERNEL_MODULES_STAGED=true. The published
modules pass candidate-manifest checksum verification. Inspection and
explicit orphan recovery both exit 1 with a build state mismatch.
Before-and-after build snapshots match.

The default harness run also passed, including final state promotion
and staged module validation. Both runs passed canonical protection
checks.

Retained evidence:
- Interrupted run: /var/tmp/sable-m112-e2e-bLX314NM
- Default run: /var/tmp/sable-m112-e2e-9UeYrkqT

This test covers refusal after process death at one publication boundary.
Resuming finalization and testing power-loss behavior remain open.

## SquashFS preflight after interrupted rootfs finalization

SquashFS generation requires the BUILD_STATE marker and exactly one
BUILD_STATE entry in metadata/build.env to report rootfs-generated.

The disposable interruption test invokes the normal SquashFS entry
point against both mismatch directions. Both invocations exited 1 at
the state gate. The lock path was absent after each refusal, and the
before-and-after build snapshots matched. The harness restored the
original interruption evidence and verified canonical build protection.

Retained evidence: /var/tmp/sable-m112-e2e-7fYdXRBM

This run validates preflight refusal. Positive SquashFS generation
remains to be exercised.
