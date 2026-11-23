# ASUS Beta 1 Installation Validation

Date: 2026-11-22
Canonical build: 20261122T214629Z-2aca578-k6.16.1-sable-beta1-test1
Source commit: 2aca578
Kernel: 6.16.1-sable-beta1-test1

Validation hardware:
- ASUS laptop
- Internal SSD: P3-512, 476.9 GiB
- Installation media: SABLEASUS USB ISO

## Overall result

PASS: Live boot, Wi-Fi, Firefox, and desktop operation.

PASS: Installation ultimately produced a bootable system on the
internal SSD.

INSTALLER DEFECTS: Two issues require correction.

## Issue 1: Fresh installation requires prepared partitions

The fresh-install workflow requires the operator to supply three
existing GPT partitions identified by PARTUUID.

Verified prerequisites:

- EFI: 512 MiB, FAT32, GPT EFI System Partition type
- BOOT: 2 GiB, ext4
- ROOT: remaining capacity, ext4
- All three partitions on the same disk
- Target partitions must not be mounted

The installer planner validates these prerequisites but does not
create the partition layout.

During ASUS validation, an initial installation attempt failed with:

    Error: install path already exists

The precise cause of that earlier error remains unverified.

After the internal disk was repartitioned and formatted, installation
proceeded.

Required follow-up:

1. Document option 4's partitioning prerequisites clearly.
2. Determine whether fresh-install mode should prepare the disk.
3. Provide clear, safe target selection and confirmation.
4. Add automated installation tests using qcow2 targets.
5. Reproduce and diagnose the earlier install-path error separately.

## Issue 2: UEFI boot-order verification reports installation failure

After filesystem deployment and successful password configuration,
the installer reported:

    BootCurrent: 0006
    No BootOrder is set; firmware will attempt recovery
    Boot0000* SableLinux Test

    ERROR: System deployed, but the firmware boot order could not be read.

The ASUS was subsequently rebooted and successfully started
SableLinux from its internal SSD.

Observed outcome:

- Filesystem deployment completed.
- UEFI boot entry was present.
- Boot-order verification reported an error.
- The installed operating system booted successfully.

This demonstrates a nonfatal boot-order verification failure
on the tested ASUS firmware.

The underlying cause has not yet been determined.

Required follow-up:

1. Inspect the installer boot-order verification logic.
2. Distinguish successful deployment from firmware-order uncertainty.
3. Check whether BootOrder can be read or repaired safely.
4. Avoid reporting complete installation failure when the deployment
   succeeded and a working boot path exists.
5. Test the behavior under OVMF and physical UEFI firmware.

## Installer usability

The current ERASE confirmation requires lengthy manual input.
Investigate replacing it with explicit disk selection, a clear
destructive-operation summary, and a confirmation defaulting to No.

Do not weaken target identity verification or live-media protection.

## Release status

ASUS first boot: PASS.

Installer reliability: NOT YET RELEASE-READY.

Both defects remain open pending diagnosis, corrections, and
automated regression validation.
