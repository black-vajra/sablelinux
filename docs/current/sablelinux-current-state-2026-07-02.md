# SableLinux Current State — 2026-07-02

## Purpose

This document records the verified working state at the start of the July 2026 cleanup/organization pass.

The goal of this pass is not package upgrading. The goal is to clarify the current source of truth, separate historical notes from active engineering files, and prepare for comparison against the EliteBook install media/backups.

## Current Working Assumption

The local Z890 SableLinux install is a working/reference system, but not necessarily the most current install-media target.

Recent install/live media work has been happening on individual live-boot/install disk variants and backup trees, not consistently on the local installed root.

The EliteBook install and existing install disks/backups may contain driver and hardware-support updates not replicated on the Z890 system.

## Verified Local System

Host: SableLinux  
OS: Sable Linux 1.0  
Kernel: 6.16.1-sable-compat  
Primary repo: /home/pepper/sablelinux  
Branch: development  
Remote: git@github.com:black-vajra/sablelinux.git  

Root filesystem:
- /dev/nvme1n1p3 mounted on /
- ext4
- large free space available

Boot filesystem:
- /dev/nvme1n1p2 mounted on /boot
- ext4
- healthy enough for current work

## Repository State

As of verification:
- Branch: development
- Remote tracking: origin/development
- Latest commit: 4d078a0
- Commit subject: Fix waybar-missing-on-install: PAM file descriptor limits regression in system-auth

## BUILDLOG Cleanup Status

BUILDLOG.md previously contained committed merge-conflict markers around the June 17/18 Waybar/audio entries.

Resolved during the 2026-07-02 cleanup pass.

Both valid sections were preserved:
- Waybar Still Missing on Installed System — Unresolved — 2026-06-17 (late)
- Audio Jack/HDMI Fix — HP Pavilion (sable-hp) — 2026-06-18

BUILDLOG.md may now be treated as authoritative again after normal review.

## PAM / Waybar Fix State

### Running Z890 System

Verified working:
- /etc/pam.d/system-auth includes pam_limits.so
- /etc/pam.d/system-session includes pam_limits.so
- ulimit -n reports 65536
- waybar is installed and running

### Live-root Staging Trees

Verified state:

| Tree | Waybar present | PAM file descriptor fix |
|---|---:|---:|
| /mnt/liveroot | yes | no |
| /mnt/liveroot-clean | yes | no |
| /mnt/liveroot-edit | yes | no |
| /mnt/liveroot-glk | yes | no |
| /mnt/liveroot-agno1 | yes | yes |

Important correction: `/mnt/liveroot-agno1` must not be treated as the successful EliteBook install source. It is believed to be part of the attempt to recover or reconstruct the broken live-boot/install USB path. Its PAM/Waybar state is useful evidence, but it does not establish release lineage.

Do not assume `/mnt/liveroot`, `/mnt/liveroot-agno1`, or any other `/mnt/liveroot*` tree is the current release root until the USB media, backups, and EliteBook install are inventoried and compared.

Do not rebuild ISO media until the intended canonical live-root tree is explicitly selected.

## Known Active Engineering Issues

1. BUILDLOG.md conflict markers resolved during 2026-07-02 cleanup pass.
2. Current canonical live/install root must be selected.
3. `/mnt/liveroot-agno1` must be classified as a recovery/reconstruction attempt unless later evidence proves otherwise.
4. Live/install media variants need inventory.
5. EliteBook install state at 192.168.0.240 needs comparison later.
6. May 5 backup media should be treated as likely important recovery baseline until verified.
6. LUKS install path remains deferred unless cryptsetup is added to initramfs.
7. Documentation must separate current authority from historical handoff notes.

## Forward Source of Truth

Until further verification:

1. Git commit history
2. Running system inspection
3. Explicitly inventoried live/install media
4. BUILDLOG.md after 2026-07-02 conflict-marker cleanup
5. Historical docs only as evidence, not current state

## Immediate Next Steps

1. BUILDLOG.md conflict markers cleaned without losing either valid entry.
2. Inventory repository documents and classify current vs historical.
3. Inventory /mnt live-root and ISO staging directories.
4. Create a live-media comparison checklist for the later EliteBook/library session.
5. Commit documentation cleanup before changing installer or live-root content.



## Newly Identified External State

### Broken USB live/install disks

Correction: the USB live/install disks were not connected during the first attempted USB inspection.

The attempted `/dev/sdb` inspection on 2026-07-02 was invalid because `/dev/sdb` was the 4.5T encrypted backup disk, not a USB installer.

No USB live/install disk has been inventoried yet.

Next verification must identify USB media by fresh `lsblk` before/after comparison and preferably by `/dev/disk/by-id`, not by assuming `/dev/sdb`.

### Backup volume

Backup disk was unlocked manually:

- LUKS device: /dev/sdb1 at time of unlock
- Mapper name: /dev/mapper/volume01
- Mounted at: /mnt/one
- Backup directory: /mnt/one/backups

Observed backup contents include:

- disk_identity_map.txt
- iso/
- Kubuntu-drive-2026-05-11.bin
- Kubuntu-drive.bin
- kubu-system/
- sable-system/
- system.img
- WD-drive.bin

Sable-specific backup directories observed:

- /mnt/one/backups/sable-system/sable-nvme-04-23
- /mnt/one/backups/sable-system/sable-nvme-05-03
- /mnt/one/backups/sable-system/sable-nvme-05-09

### EliteBook

EliteBook is reachable on the LAN:

- IP: 192.168.0.240
- ICMP ping: working
- known_hosts indicates prior SSH service on port 2269
- standard SSH port 22 is not assumed usable

Next verification: scan/check TCP 2269, then run read-only inventory over SSH if authentication works.


## Verified USB Media — SanDisk live/install candidate

A real USB live/install candidate was verified after correcting the earlier `/dev/sdb` mistake.

Device:

- `/dev/sdc`
- Model: SanDisk 3.2Gen1
- Removable: yes
- Serial begins: `040114997484dd91867594c3905f3e...`

Partitions:

- `/dev/sdc1`: 100M vfat, label `EFI`, UUID `5CF9-CEE9`
- `/dev/sdc2`: 14.5G ext4, label `SABLELINUX`, UUID `ad38f580-763e-49cc-aa40-7316afd804c0`

Observed files:

- `/EFI/BOOT/BOOTX64.EFI` dated 2026-05-03
- `/boot/initramfs-live.img` dated 2026-05-05
- `/boot/vmlinuz` dated 2026-06-12
- `/live/filesystem.squashfs` dated 2026-06-18

Initial assessment:

- USB has coherent live-media structure.
- No visible `grub.cfg` was found on the mounted USB partitions.
- No visible `sable-install` exists outside the squashfs.
- Further inspection must examine bootloader embedded configuration and squashfs contents.

## Reconstructed USB Lineage — Working Hypothesis

The current SanDisk live/install USB should be treated as a downstream reconstruction artifact, not as the release source of truth.

Working lineage:

1. EliteBook had a working SableLinux install.
2. An ISO/live image was reconstructed from that installed system.
3. The SanDisk live/install USB was built from that reconstructed image.
4. The current USB may therefore contain partial or inconsistent reconstruction state.

This means the EliteBook install is currently the most important candidate source of truth for the live/install media recovery process.

## SanDisk USB Initramfs Audit — 2026-07-02

The SanDisk USB initramfs was inspected read-only.

Verified:

- BusyBox is present and statically linked.
- Required initramfs applets are present:
  - sh
  - mount
  - mkdir
  - sleep
  - findfs
  - mdev
  - switch_root
  - echo
- Init script searches for `LABEL=SABLELINUX`.
- Init script mounts `/live/filesystem.squashfs`.
- The USB has that label and path.
- Host kernel config confirms support for:
  - CONFIG_DEVTMPFS=y
  - CONFIG_BLK_DEV_LOOP=y
  - CONFIG_EXT4_FS=y
  - CONFIG_OVERLAY_FS=y
  - CONFIG_TMPFS=y
  - CONFIG_SQUASHFS=y

Assessment:

The SanDisk USB's basic live-initramfs mechanics appear coherent. Current evidence does not support a missing-BusyBox-applet root cause.

Remaining likely USB issues:

1. EFI/GRUB boot configuration problem.
2. Userspace issue after switch_root.
3. Missing installer tooling inside the reconstructed squashfs.
4. Kernel/initramfs/squashfs date mismatch.
5. Hardware-specific boot behavior on ASUS or EliteBook.

Next source of truth to inspect: EliteBook install at 192.168.0.240 over SSH port 2269.

## EliteBook SSH User Correction

The EliteBook SSH service is reachable at:

- Host: 192.168.0.240
- Port: 2269
- SSH user: sable
- Hostname: vulfen
- Kernel observed: 6.16.1-sable-compat2

Earlier attempts using `pepper@192.168.0.240` failed because the account name was wrong.

## EliteBook Inventory Finding — 2026-07-02

EliteBook install was inventoried over SSH.

Verified:

- Hostname: vulfen
- SSH user: sable
- Kernel: 6.16.1-sable-compat2
- Root filesystem: ext4 ROOT on /dev/nvme0n1p3
- Boot image: /vmlinuz-6.16.1-sable-compat2
- Waybar is running as `waybar -b bar-0`

Important finding:

The EliteBook does not currently have the PAM nofile fix that was required on the Z890/VM test path:

- `/etc/pam.d/system-auth` lacks `pam_limits.so`
- `/etc/pam.d/system-session` lacks `pam_limits.so`
- `/etc/security/limits.d/99-filedesc.conf` is missing
- observed shell `ulimit -n` is 1024

Assessment:

The PAM nofile fix remains valid for the Z890/VM regression where Waybar failed with “Too many open files,” but the EliteBook proves that missing PAM limits is not a universal explanation for every missing-Waybar case.

The stronger release-engineering issue is lineage mismatch:

- EliteBook working install boots `6.16.1-sable-compat2`.
- SanDisk live USB carries older/mixed boot artifacts and a later reconstructed squashfs.
- SanDisk USB should remain classified as a downstream reconstruction artifact, not a source of truth.

## SanDisk 03005503013026003502 Backup / Reuse Decision

SanDisk USB serial `03005503013026003502` was inventoried read-only before reuse.

Observed:

- GPT device with EFI partition and SABLELINUX ext4 partition.
- `/boot/vmlinuz`, `/boot/initramfs-live.img`, and `/live/filesystem.squashfs` present.
- Squashfs creation time: 2026-05-05.
- This is an older live-media construction, distinct from the later reconstructed June SanDisk state.
- Home-level Sway and Waybar configs exist inside the squashfs.

Decision:

This USB may be reused for the next EliteBook-derived live USB build only after a compressed full-device image backup has been created and verified.
