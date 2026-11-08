# Synthetic installed-root direct boot

Validated on canonical Z890 using a disposable ext4 qcow2 disk.

## Procedure

    bash tests/release/run-installed-root-boot.sh \
        /var/tmp/sable-m112-e2e-FTJenTUh

The runner verifies the retained kernel and SquashFS against the live
boot input manifest. It extracts a disposable synthetic root and replaces
only that copy's userspace probe. A fresh whole-disk ext4 image is populated
and converted to qcow2.

QEMU boots the verified kernel directly, without an initramfs or attached
live media. The first boot verifies writable ext4 root and writes a marker.
The second boot verifies that marker persisted. Both require a successful
read-only root remount and QEMU exit status zero. Guest failure markers
cause rejection. The final qcow2 structural check must pass.

## Result and evidence

SABLE_INSTALLED_ROOT_DIRECT_BOOT_PASS

Successful run:
`/var/tmp/sable-m112-e2e-FTJenTUh/installed-root-SUZyKYqd`

Initial failed run:
`/var/tmp/sable-m112-e2e-FTJenTUh/installed-root-jokHU8D6`

The initial probe attempted to mount devtmpfs although the kernel had
already mounted it. The corrected probe verifies an existing /dev mount
is devtmpfs, or mounts it when absent. The fresh retry passed both boots.

## Acceptance boundary

This validates synthetic direct installed-root boot and persistence.
It does not validate GPT/EFI installed boot, installer execution,
full release userspace, filesystem metadata preservation or hardware.
The extraction is unprivileged; installed ownership, capabilities and
xattrs are explicitly outside this test's acceptance scope.

Next: validate a disposable GPT/EFI installed disk through OVMF and GRUB,
without QEMU direct kernel injection or attached live media.
