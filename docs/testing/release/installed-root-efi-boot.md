# Synthetic installed-root EFI boot

Validated on canonical Z890 after the synthetic direct boot and
persistence checkpoint at ab32e37.

The test verified the prior qcow2 and kernel hashes, copied the tested
ext4 filesystem into partition 2 of a fresh GPT image, and placed
standalone GRUB and the verified kernel on its EFI System Partition.
GRUB selected the ext4 partition by PARTUUID. QEMU used fresh OVMF
variables and booted from the target qcow2 alone.

Result: SABLE_INSTALLED_EFI_BOOT_PASS

Serial evidence records GRUB entry, writable ext4 root on /dev/vda2,
recovery of the prior boot's persistent marker, read-only remount, and
poweroff. QEMU exited zero, GPT verification reported no problems, and
the final qcow2 structural check reported no errors.

Evidence: /var/tmp/sable-m112-e2e-FTJenTUh/installed-efi-uThKWNhw

The host assembled this synthetic disk. The next gate is deployment
from a live guest to a blank disposable qcow2, followed by a separate
OVMF boot with the source media detached. Release userspace and metadata
preservation require their own validation.
