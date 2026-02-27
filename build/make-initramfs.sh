#!/bin/bash
KERNEL_VER="6.16.1-lfs-12.4-systemd"
SABLE="/mnt/sable"
WORK="/tmp/initramfs-build"
OUTPUT="$SABLE/boot/initrd.img-$KERNEL_VER"
echo "=== SableLinux initramfs builder ==="
rm -rf $WORK
mkdir -p $WORK/{bin,dev,proc,sys,lib,lib64,sysroot,lib/firmware/i915}
for bin in busybox mount sh sleep switch_root umount; do
    cp /tmp/initrd-inspect/bin/$bin $WORK/bin/
done
cp /tmp/initrd-inspect/lib/libc.so.6 $WORK/lib/
cp /tmp/initrd-inspect/lib/libm.so.6 $WORK/lib/
cp /tmp/initrd-inspect/lib64/ld-linux-x86-64.so.2 $WORK/lib64/
cp $SABLE/lib/firmware/i915/mtl_dmc.bin $WORK/lib/firmware/i915/
cp $SABLE/lib/firmware/i915/mtl_dmc_ver2_10.bin $WORK/lib/firmware/i915/
cp $SABLE/lib/firmware/i915/mtl_guc_70.bin $WORK/lib/firmware/i915/
cp $SABLE/lib/firmware/i915/mtl_gsc_1.bin $WORK/lib/firmware/i915/
cp $SABLE/lib/firmware/i915/mtl_huc_gsc.bin $WORK/lib/firmware/i915/
cp /tmp/sable-init $WORK/init
chmod 755 $WORK/init
ln -s busybox $WORK/bin/mdev
ln -s busybox $WORK/bin/findfs
cd $WORK
find . | cpio -H newc -o | gzip > $OUTPUT
echo "=== Done: $OUTPUT ==="
ls -lh $OUTPUT
