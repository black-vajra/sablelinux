# HP Pavilion Beta 1 Validation and Release Follow-up

Date: 2026-11-23
Release build: 20261122T214629Z-2aca578-k6.16.1-sable-beta1-test1
Canonical release authority: Z890 SableLinux SATA installation
Validation hardware: HP Pavilion, Intel graphics, HP SSD S750 1 TB
Installation media: SABLEASUS hybrid ISO

## 1. Physical live-boot validation

The HP Pavilion booted the Beta 1 live USB and reached systemd.

Verified:
- Intel i915 initialized successfully.
- Realtek ALC671 audio codec detected.
- Realtek r8169 Ethernet established a 1 Gbps link.
- Live SquashFS/OverlayFS root operational.
- systemd reached graphical.target.
- Sway launched successfully.
- Both Waybar processes operated.

### tty1 login-prompt presentation defect

The initial display appeared to hang on kernel initialization messages.

Ctrl+Alt+F2 presented a working tty2 login.
Logging in and manually launching Sway succeeded.

Investigation established:
- Default target: graphical.target
- getty@tty1.service: active and running
- tty1 agetty process present
- tty2 registered as an active Wayland login session
- Switching to tty1 displayed the previous kernel messages
- Pressing Enter revealed the tty1 login prompt
- Logging in on tty1 automatically launched Sway

Conclusion:
The live operating system did not hang. The tty1 login prompt was
not initially visible, despite a functional getty and keyboard.

Root cause remains unverified.

Release requirement:
Investigate console/getty prompt presentation and validate reliable
live login on physical hardware before public ISO release.

## 2. Pavilion partition and dual-boot validation

Internal disk: HP SSD S750 1 TB (/dev/sda during validation).

Verified partition layout:
- /dev/sda1: 512 MiB FAT32 EFI
- /dev/sda2: 2 GiB ext4 SableLinux BOOT
- /dev/sda3: 293.3 GiB ext4 SABLE_ROOT
- /dev/sda4: 4 GiB ext4 Kubuntu BOOT
- /dev/sda5: 654.1 GiB encrypted Kubuntu

The SABLEASUS installation USB was /dev/sdb.

The default dual-boot installer planner passed, confirming SableLinux
OS identity, fstab partition mapping, filesystem types, and Kubuntu's
existing EFI/ubuntu/shimx64.efi loader.

The selected installation mode replaces only the SableLinux root while
reusing SableLinux BOOT and the shared EFI partition.

## 3. Existing boot-path collision

The installer refuses installation when either path exists:
- BOOT:/sablelinux-test
- EFI:/EFI/SableLinux-Test

Both directories existed on the Pavilion.

To preserve existing boot files and satisfy the installer preflight,
the directories were renamed to:
- BOOT:/sablelinux-test-pre-beta1-20261123
- EFI:/EFI/SableLinux-Test-pre-beta1-20261123

Both preservation operations were verified successful.
Kubuntu's EFI loader remained present.

This is a confirmed replacement-workflow limitation. The installer
should manage release-owned boot paths transactionally, preserving
rollback material without requiring manual filesystem intervention.

The related ASUS 'Install path already exists' failure was previously
observed, but its exact original filesystem state remains unverified.

Pavilion installation completion and first boot have not yet been
verified in this journal.

## 4. Pavilion Wi-Fi discovery failure

The Pavilion's wifi-connect script reported no Wi-Fi interface.

The same physical machine had previously been configured successfully
for Wi-Fi in an earlier SableLinux installation.

The Beta 1 live image therefore requires an investigation of its
device-driver, module, firmware, and hardware-discovery coverage.

The adapter identity and immediate failure cause remain unverified.

Release requirement:
- Discover network hardware through standard PCI/USB modalias mechanisms.
- Verify kernel driver and module availability.
- Verify distributable firmware inclusion and successful loading.
- Validate udev/kmod automatic driver binding.
- Produce actionable diagnostics when an interface is absent.
- Maintain tested hardware-support records for Pavilion, ASUS,
  EliteBook, and Z890.
- Do not require device-specific ISO rebuilds for supported hardware.

## 5. Desktop installer usability

Add a visible 'Install SableLinux Now' launcher to the live Sway
desktop.

The launcher must:
- Detect and present suitable installation targets.
- Distinguish fresh, single-OS replacement, and dual-boot modes.
- Invoke the existing planner before any destructive action.
- Clearly identify affected and preserved partitions.
- Require explicit confirmation.
- Display phase progress, elapsed time, and persistent diagnostics.
- Preserve installation logs and distinguish deployment success
  from firmware boot-order verification uncertainty.

Do not embed machine-specific PARTUUIDs in the ISO.

## 6. Installer progress reporting

The installer may appear inactive after 'boot/vmlinuz: OK'.

That message is a checksum result, not proof of which subsequent
operation consumes time.

Identify the actual long-running phase and provide truthful
progress reporting, including measured extraction progress where
supported and indeterminate activity feedback otherwise.

Do not fabricate completion percentages.

## 7. ISO footprint optimization

The approximately 7.4 GiB Beta 1 ISO is dominated by its approximately
7.3 GiB SquashFS payload.

Before changing kernel configuration, audit:
- Built-in kernel options versus loadable modules
- Installed kernel module footprint
- Hardware firmware footprint
- Debug files, development artifacts, sources, and caches
- Root filesystem package manifest and release-owned content
- SquashFS compression settings

Make incremental, measured changes and validate QEMU Tier 1,
OVMF/GRUB, installation, and physical hardware boot.

Converting kernel options from built-in to module does not by itself
guarantee smaller ISO media.

## 8. Outstanding validation and release work

- Complete and verify Pavilion installation and first boot.
- Configure and validate Pavilion WireGuard and SSH.
- Perform EliteBook physical Beta 1 installer validation.
- Resolve Pavilion tty1 prompt visibility before public release.
- Diagnose and correct Wi-Fi hardware-discovery failure.
- Correct boot-path collision in replacement installation.
- Add installer launcher and useful progress reporting.
- Verify installer firmware BootOrder handling on multiple systems.
- Integrate ISO creation, checksums, and provenance into the
  canonical release pipeline.
- Establish a distribution method for ISO artifacts exceeding
  GitHub's ordinary repository file-size limits.

All corrective changes must be implemented and validated on the
canonical Z890 SableLinux build pipeline.

## 9. Supplementary installed-system validation — 2026-11-26

The Pavilion is operating an installed SableLinux 1.0 system with
kernel 6.16.1-sable-beta1-test1.

The earlier outstanding first-boot observation is superseded by
verified installed-system operation and subsequent successful reboot.

This does not independently establish that every installer phase or
the previously observed replacement-workflow defect has been resolved.

Verified:

- Persistent machine identity.
- Unique SSH host and user authentication keys.
- Public-key SSH authentication over LAN.
- Recovery after DHCP address change.
- Machine-specific WireGuard credentials.
- Successful WireGuard administrative split tunnel.
- Restricted relay peer forwarding.
- Authenticated SSH over WireGuard.
- SSH and WireGuard automatic startup after physical reboot.

Confirmed networking defects:

- Missing SSH host-key generation service dependency.
- Private deployment configuration and historical backup inherited
  by the release.
- Unavailable IPv6 policy routing.
- Missing xt_comment and xt_connmark support.
- Full-tunnel WireGuard activation failure.
- Running kernel configuration unavailable for inspection.

Temporary split-tunnel administration is accepted for continued
device provisioning. Full-tunnel networking remains unqualified.

IPv6 leak prevention and endpoint firewall hardening remain open.

The earlier Wi-Fi discovery, installer boot-path collision, tty1
presentation and other release findings remain open unless separately
resolved and validated.

Detailed evidence and canonical follow-up:

- docs/journal/2026-11-26.md
- docs/testing/release/networking-validation.md
