# Canonical image metadata fixture — 2026-10-21

Host: Z890; kernel: 6.16.1-sable-gpu-test2.
Repository checkpoint tested: 9dc2d17.
Tools identified in preceding audit: squashfs-tools 4.6.1.

A disposable fixture used zstd compression and 1 MiB blocks.
This was a component test, not a complete release-image or installer test.

## Direct extraction

Contents, modes, numeric ownership, symlink target, hardlink identity,
user.sable_test and security.capability matched after direct extraction.

mksquashfs reported unrecognised system.posix_acl_access and
system.posix_acl_default prefixes. Both ACLs were absent after extraction.
The fixture metadata comparison therefore FAILED.

## Mounted image and overlay

The running configuration disables CONFIG_SQUASHFS_XATTR.
CONFIG_FS_POSIX_ACL, CONFIG_TMPFS_POSIX_ACL and CONFIG_TMPFS_XATTR are enabled.

The mounted image exposed none of the tested xattrs. The overlay likewise
exposed none before copy-up. Adding user.sable_copyup triggered copy-up of
the xattr fixture file; the new attribute appeared in the overlay and upper
file, while the original user.sable_test remained absent.

Only that file was copied up. Missing upper entries for the capability and
ACL fixtures are expected, not additional failures. All mounts were unmounted.

Mounts used a private namespace and restrictive SquashFS mount options.
No capability execution or ACL enforcement test was performed.

## Follow-up

Inventory metadata requirements in the staged release root.
Qualify SquashFS xattr support in a separate kernel candidate.
Design and validate explicit ACL preservation for live and installed roots.
Do not assume enabling SquashFS xattrs alone resolves ACL preservation.

Full boot, full installation, timestamp preservation and release acceptance
remain untested by these fixtures. Working kernel and AI service were unchanged.
