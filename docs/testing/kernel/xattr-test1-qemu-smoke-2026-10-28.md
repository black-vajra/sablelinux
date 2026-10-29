# SableLinux xattr-test1 — QEMU Kernel Smoke Test

Date: 2026-10-28
Canonical host: Z890 SableLinux
Repository branch: development

## Kernel candidate

Candidate ID:
20261028T212705Z-622d439-linux-6.16.1-xattr-test1

Kernel release:
6.16.1-sable-xattr-test1

Build Git commit:
bb2592ce2354126787598cc00d8cd7749ec4f003

## Test

Harness:
scripts/testing/run-kernel-smoke-vm.sh

Method:
- Direct QEMU/KVM kernel boot
- Independently generated static BusyBox initramfs
- Serial console capture
- Guest kernel release verification
- Explicit guest success marker
- QEMU exit-status verification

## Results

Guest output:

    SABLE_KERNEL_VM_BEGIN
    Guest kernel: 6.16.1-sable-xattr-test1
    SABLE_KERNEL_VM_PASS

QEMU exit status: 0

Result: PASS

## Retained evidence

/srv/sablelinux/testing/kernel-smoke-kaICjO3b

The evidence directory contains the generated initramfs,
serial-console logs, QEMU command, and provenance metadata.

Recorded test creation:
2026-10-29T00:41:28Z

## Host preservation

Running host kernel:
6.16.1-sable-gpu-test2

No kernel installation, host module installation, or GRUB
modification was performed.

## Validation scope

Verified:
- Kernel direct boot under QEMU/KVM
- Initramfs execution
- Expected guest kernel identity
- Guest success marker
- Clean QEMU exit

Not yet verified:
- SquashFS mounting and extended attributes
- OverlayFS writable root
- Full live userspace startup
- OVMF/GRUB boot
- Installer deployment
- Physical hardware boot

This is a kernel smoke-test PASS, not full live-root
or release qualification.
