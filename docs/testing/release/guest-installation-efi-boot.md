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

## Repeatable fixture runner

Run from the repository root as an unprivileged user with KVM access:

    bash tests/release/run-guest-install.sh /var/tmp/sable-m112-e2e-FTJenTUh

The runner verifies the fixture kernel and SquashFS hashes and creates
a fresh root PARTUUID, GRUB loader, deployment initramfs and blank qcow2.
It requires a successful guest installation and two disk-only EFI boots
that verify a fresh write and its persistence.

Validated runner evidence:
`/var/tmp/sable-m112-e2e-FTJenTUh/guest-install-RFkXc8dH`

## Installed metadata fixture

Generate a fresh integration fixture with
`SABLE_TEST_FINALIZATION=normal-with-squashfs bash tests/release/run-rootfs-selfcontained.sh`.
Use its printed test-root path with
`SABLE_INSTALL_METADATA=1 bash tests/release/run-guest-install.sh TEST_ROOT`.
The optional checker requires a C compiler with static libc support.

The checker requires a regular file with numeric UID 12345, GID 23456,
mode 0640, a second name for the same inode with link count 2, and
`user.sable_install_test=preserved`. The runner requires a pass on the
mounted SquashFS, on freshly extracted ext4, and on both disk-only
EFI boots. Persistence and qcow2 checks also passed.

Validated on canonical Z890:
`/var/tmp/sable-m112-e2e-Rka4G4LY/guest-install-3Nc4A94p`

POSIX ACLs and file capabilities remain outside this fixture's coverage.

## File capability preservation

The metadata fixture now includes an executable with `cap_net_raw=ep`.
The checker verifies the exact `security.capability` bytes on the
mounted SquashFS, on freshly extracted ext4, and on both disk-only EFI
boots. The executable is used as a metadata fixture and is never run.

Validated on canonical Z890:
`/var/tmp/sable-m112-e2e-PUYmS652/guest-install-5baLyIzz`

Use a freshly generated fixture when enabling `SABLE_INSTALL_METADATA=1`
so the SquashFS includes the capability probe. POSIX ACL preservation
remains a separate gate.
