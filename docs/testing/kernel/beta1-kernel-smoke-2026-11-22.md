# SableLinux Beta 1 — Kernel Boot Validation

Date: 2026-11-22
Canonical host: Z890 SableLinux
Branch: development

## Candidate

Candidate ID:
20261122T181958Z-0b30f88-linux-6.16.1-beta1-test1

Kernel:
6.16.1-sable-beta1-test1

Git commit:
0b30f88c38523e295e83708f6cbaeb3641c5bf8f

## Validation

Harness:
scripts/testing/run-kernel-smoke-vm.sh

Method:
- Candidate integrity verification
- Direct kernel boot using QEMU/KVM
- Isolated static BusyBox initramfs
- Guest kernel identity verification
- Serial-console evidence capture
- QEMU exit-status verification

## Results

Candidate verification: PASS
Kernel artifacts verified: 3
Module files verified: 77
Kernel smoke test: PASS
QEMU exit status: 0

Evidence:
/srv/sablelinux/testing/kernel-smoke-6mNKNmOR

## Host preservation

No kernel installation, module deployment, or
bootloader modification was performed.

## Scope

Verified:
- Kernel direct boot under QEMU/KVM
- Minimal initramfs execution
- Expected guest kernel identity
- Successful guest termination

Pending:
- SquashFS and extended-attribute validation
- OverlayFS writable root
- Complete live userspace startup
- OVMF and GRUB
- Installer validation
- Physical hardware validation

This result establishes the kernel smoke-test gate,
not full Tier 1 or Beta 1 release qualification.
