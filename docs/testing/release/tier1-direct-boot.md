# Tier 1 direct kernel boot

Validated on the canonical Z890 using disposable integration artifacts.

## Procedure

Generate the fixture, SquashFS and initramfs:

    SABLE_TEST_FINALIZATION=normal-with-squashfs bash tests/release/run-rootfs-selfcontained.sh

Run the boot test against the evidence directory printed by that command:

    bash tests/release/run-tier1-boot.sh /var/tmp/sable-m112-e2e-FTJenTUh

The runner verifies the kernel, initramfs and SquashFS hashes against
live-boot-inputs.sha256. It creates fresh 128 MiB ext4 media labeled
SABLELINUX and boots through QEMU/KVM with a read-only virtio disk.

Serial output goes to a dedicated file. The bounded test requires QEMU
exit status zero, the exact userspace success marker, and no userspace
failure marker.

## Verified result

SABLE_TIER1_BOOT_PASS

The guest found the labeled medium, mounted ext4 and SquashFS, created
the overlay root, and switched into the fixture's /sbin/init. That probe
verified an overlay root and a successful write, then powered off.

Retained automated-run evidence:

    /var/tmp/sable-m112-e2e-FTJenTUh/tier1-sQeSUjOR

Earlier successful visible and headless runs:

    /var/tmp/sable-m112-e2e-FTJenTUh/tier1-visible-4RcDRVos
    /var/tmp/sable-m112-e2e-FTJenTUh/tier1-headless-9tknXSii

## Fixture and harness changes

The fixture now provides /sbin -> usr/sbin and a working /sbin/init
link to a BusyBox-based userspace probe. Static BusyBox is included.
The integration harness imports the fixture source into its disposable
checkout and creates a test commit only when staged changes exist.

## Scope and remaining validation

This result covers the selected release kernel and synthetic userspace.
Full release userspace, EFI/GRUB, installation, and hardware acceptance
remain pending.

Earlier serial-stdio runs timed out with empty logs under both KVM and
TCG. File-based serial capture passed with visible and headless KVM.
The precise cause of the earlier timeouts remains undetermined.
