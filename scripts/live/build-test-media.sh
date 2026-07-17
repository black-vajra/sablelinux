#!/usr/bin/env bash
set -Eeuo pipefail

WORKSPACE="/srv/sablelinux"
REQUESTED_BUILD_ID=""
REQUESTED_SIZE_GIB=""

usage() {
    cat <<'USAGE'
Usage:

  sudo scripts/live/build-test-media.sh
  sudo scripts/live/build-test-media.sh --build-id BUILD_ID
  sudo scripts/live/build-test-media.sh --size-gib SIZE
USAGE
}

die() {
    echo "ERROR: $*" >&2
    exit 1
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --build-id)
            [ "$#" -ge 2 ] ||
                die "--build-id requires a value"
            REQUESTED_BUILD_ID="$2"
            shift 2
            ;;
        --size-gib)
            [ "$#" -ge 2 ] ||
                die "--size-gib requires a value"
            REQUESTED_SIZE_GIB="$2"
            shift 2
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            die "unknown argument: $1"
            ;;
    esac
done

[ "$EUID" -eq 0 ] ||
    die "run this script through sudo"

BUILD_USER="${SUDO_USER:-pepper}"
BUILD_GROUP="$(id -gn "$BUILD_USER")"
REPO="/home/$BUILD_USER/sablelinux"

[ -d "$REPO/.git" ] ||
    die "repository is missing: $REPO"

if [ -n "$REQUESTED_BUILD_ID" ]; then
    BUILD_ID="$REQUESTED_BUILD_ID"
else
    BUILD_ID="$(cat "$WORKSPACE/state/current-build-id")"
fi

BUILD_ROOT="$WORKSPACE/builds/$BUILD_ID"
BUILD_ENV="$BUILD_ROOT/metadata/build.env"
SQUASHFS="$BUILD_ROOT/squashfs/filesystem.squashfs"
INITRAMFS="$BUILD_ROOT/initramfs/initramfs-live.img"
MEDIA_DIR="$BUILD_ROOT/media"
OUTPUT="$MEDIA_DIR/sablelinux-live-test.ext4"
PARTIAL="$MEDIA_DIR/sablelinux-live-test.ext4.partial"
MOUNT_DIR="$BUILD_ROOT/tmp/test-media-mount"
LOCK="$WORKSPACE/state/locks/test-media-$BUILD_ID.lock"

[ -d "$BUILD_ROOT" ] ||
    die "build directory is missing: $BUILD_ROOT"

[ -f "$BUILD_ENV" ] ||
    die "build metadata is missing: $BUILD_ENV"

[ -s "$SQUASHFS" ] ||
    die "SquashFS input is missing: $SQUASHFS"

[ -s "$INITRAMFS" ] ||
    die "live initramfs input is missing: $INITRAMFS"

[ "$(cat "$BUILD_ROOT/BUILD_STATE")" = "initramfs-generated" ] ||
    die "build must be initramfs-generated"

[ ! -e "$OUTPUT" ] ||
    die "test-media output already exists: $OUTPUT"

git_repo() {
    git -c safe.directory="$REPO" -C "$REPO" "$@"
}

CURRENT_COMMIT="$(git_repo rev-parse HEAD)"
BUILD_COMMIT="$(
    awk -F= '$1 == "GIT_COMMIT" {print $2}' "$BUILD_ENV"
)"

[ "$CURRENT_COMMIT" = "$BUILD_COMMIT" ] ||
    die "repository commit does not match build provenance"

[ -z "$(git_repo status --porcelain)" ] ||
    die "repository contains uncommitted changes"

[ "$(hostname)" = "SableLinux" ] ||
    die "this is not the canonical Z890 host"

for tool in \
    truncate \
    mkfs.ext4 \
    mount \
    umount \
    e2fsck \
    blkid \
    sha256sum \
    rsync
do
    command -v "$tool" >/dev/null 2>&1 ||
        die "required tool is unavailable: $tool"
done

if ! mkdir "$LOCK" 2>/dev/null; then
    die "another test-media generation process appears active"
fi

MOUNTED="no"

cleanup() {
    if [ "$MOUNTED" = "yes" ] && mountpoint -q "$MOUNT_DIR"; then
        umount "$MOUNT_DIR" 2>/dev/null || true
    fi

    rmdir "$MOUNT_DIR" 2>/dev/null || true
    rm -f "$PARTIAL"
    rmdir "$LOCK" 2>/dev/null || true
}

trap cleanup EXIT

install -d \
    -o root \
    -g "$BUILD_GROUP" \
    -m 2775 \
    "$MEDIA_DIR"

install -d \
    -o root \
    -g root \
    -m 0755 \
    "$MOUNT_DIR"

SQUASHFS_BYTES="$(stat -c '%s' "$SQUASHFS")"
GIB=$((1024 * 1024 * 1024))
MINIMUM_BYTES=$((SQUASHFS_BYTES + GIB))
CALCULATED_GIB=$(((MINIMUM_BYTES + GIB - 1) / GIB))

if [ "$CALCULATED_GIB" -lt 8 ]; then
    CALCULATED_GIB=8
fi

if [ -n "$REQUESTED_SIZE_GIB" ]; then
    case "$REQUESTED_SIZE_GIB" in
        ''|*[!0-9]*)
            die "--size-gib must be a positive integer"
            ;;
    esac

    IMAGE_GIB="$REQUESTED_SIZE_GIB"
else
    IMAGE_GIB="$CALCULATED_GIB"
fi

[ "$IMAGE_GIB" -ge "$CALCULATED_GIB" ] ||
    die "requested image is too small; at least ${CALCULATED_GIB} GiB is required"

IMAGE_BYTES=$((IMAGE_GIB * GIB))
SOURCE_DATE_EPOCH="$(
    git_repo show -s --format=%ct "$CURRENT_COMMIT"
)"

TIMESTAMP="$(date --utc +%Y%m%dT%H%M%SZ)"
REPORT="$BUILD_ROOT/reports/test-media-build-$TIMESTAMP.txt"
LOG="$BUILD_ROOT/logs/test-media-build-$TIMESTAMP.log"

{
    echo "============================================================"
    echo "SABLELINUX TIER 1 EXT4 TEST-MEDIA GENERATION"
    echo "============================================================"
    echo "Timestamp: $(date --iso-8601=seconds)"
    echo "Build ID: $BUILD_ID"
    echo "Git commit: $CURRENT_COMMIT"
    echo "SquashFS: $SQUASHFS"
    echo "SquashFS bytes: $SQUASHFS_BYTES"
    echo "Image: $OUTPUT"
    echo "Image virtual size: ${IMAGE_GIB} GiB"
    echo "Filesystem label: SABLELINUX"
    echo "SquashFS destination: /live/filesystem.squashfs"
    echo "Source date epoch: $SOURCE_DATE_EPOCH"
    echo
    echo "=== INPUT HASHES ==="
    sha256sum \
        "$SQUASHFS" \
        "$INITRAMFS" \
        "$REPO/scripts/live/build-test-media.sh"
    echo
    echo "=== CREATE SPARSE IMAGE ==="
} | tee "$REPORT"

rm -f "$PARTIAL"
truncate -s "$IMAGE_BYTES" "$PARTIAL"

{
    echo "Sparse file created:"
    ls -lh "$PARTIAL"
    du -h "$PARTIAL"
    echo
    echo "=== FORMAT EXT4 ==="
} | tee -a "$REPORT"

mkfs.ext4 \
    -F \
    -L SABLELINUX \
    -m 0 \
    -E lazy_itable_init=0,lazy_journal_init=0 \
    "$PARTIAL" 2>&1 |
    tee "$LOG" |
    tee -a "$REPORT"

echo |
    tee -a "$REPORT"

echo "=== POPULATE TEST MEDIA ===" |
    tee -a "$REPORT"

mount -o loop,rw "$PARTIAL" "$MOUNT_DIR"
MOUNTED="yes"

install -d -m 0755 "$MOUNT_DIR/live"

install -m 0644 \
    "$SQUASHFS" \
    "$MOUNT_DIR/live/filesystem.squashfs"

SQUASHFS_HASH="$(sha256sum "$SQUASHFS" | awk '{print $1}')"

printf '%s  %s\n' \
    "$SQUASHFS_HASH" \
    "filesystem.squashfs" \
    > "$MOUNT_DIR/live/filesystem.squashfs.sha256"

sed \
    's/^BUILD_STATE=.*/BUILD_STATE=test-media-generated/' \
    "$BUILD_ENV" \
    > "$MOUNT_DIR/live/build.env"

cat > "$MOUNT_DIR/live/README.txt" <<README
SableLinux Tier 1 direct-boot test media

Build ID: $BUILD_ID
Git commit: $CURRENT_COMMIT
Filesystem label: SABLELINUX
Live filesystem: /live/filesystem.squashfs

This ext4 image is intended for direct QEMU/KVM validation with the matching
kernel and live initramfs stored in the canonical build directory.
README

find "$MOUNT_DIR/live" \
    -exec touch -h -d "@$SOURCE_DATE_EPOCH" {} +

sync

{
    echo "Mounted contents:"
    find "$MOUNT_DIR" \
        -maxdepth 3 \
        -printf '%y %m %u:%g %s %p\n' |
        sort
    echo
    echo "Filesystem usage:"
    df -h "$MOUNT_DIR"
} | tee -a "$REPORT"

umount "$MOUNT_DIR"
MOUNTED="no"

echo |
    tee -a "$REPORT"

echo "=== VALIDATE EXT4 IMAGE ===" |
    tee -a "$REPORT"

e2fsck -fn "$PARTIAL" 2>&1 |
    tee -a "$LOG" |
    tee -a "$REPORT"

LABEL="$(blkid -s LABEL -o value "$PARTIAL")"
FSTYPE="$(blkid -s TYPE -o value "$PARTIAL")"
UUID="$(blkid -s UUID -o value "$PARTIAL")"

[ "$LABEL" = "SABLELINUX" ] ||
    die "unexpected filesystem label: $LABEL"

[ "$FSTYPE" = "ext4" ] ||
    die "unexpected filesystem type: $FSTYPE"

mount -o loop,ro "$PARTIAL" "$MOUNT_DIR"
MOUNTED="yes"

test -s "$MOUNT_DIR/live/filesystem.squashfs" ||
    die "SquashFS is missing from test-media image"

test -f "$MOUNT_DIR/live/filesystem.squashfs.sha256" ||
    die "embedded SquashFS checksum is missing"

test -f "$MOUNT_DIR/live/build.env" ||
    die "embedded build metadata is missing"

(
    cd "$MOUNT_DIR/live"
    sha256sum -c filesystem.squashfs.sha256
) |
    tee -a "$REPORT"

cmp -s \
    "$SQUASHFS" \
    "$MOUNT_DIR/live/filesystem.squashfs" ||
    die "embedded SquashFS differs from canonical input"

grep -q "^BUILD_ID=$BUILD_ID$" \
    "$MOUNT_DIR/live/build.env" ||
    die "embedded build ID does not match"

grep -q "^GIT_COMMIT=$CURRENT_COMMIT$" \
    "$MOUNT_DIR/live/build.env" ||
    die "embedded Git commit does not match"

umount "$MOUNT_DIR"
MOUNTED="no"

mv "$PARTIAL" "$OUTPUT"

chown root:"$BUILD_GROUP" "$OUTPUT"
chmod 0644 "$OUTPUT"

IMAGE_SHA256="$(sha256sum "$OUTPUT" | awk '{print $1}')"
IMAGE_ACTUAL_BYTES="$(du -B1 "$OUTPUT" | awk '{print $1}')"

sha256sum "$OUTPUT" \
    > "$BUILD_ROOT/metadata/test-media.sha256"

cat > "$BUILD_ROOT/metadata/test-media.env" <<METADATA
BUILD_ID=$BUILD_ID
GENERATED_AT=$(date --utc +%Y-%m-%dT%H:%M:%SZ)
GIT_COMMIT=$CURRENT_COMMIT
SOURCE_DATE_EPOCH=$SOURCE_DATE_EPOCH
OUTPUT=$OUTPUT
FORMAT=ext4
LABEL=$LABEL
UUID=$UUID
VIRTUAL_BYTES=$IMAGE_BYTES
ACTUAL_DISK_BYTES=$IMAGE_ACTUAL_BYTES
SQUASHFS_PATH=/live/filesystem.squashfs
SQUASHFS_BYTES=$SQUASHFS_BYTES
SQUASHFS_SHA256=$SQUASHFS_HASH
IMAGE_SHA256=$IMAGE_SHA256
GENERATOR_SHA256=$(sha256sum "$REPO/scripts/live/build-test-media.sh" | awk '{print $1}')
METADATA

du -h "$OUTPUT" \
    > "$BUILD_ROOT/metadata/test-media-size.txt"

printf '%s\n' "test-media-generated" \
    > "$BUILD_ROOT/BUILD_STATE"

sed -i \
    's/^BUILD_STATE=.*/BUILD_STATE=test-media-generated/' \
    "$BUILD_ENV"

chown root:"$BUILD_GROUP" \
    "$BUILD_ROOT/BUILD_STATE" \
    "$BUILD_ENV" \
    "$BUILD_ROOT/metadata/test-media.env" \
    "$BUILD_ROOT/metadata/test-media.sha256" \
    "$BUILD_ROOT/metadata/test-media-size.txt"

chmod 0664 \
    "$BUILD_ROOT/BUILD_STATE" \
    "$BUILD_ENV" \
    "$BUILD_ROOT/metadata/test-media.env" \
    "$BUILD_ROOT/metadata/test-media.sha256" \
    "$BUILD_ROOT/metadata/test-media-size.txt"

{
    echo
    echo "PASS: ext4 Tier 1 test-media generation completed"
    echo "Build state: test-media-generated"
    echo
    ls -lh "$OUTPUT"
    du -h "$OUTPUT"
    cat "$BUILD_ROOT/metadata/test-media.sha256"
    echo
    echo "Report: $REPORT"
    echo "Log: $LOG"
} | tee -a "$REPORT"
