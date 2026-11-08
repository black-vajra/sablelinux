# Synthetic guest installation and independent EFI boot

Validated on canonical Z890 after the guest partition-image deployment
checkpoint at 31aec9f.

The installer guest created GPT, FAT32 and ext4 on a blank 640 MiB qcow2.
It extracted the verified synthetic SquashFS onto the mounted ext4 root,
installed a prepared GRUB EFI loader and the verified kernel on the ESP,
and checked the installed loader, kernel and test init hashes.

Two separate OVMF launches booted the target disk alone, each with fresh
firmware variables. The first wrote a new persistence marker. The second
read it back. Both mounted writable ext4 on /dev/vda2, remounted it
read-only before shutdown, and exited zero. The qcow2 check found no errors.

Result: SABLE_GUEST_INSTALL_AND_EFI_BOOT_PASS

Evidence: /var/tmp/sable-m112-e2e-FTJenTUh/guest-install-NltxiNDq

Scope: synthetic file-level installation using a prepared EFI loader.
Release userspace, guest-side bootloader generation and explicit metadata
preservation checks remain separate validation gates.
