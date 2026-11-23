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

---

## Supplemental engineering findings — 2026-11-22

This section supplements the initial report with findings established
during the complete ISO-to-installed-system validation sequence.

### 1. ISO generation and USB deployment

The canonical Z890 generated a hybrid BIOS/UEFI installer ISO using
scripts/live/build-installer-iso.sh.

Verified:
- ISO SHA256 integrity
- BIOS and UEFI El Torito boot entries
- GRUB live-media label SABLEASUS
- Successful physical USB boot on ASUS hardware

The initial USB-writing safety check rejected the correct SanDisk device
because the serial number displayed by lsblk was truncated.

The full identifier was subsequently retrieved through udev.

Follow-up:
- Use stable, complete device identifiers.
- Preserve explicit target verification before destructive writes.
- Record ISO and written-media verification results separately.

### 2. ASUS physical live validation

PASS:
- USB live boot
- Sway graphical desktop
- Physical Wi-Fi connectivity
- Firefox and Internet access

Hardware inventory and comprehensive peripheral validation remain pending.

### 3. Original installation failure — cause unverified

The initial installer attempt failed with:

    Error: install path already exists

IMPORTANT: The internal SSD already contained three partitions:

    /dev/sda1  512 MiB   FAT32  EFI
    /dev/sda2    2 GiB   ext4   BOOT
    /dev/sda3 474.4 GiB  ext4   SABLE_ROOT

Therefore, the failure must not be attributed to missing partitions
without further investigation.

The installer path involved and exact failure condition remain unknown.

Track this independently from the fresh-install partition prerequisites.

### 4. Fresh-install partition prerequisites

Inspection of the installer scripts confirmed that fresh installation
requires three existing, formatted GPT partitions supplied by PARTUUID.

The installer validates these partitions but does not create them.

The ASUS was subsequently prepared with:

    EFI:  512 MiB, GPT EFI System Partition, FAT32
    BOOT:   2 GiB, ext4
    ROOT: remaining capacity, ext4

All partitions reside on the internal P3-512 SSD.

### 5. Partition-table refresh recovery

After successful GPT creation, the kernel initially rejected partprobe:

    partprobe: /dev/sda: Device or resource busy

The partition mapping was refreshed without rebooting using:

    partx -u /dev/sda
    udevadm settle

All three kernel-visible PARTUUIDs were verified against their
corresponding on-disk GPT unique GUIDs before formatting.

This is a verified recovery procedure for this incident, not a
general-purpose instruction to bypass busy-device safeguards.

### 6. UEFI boot-order verification failure

After successful filesystem deployment and password configuration,
the installer created the SableLinux Test boot entry but reported:

    BootCurrent: 0006
    No BootOrder is set; firmware will attempt recovery
    Boot0000* SableLinux Test

    ERROR: System deployed, but the firmware boot order could not be read.

The ASUS subsequently booted SableLinux successfully from its
internal SSD.

Conclusion:
- Deployment succeeded.
- First boot succeeded.
- Installer firmware-order verification reported a nonfatal failure
  on this hardware.
- The underlying firmware/installer interaction remains undiagnosed.

The installer must report deployment success separately from
firmware boot-order verification uncertainty.

### 7. Installer usability

The current destructive-operation confirmation requires lengthy
manual ERASE input.

Future improvements should provide:
- Explicit installation-target selection
- Target model, size, and partition summary
- Clear destructive-operation warning
- Simple confirmation defaulting to No
- Continued protection of live media and unrelated disks

### 8. Release-engineering follow-up

The ASUS-oriented ISO generator successfully produced bootable media,
but ISO generation and validation are not yet fully integrated into
the canonical build-state pipeline.

Required follow-up:
- Canonical ISO generation with build-ID provenance
- Recorded ISO and USB hashes
- Automated qcow2 installer regression tests
- UEFI/OVMF installation validation
- Physical ASUS post-installation validation

### Validation checkpoint

PASS: Canonical Beta 1 ISO generation.
PASS: Physical ASUS live USB boot.
PASS: Sway, Wi-Fi, and Firefox in the live environment.
PASS: Fresh filesystem deployment.
PASS: First boot from ASUS internal SSD.

OPEN: Installer path-exists failure.
OPEN: Manual partition preparation requirement.
OPEN: Firmware BootOrder verification behavior.
OPEN: Installer confirmation usability.
OPEN: Complete post-install hardware regression validation.
