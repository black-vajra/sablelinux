#!/bin/busybox sh
set -eu
export PATH=/bin LC_ALL=C LD_LIBRARY_PATH=/usr/lib:/usr/lib64

/bin/busybox --install -s /bin
trap 'echo SABLE_GUEST_INSTALL_FAIL; poweroff -f' EXIT
mount -t proc proc /proc
mount -t sysfs sysfs /sys
mount -t devtmpfs devtmpfs /dev
exec >/dev/console 2>&1

i=0
while [ ! -b /dev/vda ] || [ ! -b /dev/vdb ]; do
    i=$((i + 1))
    [ "$i" -lt 10 ]
    sleep 1
done
[ "$(cat /sys/block/vda/ro)" = 1 ]
[ "$(cat /sys/block/vdb/ro)" = 0 ]
[ "$(cat /sys/block/vdb/size)" = 1310720 ]
[ ! -e /sys/block/vdb/vdb1 ]
[ ! -e /sys/block/vdb/vdb2 ]
mount -t ext4 -o ro /dev/vda /source
(cd /source && sha256sum -c payload.sha256)

sgdisk --clear \
    --new=1:2048:+64M --typecode=1:ef00 --change-name=1:SABLEINSTEFI \
    --new=2:133120:+512M --typecode=2:8300 --change-name=2:SABLEINSTROOT \
    --partition-guid="2:$(cat /root-partuuid)" /dev/vdb
sgdisk --verify /dev/vdb
if [ ! -b /dev/vdb1 ] || [ ! -b /dev/vdb2 ]; then
    blockdev --rereadpt /dev/vdb
fi

i=0
while [ ! -b /dev/vdb1 ] || [ ! -b /dev/vdb2 ]; do
    i=$((i + 1))
    [ "$i" -lt 10 ]
    sleep 1
done
[ "$(cat /sys/class/block/vdb1/size)" = 131072 ]
[ "$(cat /sys/class/block/vdb2/size)" = 1048576 ]

mkfs.fat -F 32 -n SABLEINST /dev/vdb1
mkfs.ext4 -L SABLETESTROOT /dev/vdb2
mount -t ext4 /dev/vdb2 /target
mount -t vfat /dev/vdb1 /esp

if [ -x /bin/check-install-metadata ]; then
    mkdir /squashfs-check
    mount -t squashfs -o loop,ro /source/filesystem.squashfs /squashfs-check
    /bin/check-install-metadata /squashfs-check squashfs
    umount /squashfs-check
fi

unsquashfs -processors 2 -f -d /target /source/filesystem.squashfs

if [ -x /bin/check-install-metadata ]; then
    /bin/check-install-metadata /target extracted
    checker=/target/usr/lib/systemd/sable-check-install-metadata
    [ ! -e "$checker" ] && [ ! -L "$checker" ]
    cp /bin/check-install-metadata "$checker"
    chmod 0755 "$checker"
fi
[ "$(readlink /target/sbin)" = usr/sbin ]
[ "$(readlink /target/usr/sbin/init)" = ../lib/systemd/systemd ]
[ -f /target/usr/lib/systemd/systemd ]
[ ! -L /target/usr/lib/systemd/systemd ]
[ -x /target/usr/bin/busybox ]
[ ! -e /target/.sable-fresh-install-probe ]
for dir in dev proc sys; do
    [ ! -L "/target/$dir" ]
    mkdir -p "/target/$dir"
done

cp /source/installed-init /target/usr/lib/systemd/systemd
chmod 0755 /target/usr/lib/systemd/systemd
mkdir -p /esp/EFI/BOOT
cp /source/BOOTX64.EFI /esp/EFI/BOOT/BOOTX64.EFI
cp /source/vmlinuz /esp/vmlinuz

awk '
    $2 == "installed-init" { print $1 "  /target/usr/lib/systemd/systemd" }
    $2 == "BOOTX64.EFI"    { print $1 "  /esp/EFI/BOOT/BOOTX64.EFI" }
    $2 == "vmlinuz"        { print $1 "  /esp/vmlinuz" }
' /source/payload.sha256 | sha256sum -c -

sync
umount /esp
umount /target
umount /source
sync
echo SABLE_GUEST_INSTALL_PASS
exec poweroff -f
