# SableLinux NVMe Boot Issue — Full Context Prompt

## Situation Summary

I have a custom Linux distribution called SableLinux, built from scratch using Linux From Scratch (LFS) 12.4-systemd. I just migrated it from a 500GB internal SATA SSD (/dev/sda) to a new 1TB WD SN560 NVMe SSD (now enumerating as /dev/nvme1n1). The system boots GRUB fine, loads the kernel and initrd, but then freezes completely — no further output, no login prompt, requires hard power-off.

---

## Hardware

- **CPU:** Intel Core Ultra 5 245K (14 cores)
- **RAM:** 32GB DDR5
- **GPU:** AMD RX 9070 XT (RDNA4/gfx1201)
- **Motherboard:** Gigabyte Z890 Aorus Elite X ICE
- **Boot drive:** WD SN560 1TB M.2 PCIe 4.0 NVMe — /dev/nvme1n1
  - nvme1n1p1: 512M vfat — EFI
  - nvme1n1p2: 2G ext4 — /boot
  - nvme1n1p3: ~951G ext4 — / (UUID: 70148917-ed5a-466c-b71b-444596ca684a)
- **Host OS drive:** Ubuntu 24.04 on nvme0n1 (separate NVMe, system runs fine)

---

## What Was Done

1. Took partclone/dd backups of the working SATA SSD (sda1/2/3)
2. Partitioned the new NVMe with gdisk (same layout: EFI/boot/root)
3. Restored all three partitions:
   - EFI + boot via `dd`
   - Root via `partclone.restore`
4. Chrooted into the restored system from Ubuntu host
5. Ran `grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=SableLinux --no-nvram`
6. Ran `grub-mkconfig -o /boot/grub/grub.cfg`
7. Verified UUID in grub.cfg matches nvme1n1p3 ✓
8. Registered EFI boot entry via efibootmgr
9. Discovered `CONFIG_BLK_DEV_NVME is not set` in kernel config — NVMe support was absent
10. Rebuilt kernel 6.16.1 with `CONFIG_BLK_DEV_NVME=y` (built-in)
11. Updated custom initramfs init script to mount `/dev/nvme1n1p3` instead of `/dev/sda3`
12. Rebuilt initramfs

**Still freezing after kernel + initrd load.**

---

## Kernel

- Version: 6.16.1-lfs-12.4-systemd
- Custom kernel config, originally built for SATA-only boot
- NVMe now built-in (`CONFIG_BLK_DEV_NVME=y`) after rebuild
- No initramfs auto-generation (no dracut, no mkinitcpio) — custom hand-rolled initramfs

---

## Custom Initramfs

SableLinux uses a completely hand-rolled initramfs with a minimal busybox-based init script. There is no dracut, no mkinitcpio, no update-initramfs. The initramfs is built by a custom bash script (`make-initramfs.sh`) which packages busybox binaries + firmware + a hand-written init script into a cpio.gz.

**Current init script (`/opt/initramfs-tools/sable-init`):**
```sh
#!/bin/busybox sh
/bin/busybox --install -s /bin
mount -t proc none /proc
mount -t sysfs none /sys
mount -t devtmpfs none /dev 2>/dev/null || true
echo "Waiting for NVMe..."
sleep 3
echo "Mounting root..."
mount -o ro /dev/nvme1n1p3 /sysroot
echo "Mount done, switching root..."
umount /proc
umount /sys
exec switch_root /sysroot /sbin/init
EOF
```

**Confirmed via `cpio -t` extraction that the built initramfs contains exactly this script.**

The debug echo lines ("Waiting for NVMe...", "Mounting root...", "Mount done...") do NOT appear on screen during boot — the system freezes before or at EFI stub messages, suggesting the hang may be occurring even before the init script runs, OR the console output is not visible.

---

## Boot Screen Output (what's visible)

```
Loading Linux 6.16.1-lfs-12.4-systemd ...
Loading initial ramdisk ...
EFI stub: Loaded initrd from LINUX_EFI_INITRD_MEDIA_GUID device path
EFI stub: Measured initrd data into PCR 9
[FREEZE — no further output]
```

The system freezes here every time. Requires hard power-off.

---

## What We've Ruled Out

- GRUB config is correct — UUIDs match, kernel/initrd paths correct
- Partition restore was successful — `file -s /dev/nvme1n1p3` confirms clean ext4 with correct UUID
- NVMe kernel support is now built-in (confirmed CONFIG_BLK_DEV_NVME=y after rebuild)
- initramfs contains correct device path (nvme1n1p3)
- mdev -s was removed from init script (was causing hangs on previous SATA boot attempts too)
- Boot order is not the issue — manually selecting SableLinux via F12 UEFI boot menu

---

## Key Suspicion

The freeze happens at or immediately after EFI stub loads the initrd — before any init script output appears. This suggests the kernel itself may be panicking or hanging during early init, before userspace (the init script) even runs. Possible causes:

1. **Kernel parameter issue** — missing `root=` or incorrect console/earlycon setup preventing kernel messages from appearing
2. **Missing kernel module/driver** — something else besides NVMe that's needed for early boot that was previously handled by the SATA path
3. **initramfs extraction failure** — kernel can't decompress or execute the initramfs
4. **Silent kernel panic** — no console output configured so panic is invisible

---

## grub.cfg kernel line

```
linux /vmlinuz-6.16.1-lfs-12.4-systemd root=UUID=70148917-ed5a-466c-b71b-444596ca684a ro
```

No `console=`, no `earlycon`, no `earlyprintk`.

---

## Questions for ChatGPT

1. Given the freeze immediately after EFI stub loads initrd with no further console output, what is the most likely cause?
2. Should I add `console=tty0 earlyprintk=vga` or similar kernel parameters to get visibility into what's happening?
3. Could the kernel be panicking silently because of a missing driver or config option beyond NVMe?
4. Is there anything in the hand-rolled initramfs setup that could cause a silent freeze at this stage?
5. What other kernel config options are commonly needed for NVMe boot that might be missing (e.g. PCIe, AHCI, scheduler, etc.)?
6. How can I verify the rebuilt kernel bzImage actually has NVMe support compiled in without booting it?
