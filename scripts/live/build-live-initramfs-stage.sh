#!/usr/bin/env bash
set -Eeuo pipefail

WORKSPACE="/srv/sablelinux"
REQUESTED_BUILD_ID=""

usage() {
    cat <<'USAGE'
Usage:

  sudo scripts/live/build-live-initramfs-stage.sh
  sudo scripts/live/build-live-initramfs-stage.sh --build-id BUILD_ID
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

if [ -n "$REQUESTED_BUILD_ID" ]; then
    BUILD_ID="$REQUESTED_BUILD_ID"
else
    BUILD_ID="$(cat "$WORKSPACE/state/current-build-id")"
fi

BUILD_ROOT="$WORKSPACE/builds/$BUILD_ID"
BUILD_ENV="$BUILD_ROOT/metadata/build.env"
SQUASHFS="$BUILD_ROOT/squashfs/filesystem.squashfs"
OUTPUT_DIR="$BUILD_ROOT/initramfs"
BOOT_DIR="$BUILD_ROOT/boot"
OUTPUT="$OUTPUT_DIR/initramfs-live.img"
FIRST_OUTPUT="$OUTPUT_DIR/initramfs-live.img.first"
SECOND_OUTPUT="$OUTPUT_DIR/initramfs-live.img.second"
LOCK="$WORKSPACE/state/locks/initramfs-$BUILD_ID.lock"

[ -d "$REPO/.git" ] ||
    die "repository is missing: $REPO"

[ -d "$BUILD_ROOT" ] ||
    die "build directory is missing: $BUILD_ROOT"

[ -f "$BUILD_ENV" ] ||
    die "build metadata is missing"

[ -s "$SQUASHFS" ] ||
    die "SquashFS input is missing"

[ "$(cat "$BUILD_ROOT/BUILD_STATE")" = "squashfs-generated" ] ||
    die "build must be squashfs-generated"

[ ! -e "$OUTPUT" ] ||
    die "initramfs output already exists"

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

KERNEL_RELEASE="$(
    awk -F= '$1 == "KERNEL_RELEASE" {print $2}' "$BUILD_ENV"
)"

KERNEL_SOURCE="/boot/vmlinuz-$KERNEL_RELEASE"
MODULE_ROOT="/lib/modules/$KERNEL_RELEASE"
BUSYBOX="${BUSYBOX:-/usr/bin/busybox}"
BUILDER="$REPO/scripts/live/build-live-initramfs-busybox.sh"

[ -f "$KERNEL_SOURCE" ] ||
    die "kernel image is missing: $KERNEL_SOURCE"

[ -d "$MODULE_ROOT" ] ||
    die "module tree is missing: $MODULE_ROOT"

[ -x "$BUSYBOX" ] ||
    die "BusyBox is missing: $BUSYBOX"

[ -x "$BUILDER" ] ||
    die "BusyBox initramfs builder is missing"

file "$BUSYBOX" |
    grep -q 'statically linked' ||
    die "BusyBox is not statically linked"

if ! mkdir "$LOCK" 2>/dev/null; then
    die "another initramfs build appears to be active"
fi

cleanup() {
    rm -f "$FIRST_OUTPUT" "$SECOND_OUTPUT"
    rm -rf \
        "$BUILD_ROOT/tmp/initramfs-work-first" \
        "$BUILD_ROOT/tmp/initramfs-work-second" \
        "$BUILD_ROOT/tmp/initramfs-inspect"
    rmdir "$LOCK" 2>/dev/null || true
}

trap cleanup EXIT

install -d \
    -o root \
    -g "$BUILD_GROUP" \
    -m 2775 \
    "$OUTPUT_DIR" \
    "$BOOT_DIR"

SOURCE_DATE_EPOCH="$(
    git_repo show -s --format=%ct "$CURRENT_COMMIT"
)"

TIMESTAMP="$(date --utc +%Y%m%dT%H%M%SZ)"
REPORT="$BUILD_ROOT/reports/initramfs-build-$TIMESTAMP.txt"
LOG="$BUILD_ROOT/logs/initramfs-build-$TIMESTAMP.log"

{
    echo "============================================================"
    echo "SABLELINUX CANONICAL LIVE INITRAMFS GENERATION"
    echo "============================================================"
    echo "Timestamp: $(date --iso-8601=seconds)"
    echo "Build ID: $BUILD_ID"
    echo "Git commit: $CURRENT_COMMIT"
    echo "Kernel release: $KERNEL_RELEASE"
    echo "Kernel source: $KERNEL_SOURCE"
    echo "SquashFS: $SQUASHFS"
    echo "BusyBox: $BUSYBOX"
    echo "Source date epoch: $SOURCE_DATE_EPOCH"
    echo
    echo "=== INPUT HASHES ==="
    sha256sum \
        "$KERNEL_SOURCE" \
        "$SQUASHFS" \
        "$BUSYBOX" \
        "$BUILDER"
    echo
    echo "=== FIRST REPRODUCIBILITY BUILD ==="
} | tee "$REPORT"

SOURCE_DATE_EPOCH="$SOURCE_DATE_EPOCH" \
BUSYBOX="$BUSYBOX" \
WORK="$BUILD_ROOT/tmp/initramfs-work-first" \
    "$BUILDER" "$FIRST_OUTPUT" 2>&1 |
    tee "$LOG" |
    tee -a "$REPORT"

echo |
    tee -a "$REPORT"

echo "=== SECOND REPRODUCIBILITY BUILD ===" |
    tee -a "$REPORT"

SOURCE_DATE_EPOCH="$SOURCE_DATE_EPOCH" \
BUSYBOX="$BUSYBOX" \
WORK="$BUILD_ROOT/tmp/initramfs-work-second" \
    "$BUILDER" "$SECOND_OUTPUT" 2>&1 |
    tee -a "$LOG" |
    tee -a "$REPORT"

if ! cmp -s "$FIRST_OUTPUT" "$SECOND_OUTPUT"; then
    echo "First hash:" |
        tee -a "$REPORT"
    sha256sum "$FIRST_OUTPUT" |
        tee -a "$REPORT"

    echo "Second hash:" |
        tee -a "$REPORT"
    sha256sum "$SECOND_OUTPUT" |
        tee -a "$REPORT"

    die "repeated initramfs builds are not byte-identical"
fi

echo |
    tee -a "$REPORT"

echo "PASS: repeated initramfs builds are byte-identical" |
    tee -a "$REPORT"

mv "$FIRST_OUTPUT" "$OUTPUT"
rm -f "$SECOND_OUTPUT"

KERNEL_OUTPUT="$BOOT_DIR/vmlinuz-$KERNEL_RELEASE"

install -m 0644 \
    "$KERNEL_SOURCE" \
    "$KERNEL_OUTPUT"

chown root:"$BUILD_GROUP" \
    "$OUTPUT" \
    "$KERNEL_OUTPUT"

chmod 0644 \
    "$OUTPUT" \
    "$KERNEL_OUTPUT"

echo |
    tee -a "$REPORT"

echo "=== VALIDATE INITRAMFS ARCHIVE ===" |
    tee -a "$REPORT"

gzip -t "$OUTPUT" ||
    die "initramfs gzip validation failed"

FILE_DESCRIPTION="$(file "$OUTPUT")"

echo "$FILE_DESCRIPTION" |
    tee -a "$REPORT"

echo "$FILE_DESCRIPTION" |
    grep -qi 'gzip compressed data' ||
    die "initramfs is not recognized as gzip data"

INSPECT="$BUILD_ROOT/tmp/initramfs-inspect"
mkdir -p "$INSPECT"

gzip -dc "$OUTPUT" |
    (
        cd "$INSPECT"
        cpio -idmu --quiet
    )

test -x "$INSPECT/init" ||
    die "initramfs does not contain executable /init"

test -x "$INSPECT/bin/busybox" ||
    die "initramfs does not contain executable BusyBox"

file "$INSPECT/bin/busybox" |
    grep -q 'statically linked' ||
    die "embedded BusyBox is not statically linked"

grep -q 'LABEL="SABLELINUX"' "$INSPECT/init" ||
    die "initramfs does not use the expected default media label"

grep -q 'SQUASH="/live/filesystem.squashfs"' "$INSPECT/init" ||
    die "initramfs does not use the expected SquashFS path"

grep -q 'switch_root /mnt/rootfs /sbin/init' "$INSPECT/init" ||
    die "initramfs does not switch into the live root"

LC_ALL=C gzip -dc "$OUTPUT" |
    cpio -it 2>/dev/null |
    LC_ALL=C sort \
    > "$BUILD_ROOT/metadata/initramfs-contents.txt"

sha256sum \
    "$KERNEL_OUTPUT" \
    "$OUTPUT" \
    "$SQUASHFS" \
    > "$BUILD_ROOT/metadata/live-boot-inputs.sha256"

cat > "$BUILD_ROOT/metadata/initramfs.env" <<METADATA
BUILD_ID=$BUILD_ID
GENERATED_AT=$(date --utc +%Y-%m-%dT%H:%M:%SZ)
GIT_COMMIT=$CURRENT_COMMIT
KERNEL_RELEASE=$KERNEL_RELEASE
SOURCE_DATE_EPOCH=$SOURCE_DATE_EPOCH
BUSYBOX=$BUSYBOX
BUILDER=$BUILDER
OUTPUT=$OUTPUT
OUTPUT_BYTES=$(stat -c '%s' "$OUTPUT")
KERNEL_OUTPUT=$KERNEL_OUTPUT
KERNEL_BYTES=$(stat -c '%s' "$KERNEL_OUTPUT")
BUILDER_SHA256=$(sha256sum "$BUILDER" | awk '{print $1}')
BUSYBOX_SHA256=$(sha256sum "$BUSYBOX" | awk '{print $1}')
INITRAMFS_SHA256=$(sha256sum "$OUTPUT" | awk '{print $1}')
KERNEL_SHA256=$(sha256sum "$KERNEL_OUTPUT" | awk '{print $1}')
SQUASHFS_SHA256=$(sha256sum "$SQUASHFS" | awk '{print $1}')
REPRODUCIBILITY_CHECK=byte-identical
METADATA

du -h "$OUTPUT" \
    > "$BUILD_ROOT/metadata/initramfs-size.txt"

printf '%s\n' "initramfs-generated" \
    > "$BUILD_ROOT/BUILD_STATE"

sed -i \
    's/^BUILD_STATE=.*/BUILD_STATE=initramfs-generated/' \
    "$BUILD_ENV"

chown root:"$BUILD_GROUP" \
    "$BUILD_ROOT/BUILD_STATE" \
    "$BUILD_ENV" \
    "$BUILD_ROOT/metadata/initramfs.env" \
    "$BUILD_ROOT/metadata/initramfs-size.txt" \
    "$BUILD_ROOT/metadata/initramfs-contents.txt" \
    "$BUILD_ROOT/metadata/live-boot-inputs.sha256"

chmod 0664 \
    "$BUILD_ROOT/BUILD_STATE" \
    "$BUILD_ENV" \
    "$BUILD_ROOT/metadata/initramfs.env" \
    "$BUILD_ROOT/metadata/initramfs-size.txt" \
    "$BUILD_ROOT/metadata/initramfs-contents.txt" \
    "$BUILD_ROOT/metadata/live-boot-inputs.sha256"

{
    echo
    echo "PASS: live initramfs generation completed"
    echo "PASS: reproducibility check passed"
    echo "Build state: initramfs-generated"
    echo
    cat "$BUILD_ROOT/metadata/initramfs-size.txt"
    cat "$BUILD_ROOT/metadata/live-boot-inputs.sha256"
    echo
    echo "Report: $REPORT"
    echo "Log: $LOG"
} | tee -a "$REPORT"
