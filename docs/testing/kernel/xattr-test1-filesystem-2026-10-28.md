# SableLinux xattr-test1 — QEMU Filesystem Integration

Date: 2026-10-28 (EDT)
Canonical host: Z890 SableLinux
Branch: development

## Objective

Validate SquashFS extended-attribute support and OverlayFS
writable copy-up with the isolated xattr-test1 kernel.

## Kernel

Release: 6.16.1-sable-xattr-test1

Candidate:
20261028T212705Z-622d439-linux-6.16.1-xattr-test1

Kernel build commit:
bb2592ce2354126787598cc00d8cd7749ec4f003

Kernel artifact SHA256:
8ddbc44942be548edd2a9cb27bdce87486d3eb1f845193e21348ca1d9a3335d9

## Test

Harness:
scripts/testing/run-squashfs-overlay-vm.sh

Test execution Git commit:
61713d2fe4ce6fa27994c2a704d23f45def7bd9b

QEMU version: 9.2.3
Recorded test creation: 2026-10-29T00:56:12Z

Test fixture:
/srv/sablelinux/testing/squashfs-xattr-55lMdJcu/filesystem.squashfs

SquashFS SHA256:
b3830f7e421e48a102b275bb43d6e0a64d2dd8c643456056a810d7e537780728

Generated test initramfs SHA256:
c07d4937ff0dba8ff9f7a8f4741231867644e817d84ec1e73f0dee4b6d1ddd30

Retained evidence:
/srv/sablelinux/testing/squashfs-overlay-vm-jk4MXDto

## Verified results

- Direct QEMU/KVM kernel boot: PASS
- SquashFS read-only mount: PASS
- SquashFS file-content verification: PASS
- SquashFS user.sable_test attribute retrieval: PASS
- OverlayFS mount: PASS
- OverlayFS writable copy-up: PASS
- Original read-only filesystem preservation: PASS
- Guest marker SABLE_FS_VM_PASS: PRESENT
- QEMU exit status: 0

Overall result: PASS

## Host preservation

Running kernel: 6.16.1-sable-gpu-test2

No host kernel installation, module installation, or GRUB
modification was performed.

## Reproducibility limitations

The test fixture was generated manually using SquashFS Tools
4.6.1 with gzip compression and extended attributes enabled.

The harness currently references this fixture and kernel
candidate by fixed paths. Fixture creation must be automated,
inputs parameterized, and negative-path tests added before
claiming a fully reproducible filesystem regression pipeline.

## Scope

This validates focused Tier 1 filesystem integration.

Not yet validated:
- Complete SableLinux live-root generation and boot
- Live initramfs discovery and switch_root
- OVMF/GRUB boot
- Installer deployment
- Physical hardware boot

This result is not release qualification.
