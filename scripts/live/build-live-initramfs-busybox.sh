#!/usr/bin/env bash
# =============================================================================
# SableLinux BusyBox Live Initramfs Builder
#
# Builds a minimal live initramfs that:
#   1. finds a block device labeled SABLELINUX
#   2. mounts /live/filesystem.squashfs
#   3. creates a tmpfs-backed overlay root
#   4. switch_roots into /sbin/init
#
# Usage:
#   scripts/live/build-live-initramfs-busybox.sh OUTPUT.img
#
# Optional environment:
#   BUSYBOX=/path/to/static/busybox
# =============================================================================

set -euo pipefail

OUT="${1:-}"
BUSYBOX="${BUSYBOX:-/usr/bin/busybox}"
WORK="${WORK:-/tmp/sable-live-initramfs-build}"

die() {
    echo "ERROR: $*" >&2
    exit 1
}

[ -n "$OUT" ] || die "Usage: $0 OUTPUT.img"
[ -x "$BUSYBOX" ] || die "BusyBox not found or not executable: $BUSYBOX"

if ! "$BUSYBOX" --list >/dev/null 2>&1; then
    die "BusyBox applet listing failed: $BUSYBOX"
fi

for app in sh mount umount sleep mdev findfs losetup mkdir echo cat ls switch_root; do
    "$BUSYBOX" --list | grep -qx "$app" || die "BusyBox missing required applet: $app"
done

if file "$BUSYBOX" | grep -q "statically linked"; then
    echo "OK: static BusyBox detected: $BUSYBOX"
else
    echo "BusyBox file type:"
    file "$BUSYBOX" || true
    die "BusyBox must be static for this minimal initramfs: $BUSYBOX"
fi

echo "=== Building SableLinux BusyBox live initramfs ==="
echo "Output:  $OUT"
echo "BusyBox: $BUSYBOX"
echo "Workdir: $WORK"

rm -rf "$WORK"
mkdir -p "$WORK"/{bin,dev,proc,sys,mnt/scan,mnt/squashfs,mnt/overlay,mnt/rootfs}

cp -v "$BUSYBOX" "$WORK/bin/busybox"

cat > "$WORK/init" <<'ENDINIT'
#!/bin/busybox sh

/bin/busybox --install -s /bin

mount -t proc none /proc
mount -t sysfs none /sys
mount -t devtmpfs none /dev 2>/dev/null || true
mkdir -p /dev/pts
mount -t devpts none /dev/pts 2>/dev/null || true
mdev -s 2>/dev/null || true

LABEL="SABLELINUX"
SQUASH="/live/filesystem.squashfs"

for arg in $(cat /proc/cmdline); do
    case "$arg" in
        sable.live.label=*)  LABEL="${arg#sable.live.label=}" ;;
        sable.live.squash=*) SQUASH="${arg#sable.live.squash=}" ;;
    esac
done

echo
echo "=== SableLinux BusyBox Live Boot ==="
echo "cmdline: $(cat /proc/cmdline)"
echo "label:   $LABEL"
echo "squash:  $SQUASH"
echo

ROOTDEV=""
for i in 1 2 3 4 5 6 7 8 9 10; do
    ROOTDEV="$(findfs "LABEL=$LABEL" 2>/dev/null)"
    [ -n "$ROOTDEV" ] && break
    echo "Waiting for LABEL=$LABEL ... attempt $i"
    sleep 1
done

if [ -z "$ROOTDEV" ]; then
    echo "ERROR: cannot find LABEL=$LABEL"
    echo "Available block devices:"
    ls -l /dev/vd* /dev/sd* /dev/nvme* 2>/dev/null || true
    exec sh
fi

echo "Found live media: $ROOTDEV"

mount -t ext4 -o ro "$ROOTDEV" /mnt/scan || {
    echo "ERROR: failed to mount $ROOTDEV as ext4"
    exec sh
}

[ -f "/mnt/scan$SQUASH" ] || {
    echo "ERROR: missing squashfs: /mnt/scan$SQUASH"
    echo "Live media contents:"
    ls -R /mnt/scan | head -n 120
    exec sh
}

mount -t squashfs -o loop "/mnt/scan$SQUASH" /mnt/squashfs || {
    echo "ERROR: failed to mount squashfs"
    echo "Kernel filesystems:"
    cat /proc/filesystems
    exec sh
}

mount -t tmpfs tmpfs /mnt/overlay || {
    echo "ERROR: failed to mount tmpfs overlay store"
    exec sh
}

mkdir -p /mnt/overlay/upper /mnt/overlay/work

mount -t overlay overlay \
    -o lowerdir=/mnt/squashfs,upperdir=/mnt/overlay/upper,workdir=/mnt/overlay/work \
    /mnt/rootfs || {
    echo "ERROR: failed to mount overlayfs"
    echo "Kernel filesystems:"
    cat /proc/filesystems
    exec sh
}

mkdir -p /mnt/rootfs/proc /mnt/rootfs/sys /mnt/rootfs/dev
mount --move /proc /mnt/rootfs/proc
mount --move /sys  /mnt/rootfs/sys
mount --move /dev  /mnt/rootfs/dev

echo "Pivoting to SableLinux live root..."
exec switch_root /mnt/rootfs /sbin/init
ENDINIT

chmod 755 "$WORK/init"

mkdir -p "$(dirname "$OUT")"

(
    cd "$WORK"
    find . | cpio -H newc -o | gzip -9 > "$OUT"
)

echo "=== Done ==="
ls -lh "$OUT"
file "$OUT"
