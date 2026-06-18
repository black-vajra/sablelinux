#!/bin/bash
WORK="/tmp/live-initramfs-build"
OUTPUT="/tmp/usb-root/boot/initramfs-live.img"
TOOLS="/opt/initramfs-tools"

echo "=== SableLinux live initramfs builder ==="

rm -rf $WORK
mkdir -p $WORK/{bin,dev,proc,sys,lib,lib64,mnt/scan,mnt/squashfs,mnt/overlay,mnt/rootfs}
mkdir -p $WORK/lib/firmware/rtl_nic
mkdir -p $WORK/lib/firmware/intel-ucode
mkdir -p $WORK/lib/firmware/mediatek

for bin in busybox mount sh sleep switch_root umount; do
    cp $TOOLS/bin/$bin $WORK/bin/
done
ln -s busybox $WORK/bin/mdev
ln -s busybox $WORK/bin/findfs
ln -s busybox $WORK/bin/losetup

cp $TOOLS/lib/libc.so.6  $WORK/lib/
cp $TOOLS/lib/libm.so.6  $WORK/lib/
cp $TOOLS/lib64/ld-linux-x86-64.so.2 $WORK/lib64/

cp /lib/firmware/rtl_nic/rtl8168fp-3.fw     $WORK/lib/firmware/rtl_nic/       2>/dev/null || true
cp /lib/firmware/regulatory.db               $WORK/lib/firmware/               2>/dev/null || true
cp /lib/firmware/regulatory.db.p7s           $WORK/lib/firmware/               2>/dev/null || true
cp /lib/firmware/iwlwifi-7265D-*.ucode       $WORK/lib/firmware/               2>/dev/null || true
cp /lib/firmware/intel-ucode/06-c6-02              $WORK/lib/firmware/intel-ucode/   2>/dev/null || true
cp /lib/firmware/mediatek/mt7925/*           $WORK/lib/firmware/mediatek/      2>/dev/null || true

cat > $WORK/init << ENDINIT
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
    ROOTDEV=\$(findfs LABEL=SABLELINUX 2>/dev/null)
    [ -n "\$ROOTDEV" ] && break
    echo "Waiting for device... attempt \$i"
    sleep 2
done

if [ -z "\$ROOTDEV" ]; then
    echo "ERROR: cannot find SABLELINUX partition"
    exec sh
fi

echo "Found \$ROOTDEV"
mount -t ext4 -o ro "\$ROOTDEV" /mnt/scan || exec sh

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
mount --move /sys  /mnt/rootfs/sys
mount --move /dev  /mnt/rootfs/dev

echo "Pivoting to live root..."
exec switch_root /mnt/rootfs /sbin/init
ENDINIT

chmod 755 $WORK/init

cd $WORK
find . | cpio -H newc -o | gzip > $OUTPUT
echo "=== Done: $OUTPUT ==="
ls -lh $OUTPUT
