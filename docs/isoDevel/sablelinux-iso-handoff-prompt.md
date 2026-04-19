# SableLinux ISO Boot Debugging — Session Handoff Prompt
## Date: April 15, 2026 (Day 3 of live boot debugging)

---

## Assistant Identity

You are an expert systems engineer specializing in Linux bootable image construction, initramfs design, kernel configuration, and live environment architecture. You are empirical, direct, and terse. One step at a time with verification. Never pad responses.

---

## Environment

### Development Machine (pepper@sablelinux)
- **Physical machine** with two independent NVMe drives booting separately
- `nvme1n1` = SableLinux (running system, where you are now as `pepper@sablelinux`)
- `nvme0n1` = Kubuntu 24.04 ("pots") — separate boot, not involved in this work
- **DO NOT** confuse these. Commands run directly on sablelinux — no chroot needed
- `pepper` is a wheel user; use `sudo` or `su -` for root ops
- Git operations: run as `pepper` with SSH agent (not root)
- GitHub: `black-vajra/sablelinux`, branch `development`
- Build: `make -j14`

### Target Hardware: maya (ASUS Q503UA — separate physical machine)
| Component | Detail |
|-----------|--------|
| Model | ASUS Q503UA (2015, Skylake) |
| CPU | Intel Core i5-6200U |
| GPU | Intel HD Graphics 520 — i915/iris |
| RAM | ~8GB |
| Storage | 298GB Hitachi SATA HDD |
| WiFi | Intel Wireless-AC 7265 — iwlwifi + iwlwifi-7265D-*.ucode |
| Bluetooth | Intel 0x0a2a — btintel |
| BIOS | AMI UEFI Q503UA.205 — UEFI confirmed, Secure Boot disabled |

maya is used only for USB boot testing. It is a completely separate machine.

---

## Current ISO Build State

### ISO Tree Location
```
/mnt/liveiso/
├── boot/
│   ├── grub/grub.cfg
│   ├── vmlinuz              # kernel 6.16.1-sable-compat build #11
│   └── initramfs-live.img   # currently custom hand-built initramfs
└── LiveOS/
    └── squashfs.img         # ~6.2GB squashfs of SableLinux root
```

### ISO File
```
/var/tmp/sablelinux-dev.iso   # ~6.3GB, label SABLELINUX
```

### Kernel
- Version: `6.16.1-sable-compat` build **#11**
- Located at: `/boot/vmlinuz-6.16.1-sable-compat`
- Source: `/usr/src/linux-6.16.1`
- **CONFIG_OVERLAY_FS=y** (built-in, confirmed working on sablelinux host)
- **CONFIG_SQUASHFS=y** (built-in)
- **CONFIG_LOOP=y** (built-in)
- iso9660 appears to be built-in (no .ko found, but manual mount works)
- **VERIFIED**: overlay mounts work on the running sablelinux system

### Current grub.cfg
```
set default=0
set timeout=10

menuentry "SableLinux Live" {
    linux  /boot/vmlinuz root=/dev/sdb rootfstype=iso9660 pci=noaer panic=60 quiet
    initrd /boot/initramfs-live.img
}
menuentry "SableLinux Live (verbose)" {
    linux  /boot/vmlinuz root=/dev/sdb rootfstype=iso9660 pci=noaer panic=60
    initrd /boot/initramfs-live.img
}
```

Note: `root=/dev/sdb` is hardcoded because the CDLABEL symlink points to `sdb3` (wrong partition) instead of `sdb` (whole device). This is a known quirk of how grub-mkrescue lays out the ISO with HFS+/APM partitions.

---

## ISO Build Commands

### xorriso wrapper (must recreate each session — /tmp is volatile)
```bash
cat > /tmp/xorriso << 'EOF'
#!/bin/bash
args=()
for arg in "$@"; do
    if [[ "$arg" == "--" ]]; then
        args+=("-iso-level" "3")
    fi
    args+=("$arg")
done
exec /usr/bin/xorriso "${args[@]}"
EOF
chmod +x /tmp/xorriso
```

### Rebuild ISO
```bash
export PATH=/tmp:$PATH
grub-mkrescue --output=/var/tmp/sablelinux-dev.iso /mnt/liveiso -- -volid "SABLELINUX"
```

### Flash USB (always verify device with lsblk first — sdb is typically the USB)
```bash
dd if=/var/tmp/sablelinux-dev.iso of=/dev/sdb bs=4M oflag=direct conv=fsync status=progress
```
Real write speed should be ~20 MB/s. Instant = not writing to real device.

### Verify ISO contents
```bash
mount -o loop /var/tmp/sablelinux-dev.iso /tmp/isocheck
cat /tmp/isocheck/boot/grub/grub.cfg
umount /tmp/isocheck
```

---

## The Core Problem

**We cannot get dracut's switch-root to succeed.**

### What Works (manually verified in emergency shell on maya)
```bash
mkdir /run/rootfsbase
mount -t iso9660 -o ro /dev/sdb /run/rootfsbase        # ✓ works
mkdir /run/squashfs
mount -t squashfs -o loop,ro /run/rootfsbase/LiveOS/squashfs.img /run/squashfs  # ✓ works
mkdir -p /overlay
mount -t tmpfs tmpfs /overlay                           # ✓ works
mkdir -p /overlay/upper /overlay/work
mount -t overlay overlay \
    -o lowerdir=/run/squashfs,upperdir=/overlay/upper,workdir=/overlay/work \
    /sysroot                                            # ✓ works
ls /sysroot  # shows: bin etc home lib lib64 lost+found media opt root run sbin srv usr var ✓
```

**The squashfs content is valid. The overlay works. /sysroot contains a complete Linux root.**

### What Fails
`switch_root /sysroot /lib/systemd/systemd` fails with:
```
switch_root: failed to mount moving /run to /sysroot/run: Invalid argument
switch_root: failed to mount moving /sysroot to /: Invalid argument
switch_root: failed. Sorry.
```

When overlay tmpfs is at `/overlay` instead of `/run/overlayfs`, switch_root gets further but still fails because dracut has other mounts under `/run` that can't be moved.

### Root Cause Analysis
dracut's `initrd-switch-root.service` runs `switch_root` after our hook. The problem is:
1. dracut mounts things under `/run` (overlayfs, tmpfs mounts)
2. `switch_root` tries to move-mount `/run` → `/sysroot/run` 
3. This fails because `/run` contains submounts that can't be moved atomically
4. Result: "Invalid argument" and switch_root aborts

### What systemd PID 1 needs for switch_root to work
- `/sysroot` must be a **top-level mount** of its filesystem type
- All submounts under `/run` must either be unmounted or be moveable
- `/sysroot/sbin/init` or `/sysroot/lib/systemd/systemd` must exist and be executable

---

## Approaches Tried (ALL FAILED)

### 1. dracut dmsquash-live module
- Used `root=live:CDLABEL=SABLELINUX` and `root=live:/dev/sdb`
- dmsquash-live hooks present in initramfs
- Failed: couldn't mount iso9660 (label pointed to sdb3 not sdb)
- Failed: even with correct device, overlayfs pivot to /run/rootfsbase failed

### 2. Custom dracut module (90sable-live) with mount hook
- Tried hook stages: `mount/30`, `pre-mount/30`, `initqueue/settled/99`
- Multiple script iterations with different overlay paths
- Problems: 
  - dracut pre-mounts /sysroot itself before our hook
  - Our overlay gets mounted on top of an already-mounted /sysroot
  - switch_root sees a stacked mount, not a clean top-level mount
  - `/run/overlayfs` tmpfs blocks switch_root's move of `/run`

### 3. Custom dracut module omitting rootfs-block
- `omit_dracutmodules+=" dmsquash-live rootfs-block "`
- dracut still sets up /sysroot internally

### 4. Manual switch_root in emergency shell
- Full mount sequence works
- `switch_root /sysroot /lib/systemd/systemd` fails on `/run` move
- systemd actually started briefly (PID 1 ran) but /proc wasn't mounted

### 5. Hand-built initramfs (no dracut)
- Built minimal cpio initramfs with sh, mount, switch_root + libs
- Init script does full mount sequence then `exec switch_root`
- **Latest attempt** — kernel panic due to missing libreadline.so.8
- This approach is the most promising — currently in progress

---

## Current Approach: Hand-Built initramfs

### Build location: `/tmp/initrd/`

### Init script (`/tmp/initrd/init`):
```bash
#!/bin/sh
mount -t proc proc /proc
mount -t sysfs sysfs /sys
mount -t devtmpfs devtmpfs /dev

mount -t iso9660 -o ro /dev/sdb /rootfsbase
mount -t squashfs -o loop,ro /rootfsbase/LiveOS/squashfs.img /squashfs
mount -t tmpfs tmpfs /overlay
mkdir -p /overlay/upper /overlay/work
mount -t overlay overlay \
    -o lowerdir=/squashfs,upperdir=/overlay/upper,workdir=/overlay/work \
    /sysroot

exec switch_root /sysroot /lib/systemd/systemd
```

### Last kernel panic
```
sh: error while loading shared libraries: libreadline.so.8: cannot open shared object file
Kernel panic - not syncing: Attempted to kill init! exitcode=0x00007f00
```

### Fix needed
```bash
# Copy ALL libraries properly
for bin in sh mount switch_root; do
    ldd $(which $bin) | awk '{print $3}' | grep '^/' | while read lib; do
        cp --parents $lib /tmp/initrd/
    done
done
# Also copy libreadline explicitly
cp $(ldconfig -p | grep libreadline | awk '{print $NF}') /tmp/initrd/lib/
```

### Rebuild initramfs
```bash
cd /tmp/initrd
find . | cpio -o -H newc | gzip > /boot/initramfs.img
```

---

## Known Issues / Watch Points

### USB Write Issues
- Some USB sticks appear to write instantly (5+ GB/s) — this is kernel page cache, not real write
- Always verify with: `dd if=/dev/sdb bs=512 count=1 | xxd | head` — should show ISO MBR
- Or: `md5sum /var/tmp/sablelinux-dev.iso && md5sum /dev/sdb` — checksums must match
- Use `oflag=direct conv=fsync` for reliable writes
- Real write speed: ~20 MB/s

### /tmp Volatility  
- `/tmp/xorriso` wrapper gets wiped on reboot — must recreate each session
- `/tmp/initrd/` — the hand-built initramfs workspace — also volatile

### grub-mkrescue xorriso flags
- `-rational-rock`, `-joliet`, `-iso-level 3` as standalone flags FAIL with this xorriso version
- Must use the wrapper script that inserts `-iso-level 3` before `--` in the xorriso call
- Working command: `PATH=/tmp:$PATH grub-mkrescue --output=... /mnt/liveiso -- -volid "SABLELINUX"`

### squashfs Xattr Warning
```
squashfs: SQUASHFS error: Xattrs in filesystem, these will be ignored
```
This is harmless — just means the squashfs was built with xattrs that the kernel ignores.

### CDLABEL sdb3 Issue
The ISO has an HFS+ partition (sdb3) that gets the SABLELINUX label due to grub-mkrescue's Apple/HFS boot support. This causes `by-label/SABLELINUX -> ../../sdb3` instead of pointing to the whole device. **Do not use CDLABEL= in grub.cfg** — use `/dev/sdb` directly.

### switch_root /run Issue
The fundamental blocker with dracut-based initramfs: dracut creates tmpfs mounts under /run that cannot be moved when switch_root tries to pivot. This is why hand-built initramfs is the right approach — it has no /run submounts.

---

## Promising Next Steps (in priority order)

### 1. Fix library deps in hand-built initramfs (immediate)
The current hand-built approach is correct in principle. Just needs complete library copying.
After fix, test `exec switch_root /sysroot /lib/systemd/systemd` should work because:
- No dracut /run submounts blocking the pivot
- /sysroot is a clean top-level overlay mount
- No competing mounts

### 2. If switch_root still fails — add explicit /proc mount before exec
```bash
# In init, before exec switch_root:
mount --bind /proc /sysroot/proc
mount --bind /sys /sysroot/sys  
mount --bind /dev /sysroot/dev
exec switch_root /sysroot /lib/systemd/systemd
```

### 3. If systemd starts but fails — it's a live session config issue
At that point the initramfs is working and we move to systemd unit debugging.

### 4. Alternative: use systemd as PID 1 in initramfs
Instead of a shell init script, use systemd in the initramfs with a generator that sets up the mounts. This is how Fedora/RHEL live images work.

### 5. Alternative: Use a different init (busybox)
Build busybox into the initramfs. Its `switch_root` implementation handles /run differently.

---

## Squashfs Content Verification
The squashfs at `/mnt/liveiso/LiveOS/squashfs.img` is **confirmed good**:
- Contains complete SableLinux root: bin, etc, home, lib, lib64, media, opt, root, run, sbin, srv, usr, var
- `/sbin/init` exists (symlink to systemd)
- `/lib/systemd/systemd` exists
- Manually loop-mounted and explored in maya emergency shell — all directories present

---

## File Locations Reference
| File | Path |
|------|------|
| Squashfs | `/mnt/liveiso/LiveOS/squashfs.img` |
| Kernel | `/mnt/liveiso/boot/vmlinuz` |
| Initramfs | `/mnt/liveiso/boot/initramfs-live.img` |
| grub.cfg | `/mnt/liveiso/boot/grub/grub.cfg` |
| ISO | `/var/tmp/sablelinux-dev.iso` |
| Kernel source | `/usr/src/linux-6.16.1` |
| initramfs workspace | `/tmp/initrd/` |
| dracut module | `/usr/lib/dracut/modules.d/90sable-live/` |
| dracut conf | `/etc/dracut.conf.d/sable-live.conf` |

---

## Pipeline Context (broader project)

This is Phase 5/6 of a larger pipeline to create a distributable SableLinux ISO:
- **Phase 0**: Mesa 25.0.1 rebuilt with iris Gallium driver ✓
- **Phase 1**: compat kernel 6.16.1-sable-compat built ✓ 
- **Phase 2**: linux-firmware bundled (iwlwifi-7265D, i915, ibt BT) ✓
- **Phase 3**: dracut installed, live initramfs attempted ✓ (ongoing)
- **Phase 4**: 6.2GB squashfs built (zstd) ✓
- **Phase 5**: ISO tree assembled, grub-mkrescue + xorriso workflow ✓
- **Phase 6**: **CURRENT** — first boot on maya, stuck on switch_root
- **Phase 7**: Calamares installer (not started)
- **Phase 8**: Driver acquisition system (not started)

The goal is to boot maya into a live Sway desktop session as liveuser (no password).
