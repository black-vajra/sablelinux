# Canonical Z890 Artifact Layout

The running Z890 SableLinux installation is the canonical build host and
release authority.

Maintained scripts, configuration, policy, and documentation live in:

/home/pepper/sablelinux

Generated build state and release artifacts live in:

/srv/sablelinux

Historical live-root trees, copied USB contents, VM payloads, and artifacts
generated on secondary systems are not authoritative build inputs.

## Top-Level Layout

/srv/sablelinux/
  builds/
  cache/
    downloads/
    packages/
  releases/
    candidates/
    published/
  reports/
  state/
    locks/

## Per-Build Layout

Each canonical build receives a unique directory:

builds/<build-id>/
  rootfs/
  boot/
  squashfs/
  initramfs/
  media/
  installer/
  logs/
  metadata/
  reports/
  tmp/

Build ID format:

YYYYMMDDTHHMMSSZ-<git-short-commit>-k<kernel-release>

Example:

20260717T193000Z-a196bd3-k6.16.1-sable-compat

## Operational Rules

1. Build directories are created by repository-controlled scripts.
2. Do not manually maintain /mnt/liveroot* trees.
3. Do not copy secondary-system artifacts into canonical builds.
4. Do not build directly inside release directories.
5. Keep logs and metadata with the build that produced them.
6. Treat cache and temporary directories as disposable.
7. Promote artifacts only after validation.
8. Published releases are immutable.
9. Every build must record its Git commit, timestamp, kernel release,
   package manifest, script versions, hashes, and validation results.
10. Conversation history is not a build dependency.

## Validation Progression

canonical source
  -> generated live root
  -> SquashFS
  -> live initramfs
  -> direct QEMU/KVM validation
  -> OVMF and GRUB validation
  -> qcow2 installation validation
  -> physical hardware validation
  -> release candidate
  -> published release
