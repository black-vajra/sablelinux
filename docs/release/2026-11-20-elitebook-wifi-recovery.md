# EliteBook Qualcomm Wi-Fi Recovery — November 20, 2026

## Status

Hardware recovery: PASS.
Normal reboot with replacement GRUB menu: operator-confirmed PASS.
Release integration: PENDING.

Canonical build host: Z890 SableLinux.
Validation target: HP EliteBook SableLinux installation.
Repository branch: development.

## Original problem

The installed 6.16.1-sable-portable-test1 kernel did not
contain the Qualcomm ath11k PCI driver required by the
EliteBook QCNFA765 wireless adapter [17cb:1103].

Firmware was present, but the matching driver was unavailable.

## Canonical kernel recovery

Kernel: 6.16.1-sable-wifi-recovery1

Build commit:
a4cdab3a039197b51e16971a77ef6adb194f1149

Candidate:
20261120T223424Z-a4cdab3-linux-6.16.1-wifi-recovery1

Canonical build directory:
/srv/sablelinux/kernel-builds/20261120T223424Z-a4cdab3-linux-6.16.1-wifi-recovery1

Verified Linux source: 6.16.1.

Configuration inherited the portable-test1 transformations,
including Intel wireless, portable touchpad support,
I2C HID, SquashFS, and SquashFS XATTR.

Resolved Qualcomm options:

- CONFIG_ATH11K=m
- CONFIG_ATH11K_PCI=m
- CONFIG_MHI_BUS=m
- CONFIG_QRTR=m
- CONFIG_QRTR_MHI=m
- CONFIG_QCOM_QMI_HELPERS=m

Kernel preparation: PASS.
Source integrity validation: PASS.
Kernel compilation and module staging: PASS.
Kernel artifact and module checksum validation: PASS.

The build script staged the kernel and modules without
installing them into the canonical Z890 host.

## Deployment

Recovery archive:
sable-wifi-recovery1-elitebook.tar.gz

Archive SHA256:
fa5cf89b6f02253806d7635e6071d32a9f7c1fb2f44002c0b5d7fcc68091915a

The archive was transferred using a SanDisk USB drive,
repartitioned as GPT with one ext4 filesystem labeled
SABLE_TRANSFER.

The archive was SHA256-verified on both machines.

Installed on EliteBook:

/boot/vmlinuz-6.16.1-sable-wifi-recovery1
/boot/config-6.16.1-sable-wifi-recovery1
/lib/modules/6.16.1-sable-wifi-recovery1/

The Z890-specific module build symlink was excluded.

Installed kernel SHA256:
11aa83355ba70473648382f5905ee0312493f7c502e6245a1a347428e74aa9fe

Original portable-test1 kernel retained.

## Hardware validation

An initial one-time GRUB boot successfully started
6.16.1-sable-wifi-recovery1.

Verified on the running recovery kernel:

- Qualcomm QCNFA765 [17cb:1103]
- Kernel driver in use: ath11k_pci
- ath11k, mhi, qrtr, qrtr_mhi, qmi_helpers loaded
- Wireless interface wlp2s0: UP, LOWER_UP
- Wireless IPv4 address obtained
- WireGuard interface wg-elitebook: UP

This establishes functional physical hardware validation
of the recovered wireless driver.

## Permanent GRUB configuration

The EliteBook uses UEFI entry Boot0005:
EFI/SableLinux-Test/grubx64.efi

The original loader contained an embedded two-entry menu:
SableLinux Test and Kubuntu.

The existing /boot/grub/grub.cfg was identified as stale
and was not used to regenerate the new bootloader.

A new standalone GRUB EFI image was generated with
three entries:

1. SableLinux Wi-Fi Recovery (default)
2. SableLinux portable-test1 (fallback)
3. Kubuntu

Timeout remains eight seconds.

Kernel and Kubuntu chainloader paths are recorded in:
docs/release-validation/elitebook-wifi-recovery-grub.cfg

Replacement EFI loader SHA256:
228a058537ee6f43b53da3a76a5bd1564e4247f08389e9585e515db48a334d0c

Original EFI loader SHA256:
127813d5d9fab71272ab44ae900fef6bc0769e88aeecb317ac27df441df75e89

Original backup:
EFI/SableLinux-Test/grubx64.efi.backup-20261120

The original backup was SHA256-verified before replacement.
The new loader was SHA256-verified after installation.

The EFI boot entry and firmware boot order were not
intentionally changed.

The operator subsequently confirmed a successful normal
reboot test with the replacement bootloader.

## Obsolete kernel quarantine

Older compat and LFS kernel images and initramfs files
were moved to:

/boot/obsolete-kernels-2026-11-20/

SHA256SUMS was captured before relocation.

The compat2 kernel and initramfs were retained.
Matching compat2 modules are absent from the new root;
compat2 is not a verified recovery boot.

The old GRUB configuration still contains obsolete entries.
Do not use these entries until its configuration is repaired.

## Rollback

The portable-test1 kernel remains selectable in the
new GRUB menu.

If the replacement EFI loader fails, restore the original
backup using an independently bootable recovery environment.
Do not depend on the failing loader to perform recovery.

The preserved EFI backup has the original SHA256 listed
above. Verify that hash before restoring it.

## Process improvements

Always identify removable storage by model, serial,
capacity, filesystem UUID, and intended physical device
before writing.

Do not assume /dev/sdX names are stable across machines.

Protect interactive operator shells from failure-driven exit.

Preserve completed build artifacts and boot configurations
outside /tmp when reboots are anticipated.

## Release follow-up

- Incorporate Qualcomm support into the next portable kernel.
- Add automated configuration regression tests for ath11k.
- Validate the consolidated kernel under the test hierarchy.
- Retain the EliteBook as a hardware-validation target.
- Keep release artifact authority on canonical Z890.
- Resolve stale legacy GRUB references separately.
- Complete independent rootfs security validation before
  any public ISO release.

This record documents a successful recovery, not a
completed portable-test2 release or ISO validation.
