#!/bin/bash

KERNEL_VER="6.16.1-lfs-12.4-systemd"
SABLE=""
WORK="/tmp/initramfs-build"
OUTPUT="/boot/initrd.img-$KERNEL_VER"
TOOLS="/opt/initramfs-tools"

echo "=== SableLinux initramfs builder ==="

rm -rf $WORK
mkdir -p $WORK/{bin,dev,proc,sys,lib,lib64,sysroot,lib/firmware/i915,lib/firmware/intel-ucode}

for bin in busybox mount sh sleep switch_root umount; do
    cp $TOOLS/bin/$bin $WORK/bin/
done

cp $TOOLS/lib/libc.so.6 $WORK/lib/
cp $TOOLS/lib/libm.so.6 $WORK/lib/
cp $TOOLS/lib64/ld-linux-x86-64.so.2 $WORK/lib64/

cp /lib/firmware/i915/mtl_dmc.bin $WORK/lib/firmware/i915/
cp /lib/firmware/i915/mtl_dmc_ver2_10.bin $WORK/lib/firmware/i915/
cp /lib/firmware/i915/mtl_guc_70.bin $WORK/lib/firmware/i915/
cp /lib/firmware/i915/mtl_gsc_1.bin $WORK/lib/firmware/i915/
cp /lib/firmware/i915/mtl_huc_gsc.bin $WORK/lib/firmware/i915/

cp /lib/firmware/intel-ucode/* $WORK/lib/firmware/intel-ucode/

cp /opt/initramfs-tools/sable-init $WORK/init
chmod 755 $WORK/init

ln -s busybox $WORK/bin/mdev
ln -s busybox $WORK/bin/findfs

cd $WORK
find . | cpio -H newc -o | gzip > $OUTPUT

echo "=== Done: $OUTPUT ==="
ls -lh $OUTPUT
