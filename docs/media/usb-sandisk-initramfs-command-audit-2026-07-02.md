# USB SanDisk Initramfs Command Audit — 2026-07-02

Thu Jul  2 11:56:29 AM EDT 2026

## BusyBox binary
/tmp/sable-initramfs-inspect/bin/busybox: ELF 64-bit LSB executable, x86-64, version 1 (GNU/Linux), statically linked, BuildID[sha1]=351ba74c282274bdd56e030c641d226cab5c14b7, for GNU/Linux 3.2.0, stripped
BusyBox v1.36.1 (Ubuntu 1:1.36.1-6ubuntu3.1) multi-call binary.
BusyBox is copyrighted by many authors between 1998-2015.
Licensed under GPLv2. See source distribution for detailed
copyright notices.


## BusyBox applets required by init script
sh           present
mount        present
mkdir        present
sleep        present
findfs       present
mdev         present
switch_root  present
echo         present

## Full relevant applet list
ash
cat
dmesg
echo
findfs
insmod
ls
mdev
mkdir
modprobe
mount
sh
sleep
switch_root

## Init script
#!/bin/busybox sh
/bin/busybox --install -s /bin

mount -t proc none /proc
mount -t sysfs none /sys
mount -t devtmpfs none /dev 2>/dev/null || true
mkdir -p /dev/pts
mount -t devpts none /dev/pts
mdev -s

echo "SableLinux Live Boot..."
sleep 3

mkdir -p /mnt/scan
ROOTDEV=""
for i in 1 2 3 4 5; do
    ROOTDEV=$(findfs LABEL=SABLELINUX 2>/dev/null)
    [ -n "$ROOTDEV" ] && break
    echo "Waiting for device... attempt $i"
    sleep 2
done

if [ -z "$ROOTDEV" ]; then
    echo "ERROR: cannot find SABLELINUX partition"
    exec sh
fi

echo "Found $ROOTDEV"
mount -t ext4 -o ro "$ROOTDEV" /mnt/scan || exec sh

mkdir -p /mnt/squashfs
mount -t squashfs -o loop /mnt/scan/live/filesystem.squashfs /mnt/squashfs || exec sh

mkdir -p /mnt/overlay /mnt/rootfs
mount -t tmpfs tmpfs /mnt/overlay
mkdir -p /mnt/overlay/upper /mnt/overlay/work
mount -t overlay overlay \
    -o lowerdir=/mnt/squashfs,upperdir=/mnt/overlay/upper,workdir=/mnt/overlay/work \
    /mnt/rootfs || exec sh

mkdir -p /mnt/rootfs/proc /mnt/rootfs/sys /mnt/rootfs/dev /mnt/rootfs/dev/pts
mount --move /proc /mnt/rootfs/proc
mount --move /sys /mnt/rootfs/sys
mount --move /dev /mnt/rootfs/dev

echo "Pivoting to live root..."
exec switch_root /mnt/rootfs /sbin/init

## Initramfs cpio list: required binaries/symlinks
bin/switch_root
bin/busybox

## Kernel support hints from host kernel config if available

--- /proc/config.gz ---
missing

--- /boot/config-6.16.1-sable-compat ---
missing

--- /usr/src/linux-6.16.1/.config ---
CONFIG_DEVTMPFS=y
CONFIG_BLK_DEV_LOOP=y
CONFIG_EXT4_FS=y
CONFIG_OVERLAY_FS=y
CONFIG_TMPFS=y
CONFIG_SQUASHFS=y
