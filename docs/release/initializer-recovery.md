# SableLinux initializer recovery and publication policy

Status: Operational policy
Authority: Canonical Z890 SableLinux build host
Scope: Release build initialization and candidate publication

## 1. Build selection semantics

`/srv/sablelinux/state/current-build-id` identifies the selected
initialized build workspace.

It does not identify a validated release or establish that an ISO,
installer, live root, or bootable image has passed release testing.

Release validation and promotion require separate evidence and
an independently defined release-selection mechanism.

## 2. Creation locking

The initializer acquires:

`/srv/sablelinux/state/locks/create-build.lock`

using atomic directory creation.

The directory prevents concurrent initializer instances that
follow the same locking protocol.

The initializer normally removes this directory through its
EXIT trap.

SIGKILL, a system crash, or sudden power loss can prevent cleanup.

An existing lock must be treated as active or potentially stale.
Never automatically remove it based solely on age.

## 3. Stale-lock investigation

All recovery operations must take place on canonical Z890.

Before attempting recovery:

1. Stop initiating new release-build operations.
2. Record the current Git commit and repository state.
3. Record the selected build ID and its pointer checksum.
4. Inspect the lock directory without modifying it.
5. Investigate active initializer, staging, verification, and
   publisher processes, including their child processes.
6. Check for relevant outstanding jobs or automation.
7. Investigate the associated build directories and logs.
8. Establish exclusive operator control of release operations.

A PID search alone is insufficient proof that no operation is active.

If process ownership or activity remains uncertain, leave the
lock in place and investigate further.

Only after confirming that no relevant operation remains active
and that competing starts are prevented may an operator manually
remove the stale lock with `rmdir`.

Never use recursive deletion for lock recovery.

Record the evidence and decision in the build incident log.

## 4. Publication ordering

The candidate publisher:

1. Acquires an exclusive advisory lock on the state directory.
2. Validates build identity, staged kernel artifacts, and provenance.
3. Atomically replaces the build metadata file.
4. Atomically replaces the BUILD_STATE completion marker.
5. Atomically replaces the current-build pointer.

These are individually atomic replacements, not one transaction.

Publication failure can leave a build initialized but unselected.

The publisher's state-directory flock is separate from the
initializer's creation-directory lock.

## 5. State classification

Use `scripts/release/inspect-build-publication.py` to inspect
an individual build.

Recognized classifications:

- initializing: initialization not completed
- interrupted: metadata and completion marker disagree
- initialized-unselected: initialized, not currently selected
- initialized-selected: initialized and currently selected

Classification is diagnostic evidence, not certification of
artifact integrity or release readiness.

Do not automatically select, delete, or retry an interrupted build.

Preserve diagnostic evidence and investigate the exact failure
boundary before deciding whether to retry or create a new build.

## 6. Production pointer preservation

Before recovery or activation, record:

- Current pointer contents
- Current pointer SHA256
- Owner, group, and permissions
- Current repository commit
- Relevant build and publication logs

Do not manually rewrite the current-build pointer as part of
routine stale-lock recovery.

Any necessary pointer repair requires a separately reviewed,
documented recovery operation.

## 7. Crash consistency

The publisher fsyncs temporary file contents before replacement.

It does not currently explicitly fsync the containing directories
after each replacement.

Therefore successful software-failure tests do not establish
complete power-loss durability.

Arbitrary crash recovery and directory durability remain separate
release-hardening requirements.

## 8. Validation requirements

Before enabling production candidate initialization:

- Repository regression suite passes.
- Isolated positive-path initializer test passes.
- Negative-path initialization matrix passes.
- Canonical filesystem and identity preflight passes.
- Production creation lock is absent.
- Existing pointer and canonical build directories are recorded.
- The intended kernel candidate independently verifies.
- The operator understands that initialization does not generate
  a live root, deploy kernel modules, or qualify a release.

The candidate safety gate must not be removed solely because
this document exists.
