# Tier 2 OVMF and GRUB boot validation

Validated on the canonical Z890 using retained disposable artifacts
that previously passed Tier 1.

## Procedure

    bash tests/release/run-tier2-boot.sh /var/tmp/sable-m112-e2e-FTJenTUh

The runner verifies kernel, initramfs and SquashFS hashes. Each run
creates a GPT disk with a FAT32 EFI System Partition and the fallback
loader EFI/BOOT/BOOTX64.EFI, plus a separate ext4 live filesystem disk.

GRUB loads the verified kernel and initramfs from the EFI partition.
OVMF uses read-only firmware code and a fresh private variable store.
Firmware input hashes and generated media hashes are retained.
Serial output is captured to a file with a bounded QEMU timeout.

## Verified result

SABLE_TIER2_OVMF_GRUB_PASS

Required checks passed:
- QEMU exited successfully.
- The GRUB entry marker appeared.
- The guest discovered the labeled ext4 live medium.
- SquashFS and overlay setup reached switch_root.
- Fixture userspace confirmed an overlay root and a successful write.
- The guest powered off cleanly.

Manual-run evidence:

    /var/tmp/sable-m112-e2e-FTJenTUh/tier2-L9knX6XP

Automated fresh-media evidence:

    /var/tmp/sable-m112-e2e-FTJenTUh/tier2-V67QwkeI

## Acceptance scope

This validates the two-disk EFI/GRUB handoff with synthetic userspace
and the selected release kernel. ISO packaging, Secure Boot, full release
userspace, installation and physical hardware acceptance remain pending.
