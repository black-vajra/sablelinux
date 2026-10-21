# SquashFS metadata preflight

## Problem and behavior

The rsync fixture verifies staging preservation, not the subsequent image path.
Canonical fixtures found dropped POSIX ACLs at mksquashfs 4.6.1 generation and
invisible mounted xattrs with GPU Test 2's SQUASHFS_XATTR disabled.

build-squashfs.sh now calls check-squashfs-metadata.py before invoking mksquashfs.
The helper inventories all entries, including root-directory and symlink xattrs,
without following symlinks. It requires root and rejects symlinked root paths,
mounted subtrees, filesystem boundaries, unreadable metadata, missing selected
kernel configuration and existing report paths. It does not modify the root.

Only user.* and security.* attribute namespaces qualified by the canonical
fixture are admitted. Other namespaces, including POSIX ACLs and trusted.*, stop
the build pending an explicit preservation design or qualification. This is a
conservative policy, not a claim that every rejected namespace is unsupported
by the image format. A payload containing any attributes additionally requires
CONFIG_SQUASHFS_XATTR=y in /boot/config-KERNEL_RELEASE, using KERNEL_RELEASE from
the build's provenance. A tree with no attributes can pass without that option.

Failure prevents image generation and state promotion. A JSON report records
bytes in hexadecimal, counts, completion and decision. Report paths are outside
the payload and must not already exist. Successful image metadata records hashes
of the helper, report and selected kernel configuration.

## Validation

Run on canonical Z890 from the repository:

    sudo python3 scripts/live/test-squashfs-metadata.py

This uses real user xattrs, file capabilities, access/default ACLs and an external
symlink fixture. Negative cases include absent kernel support, absent selected
configuration, read failure and nested mount. It uses only fresh temporary files;
it neither invokes the full builder nor mounts or modifies release inputs.

Review environments lacking CAP_SETFCAP can run --simulate-capability; this also
uses UID 0 for named ACL entries to accommodate a one-UID mapping. Such a run is
explicitly not canonical real-capability acceptance. Reviewer execution passed
that mode plus bash syntax validation. Default canonical execution has no fallback.

## Evidence and limits

staged-root-inventory.txt is the reviewed October 21 inventory of the historical
July 17 rootfs, not a refreshed release payload. Its original SHA256 is:
8ce7f187646612c8c97f5ca5095e4379cf97b2df1b93a6142acef313ea9411ce

This preflight prevents known loss conditions; it does not establish actual
image storage, kernel exposure, ACL enforcement or capability execution for a
candidate. A kernel candidate, metadata round-trip/overlay regression tests and
an ACL solution remain open. The root must be quiescent while scanned and built;
this helper does not provide snapshotting or a release input freeze.

Fresh build initialization remains deferred until the documented audits and
input freeze. Preserve July artifacts, GPU Test 2 and the running AI stack.

## Canonical validation — 2026-10-21

The default regression suite passed on Z890, including real file capabilities,
access/default ACL rejection and all reported negative cases. See
canonical-gate-tests.txt. This supersedes the pending canonical-test status
in the preparation notes. The full builder was not executed.
