# SableLinux Beta 1 — QEMU Filesystem Integration

Date: 2026-11-22
Canonical host: Z890 SableLinux
Branch: development

## Kernel candidate

Candidate:
20261122T181958Z-0b30f88-linux-6.16.1-beta1-test1

Kernel:
6.16.1-sable-beta1-test1

Build commit:
0b30f88c38523e295e83708f6cbaeb3641c5bf8f

## Test

Harness:
scripts/testing/run-squashfs-overlay-vm.sh

Method:
- Independent candidate integrity verification
- Fresh SquashFS fixture generation
- Direct QEMU/KVM kernel boot
- SquashFS read-only mount and content verification
- Extended-attribute retrieval
- OverlayFS writable copy-up
- Read-only lower filesystem preservation

## Results

Candidate integrity: PASS
Kernel artifacts: 3 verified
Kernel module files: 77 verified
Fresh SquashFS fixture: PASS
SquashFS mount: PASS
SquashFS contents: PASS
Extended attributes: PASS
OverlayFS mount: PASS
OverlayFS copy-up: PASS
Read-only lower filesystem preservation: PASS
Guest success marker: SABLE_FS_VM_PASS
QEMU exit status: 0

Overall result: PASS

## Evidence

/srv/sablelinux/testing/squashfs-overlay-vm-ycOMAYdn

## Host preservation

No kernel installation, module deployment, or bootloader
modification was performed.

## Validation boundaries

This test uses a generated filesystem fixture and minimal
initramfs, not the complete SableLinux distribution rootfs.

Pending:
- Complete live-root generation and security validation
- Live initramfs boot and switch_root
- Full SableLinux userspace startup
- OVMF and GRUB boot
- Installer deployment
- Physical hardware acceptance

This is a Tier 1 filesystem integration PASS,
not full live-media or release qualification.
