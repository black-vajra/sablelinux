# Canonical kernel-candidate initialization — 2026-11-02

## Authority and identity

- Canonical host: Z890 SableLinux
- Build ID: `20261102T173535Z-8e0d5d1-k6.16.1-sable-xattr-test1`
- Created: `2026-11-02T17:35:35Z`
- Git branch: `development`
- Source commit: `8e0d5d118e4f7d614891c6dbc3f0a80562a244d7`
- Source dirty: `false`
- Build state: `initialized`

## Kernel provenance

- Release: `6.16.1-sable-xattr-test1`
- Candidate: `20261028T212705Z-622d439-linux-6.16.1-xattr-test1`
- Preparation commit: `622d43977f97b6142462055c031defef31a0f868`
- Compilation commit: `bb2592ce2354126787598cc00d8cd7749ec4f003`
- Kernel modules staged: `false`

## Validation

- Release regression suite: 80 tests passed
- Activated initializer isolation matrix: 5 scenarios passed
- Production candidate verification: passed
- Canonical initialization: exit status 0
- Kernel artifact SHA256 verification: 3 of 3 passed
- Boot and metadata artifact manifests: identical
- Candidate kernel module checksum inventory: 57 entries
- Build completion marker: initialized
- Canonical pointer: selected this build
- Pointer ownership: root:pepper, mode 664
- Creation lock: released
- Running kernel remained 6.16.1-sable-gpu-test2

## Evidence

- Canonical build: `/srv/sablelinux/builds/20261102T173535Z-8e0d5d1-k6.16.1-sable-xattr-test1`
- Initialization log: `/var/tmp/sable-m110-first-canonical-init.log`
- Initialization log SHA256: `20e85cc5145d7feb63813aba0eacf09a903cc6a4cb5052f440202e575da4d77b`
- Staged artifact manifest SHA256: `b5054f9067db27c90520230db6743351b9648b025aaefd82d1cbb48fcd5515c4`
- Module manifest SHA256: `4666a4b65a6bfa0ab8ee15c48be7f947455b70d8dd400783203f356965165f75`
- Isolated matrix log: `/var/tmp/sable-m110-activated-matrix.log`

## Outstanding release blockers

1. Kernel modules have not been staged into a release root.
2. A current canonical package-manifest generator is required.
3. Reproducible staging-root and SquashFS generation remain outstanding.
4. Live initramfs and media generation remain outstanding.
5. Tiered QEMU, EFI, installer, and hardware validation remain outstanding.

## Release classification

This is an initialized canonical build workspace, not a release
candidate or validated bootable image.

This document records the observed initialization milestone.
Canonical build metadata remains the authoritative source of build identity.
