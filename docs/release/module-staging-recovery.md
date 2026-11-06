# Module staging recovery

Status: implemented and validated with disposable fixtures.
Canonical recovery has not been performed.

Helper: scripts/release/recover-module-staging.py
Tests: python3 -B scripts/release/test-recover-module-staging.py

## First supported operation

A separate recovery helper requires --build-root and the explicit action
--quarantine-orphan-manifest. It never runs automatically during staging.

## Preconditions and locking

1. Validate the build path and reject symlinked directory components.
2. Acquire a nonblocking exclusive lock on the existing build directory.
3. Read strict build metadata and BUILD_STATE while holding that lock.
4. Require both state records to be initialized and modules unstaged.
5. Validate the conventional or merged-/usr module-parent path.
6. Acquire its nonblocking exclusive lock after the build lock.
7. Recheck that the selected-release tree is absent using lstat semantics.
   Any existing object, including a dangling symlink, requires refusal.
8. Require the orphan manifest to be a regular nonsymlinked file.

## Evidence preservation

Create a uniquely named evidence directory under build metadata.
Preserve the manifest there without overwriting existing evidence.
Record build identity, kernel release, source path and manifest SHA256.
Make evidence durable before removing the original manifest name.
A failure must leave the original or preserved evidence available.

Do not delete module-staging or manifest temporary directories.
Do not modify build.env, BUILD_STATE, candidate artifacts or rootfs.
Do not attempt to recover an existing published module tree.

## Required disposable tests

Explicit action required; successful quarantine; successful staging retry;
refusal for an existing tree or dangling symlink; refusal for either lock;
invalid or conflicting metadata; unsafe directory paths; invalid manifest
object; interruption during evidence preservation; evidence retained on retry.

## Boundaries

Locks coordinate cooperating programs. Directory replacement races and
power-loss durability require explicit implementation review and testing.
This operation does not resume interrupted rootfs finalization.

## Verified validation — 2026-11-06

14 recovery tests passed, including:
- Explicit action required and successful evidence preservation.
- Refusal for existing trees, dangling tree symlinks and either held lock.
- Conflicting or invalid metadata and unsafe manifest objects.
- Symlinked metadata and module-parent directory rejection.
- Conventional and merged-/usr layout support.
- Evidence sync failure preserves the source manifest.
- Failure before source removal preserves evidence; retry retains it.
- Abrupt staging exit, quarantine and successful staging retry.
- Temporary staging remnants and build-state metadata preserved.

Companion regression suites passed: 23 inspector tests and 13 staging tests.
git diff --check passed.

The staging-retry test uses the existing fixture-only candidate verifier.
Injected failures test process-level error handling, not power loss.
Directory descriptors anchor filesystem access, but advisory locks cannot
prevent uncooperative writers from changing directory entries. A final
source identity/content check narrows races; it does not eliminate the
check-to-unlink window. Recovery requires an operationally quiescent build.
