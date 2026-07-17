# Canonical Build Directory Lifecycle

Each canonical SableLinux build begins with:

scripts/release/create-build.sh

The script creates a uniquely identified directory beneath:

/srv/sablelinux/builds/

Initial build state:

initialized

The initial build record contains:

- build ID
- UTC creation timestamp
- canonical hostname
- Git branch and commit
- clean repository status
- kernel release
- kernel and System.map hashes
- kernel-module file hashes
- repository index
- tool versions
- storage and mount information
- operating-system identity

No root filesystem is copied during build initialization.

Expected state progression:

initialized
  -> rootfs-generated
  -> squashfs-generated
  -> initramfs-generated
  -> tier1-validated
  -> boot-media-generated
  -> tier2-validated
  -> installer-validated
  -> hardware-validated
  -> release-candidate
  -> published

A build must not skip validation tiers.

Historical package inventories are not sufficient for release promotion.
Each build must acquire a current package manifest before release-candidate
status.
