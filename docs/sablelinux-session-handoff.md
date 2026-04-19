# SableLinux NVMe Migration — Session Handoff

## Current Situation

SableLinux (LFS 12.4-systemd custom distro) was successfully migrated from a 500GB internal SATA SSD to a WD SN560 1TB NVMe PCIe 4.0. The disk image is confirmed good. The problem is the SableLinux kernel cannot boot from NVMe on this hardware.

**Current state at end of session:**
- SableLinux NVMe drive is installed and has a freshly built kernel (6.17) from Ubuntu's config
- The SATA SSD is also plugged back in as fallback
- GRUB on the SATA drive is broken — grub.cfg was updated to point to 6.17 kernel which doesn't exist on the SATA drive
- Neither drive is currently booting cleanly
- User is accessing from a laptop — the main machine is down

---

## Hardware

- **CPU:** Intel Core Ultra 5 245K (14 cores)
- **RAM:** 32GB DDR5
- **GPU:** AMD RX 9070 XT (RDNA4/gfx1201)
- **Motherboard:** Gigabyte Z890 Aorus Elite X ICE
- **SableLinux NVMe:** WD SN560 1TB PCIe 4.0 — enumerates as nvme0n1 or nvme1n1 (flips between boots)
- **Ubuntu host NVMe:** separate drive, enumerates as whichever nvme# the SableLinux drive isn't
- **SATA SSD:** 500GB, internal, /dev/sda — original SableLinux drive, still has working OS

### NVMe Partition Layout
| Partition | Size | Type | Role |
|-----------|------|------|------|
| p1 | 512M | vfat | EFI |
| p2 | 2G | ext4 | /boot |
| p3 | ~951G | ext4 | / |

- Root UUID: `70148917-ed5a-466c-b71b-444596ca684a`
- /boot UUID: `13816e16-93ea-4e55-9b82-cfbb7946b7a0`

---

## What Has Been Proven

1. **Disk image is intact** — Ubuntu kernel 6.17.0-20-generic booted the SableLinux NVMe root successfully, reaching emergency shell
2. **Userspace is fine** — /home, binaries, all data accessible
3. **NVMe/PCIe path works** — Ubuntu kernel sees and mounts the NVMe without issue
4. **Problem is 100% the SableLinux kernel** — every SableLinux kernel build freezes silently after EFI stub loads initrd
5. **Root cause identified** — original SableLinux kernel config was built for SATA-only system, missing critical options for NVMe/Z890/RDNA4 platform

---

## What's On The NVMe /boot Right Now

```
vmlinuz-6.17-lfs-12.4-systemd      — kernel built from Ubuntu config base (latest build)
initrd.img-6.17-lfs-12.4-systemd   — custom initramfs with findfs UUID mount
config-6.17-lfs-12.4-systemd       — Ubuntu 6.17.0-20-generic config used as base
System.map-6.17-lfs-12.4-systemd
vmlinuz-6.16.1-lfs-12.4-systemd    — old broken kernel, keep for reference
initrd.img-6.16.1-lfs-12.4-systemd — old initramfs
```

---

## Current grub.cfg kernel line (on NVMe)

```
linux /vmlinuz-6.17-lfs-12.4-systemd root=UUID=70148917-ed5a-466c-b71b-444596ca684a ro modprobe.blacklist=amdgpu console=tty0 earlyprintk=efi,keep loglevel=7 nomodeset
initrd /initrd.img-6.17-lfs-12.4-systemd
```

---

## Current initramfs init script

Uses `findfs` to resolve UUID before mounting (updated per ChatGPT recommendation):

```sh
#!/bin/busybox sh
/bin/busybox --install -s /bin
mount -t proc none /proc
mount -t sysfs none /sys
mount -t devtmpfs none /dev 2>/dev/null || true
ROOTDEV="$(findfs UUID=70148917-ed5a-466c-b71b-444596ca684a)"
[ -n "$ROOTDEV" ] || exec sh
mount -o ro "$ROOTDEV" /sysroot || exec sh
umount /proc
umount /sys
exec switch_root /sysroot /sbin/init
```

---

## IMMEDIATE PROBLEM TO FIX FIRST

The SATA SSD GRUB is broken — grub.cfg points to `vmlinuz-6.17-lfs-12.4-systemd` which doesn't exist on the SATA drive. Fix from GRUB command line:

At GRUB prompt, press `c` for command line, then manually boot:

```
set root=(hd0,gpt2)
linux /vmlinuz-6.16.1-lfs-12.4-systemd root=/dev/sda3 ro
initrd /initrd.img-6.16.1-lfs-12.4-systemd
boot
```

If that works, once booted fix grub.cfg permanently:

```bash
sudo sed -i 's/6.17-lfs-12.4-systemd/6.16.1-lfs-12.4-systemd/g' /boot/grub/grub.cfg
```

---

## NVMe Boot Fix — Next Steps

The latest kernel build (6.17 from Ubuntu config) has not been confirmed working yet — it was built at end of session and not tested. Next steps:

### 1. Boot Ubuntu on the host machine
### 2. Mount SableLinux NVMe and chroot
```bash
# Check which nvme is Sable first:
lsblk | grep nvme
# Mount whichever has the SableLinux partitions:
sudo mount /dev/nvme[X]n1p3 /mnt/sable
sudo mount /dev/nvme[X]n1p2 /mnt/sable/boot
sudo mount /dev/nvme[X]n1p1 /mnt/sable/boot/efi
for dir in dev dev/pts proc sys run; do sudo mount --bind /$dir /mnt/sable/$dir; done
sudo chroot /mnt/sable /bin/bash --login
```

### 3. Verify kernel hash
```bash
sha256sum /sources/linux-6.17/arch/x86/boot/bzImage /boot/vmlinuz-6.17-lfs-12.4-systemd
```
These must match. If they don't, copy again:
```bash
cp /sources/linux-6.17/arch/x86/boot/bzImage /boot/vmlinuz-6.17-lfs-12.4-systemd
```

### 4. Verify initramfs has findfs
```bash
zcat /boot/initrd.img-6.17-lfs-12.4-systemd | cpio -t | grep findfs
```
Should show `bin/findfs`. If not, rebuild:
```bash
bash /home/pepper/sablelinux/build/make-initramfs.sh
```

### 5. Boot SableLinux and check result

---

## Known Secondary Issues (fix after stable boot)

1. **amdgpu SMU version mismatch** — RDNA4 firmware version mismatch. Currently blacklisted via `modprobe.blacklist=amdgpu`. Once booting cleanly, remove blacklist and address GPU properly. May need newer firmware blobs.

2. **FAT-fs iso8859-1 charset error** — EFI partition mount warning. Fix by editing `/etc/fstab` vfat entry to remove `iocharset=iso8859-1` or use `utf8` instead. Or add `CONFIG_NLS_ISO8859_1=y` to kernel config.

3. **NVMe enumeration flip** — nvme0n1/nvme1n1 swap between boots. Not a functional problem since GRUB and initramfs use UUIDs. Can be stabilized via BIOS boot device priority settings.

4. **sable-init hardcoded device paths** — previously had `/dev/sda3` hardcoded, now fixed to use findfs UUID. This was a contributing factor to earlier failures.

---

## Key Build Parameters

- **Always:** `make -j14`
- **Kernel source:** `/sources/linux-6.17/`
- **initramfs script:** `/opt/initramfs-tools/sable-init`
- **initramfs builder:** `/home/pepper/sablelinux/build/make-initramfs.sh`
- **Modules:** installed to `/lib/modules/6.17.0/`
- **Compiler:** GCC 15.2.0 (Ubuntu uses GCC 13 — potential ABI difference)

---

## Standard Chroot Sequence

```bash
sudo mount /dev/nvme[X]n1p3 /mnt/sable
sudo mount /dev/nvme[X]n1p2 /mnt/sable/boot
sudo mount /dev/nvme[X]n1p1 /mnt/sable/boot/efi
for dir in dev dev/pts proc sys run; do sudo mount --bind /$dir /mnt/sable/$dir; done
sudo chroot /mnt/sable /bin/bash --login
```

## Standard Unmount Sequence

```bash
sudo umount /mnt/sable/dev/pts
sudo umount /mnt/sable/dev
sudo umount /mnt/sable/proc
sudo umount /mnt/sable/sys
sudo umount /mnt/sable/run
sudo umount /mnt/sable/boot/efi
sudo umount /mnt/sable/boot
sudo umount /mnt/sable
```
