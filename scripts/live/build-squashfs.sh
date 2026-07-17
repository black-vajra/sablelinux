#!/usr/bin/env bash
set -Eeuo pipefail

WORKSPACE="/srv/sablelinux"
REQUESTED_BUILD_ID=""

usage() {
    cat <<'USAGE'
Usage:

  sudo scripts/live/build-squashfs.sh
  sudo scripts/live/build-squashfs.sh --build-id BUILD_ID
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

[ -d "$REPO/.git" ] ||
    die "repository is missing: $REPO"

if [ -n "$REQUESTED_BUILD_ID" ]; then
    BUILD_ID="$REQUESTED_BUILD_ID"
else
    BUILD_ID="$(cat "$WORKSPACE/state/current-build-id")"
fi

BUILD_ROOT="$WORKSPACE/builds/$BUILD_ID"
ROOTFS="$BUILD_ROOT/rootfs"
OUTPUT_DIR="$BUILD_ROOT/squashfs"
OUTPUT="$OUTPUT_DIR/filesystem.squashfs"
PARTIAL="$OUTPUT_DIR/filesystem.squashfs.partial"
BUILD_ENV="$BUILD_ROOT/metadata/build.env"
ROOTFS_MANIFEST="$BUILD_ROOT/metadata/rootfs-files.tsv"
LOCK="$WORKSPACE/state/locks/squashfs-$BUILD_ID.lock"

[ -d "$BUILD_ROOT" ] ||
    die "build directory is missing: $BUILD_ROOT"

[ -d "$ROOTFS" ] ||
    die "rootfs is missing: $ROOTFS"

[ -f "$BUILD_ENV" ] ||
    die "build metadata is missing"

[ -f "$ROOTFS_MANIFEST" ] ||
    die "rootfs manifest is missing"

[ "$(cat "$BUILD_ROOT/BUILD_STATE")" = "rootfs-generated" ] ||
    die "build must be rootfs-generated"

[ ! -e "$OUTPUT" ] ||
    die "SquashFS output already exists: $OUTPUT"

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

MKSQUASHFS="$(command -v mksquashfs || true)"
UNSQUASHFS="$(command -v unsquashfs || true)"

[ -x "$MKSQUASHFS" ] ||
    die "mksquashfs is unavailable"

[ -x "$UNSQUASHFS" ] ||
    die "unsquashfs is unavailable"

if ! mkdir "$LOCK" 2>/dev/null; then
    die "another SquashFS build appears to be active"
fi

cleanup() {
    rm -f "$PARTIAL"
    rmdir "$LOCK" 2>/dev/null || true
}

trap cleanup EXIT

MOUNT_FOUND="$(
    findmnt -rn -o TARGET |
    awk -v root="$ROOTFS" '
        $0 == root || index($0, root "/") == 1
    '
)"

[ -z "$MOUNT_FOUND" ] ||
    die "a mounted filesystem exists inside the rootfs"

install -d \
    -o root \
    -g "$BUILD_GROUP" \
    -m 2775 \
    "$OUTPUT_DIR"

rm -f "$PARTIAL"

MKSQUASHFS_HELP="$("$MKSQUASHFS" -help 2>&1 || true)"
ZSTD_HELP="$("$MKSQUASHFS" -help-comp zstd 2>&1 || true)"

echo "$MKSQUASHFS_HELP" |
    grep -qi 'zstd' ||
    die "installed mksquashfs lacks zstd support"

SOURCE_DATE_EPOCH="$(
    git_repo show -s --format=%ct "$CURRENT_COMMIT"
)"

PROCESSORS="$(nproc)"

OPTIONS=(
    -noappend
    -comp zstd
    -b 1M
    -processors "$PROCESSORS"
)

REPRODUCIBLE_OPTION="unsupported"
MKFS_TIME_OPTION="unsupported"
ALL_TIME_OPTION="unsupported"
ZSTD_LEVEL_OPTION="default"

if echo "$MKSQUASHFS_HELP" |
   grep -q -- '-reproducible'
then
    OPTIONS+=(-reproducible)
    REPRODUCIBLE_OPTION="enabled"
fi

if echo "$MKSQUASHFS_HELP" |
   grep -q -- '-mkfs-time'
then
    OPTIONS+=(-mkfs-time "$SOURCE_DATE_EPOCH")
    MKFS_TIME_OPTION="$SOURCE_DATE_EPOCH"
fi

if echo "$MKSQUASHFS_HELP" |
   grep -q -- '-all-time'
then
    OPTIONS+=(-all-time "$SOURCE_DATE_EPOCH")
    ALL_TIME_OPTION="$SOURCE_DATE_EPOCH"
fi

if echo "$ZSTD_HELP" |
   grep -q -- '-Xcompression-level'
then
    OPTIONS+=(-Xcompression-level 15)
    ZSTD_LEVEL_OPTION="15"
fi

TIMESTAMP="$(date --utc +%Y%m%dT%H%M%SZ)"
REPORT="$BUILD_ROOT/reports/squashfs-build-$TIMESTAMP.txt"
LOG="$BUILD_ROOT/logs/squashfs-build-$TIMESTAMP.log"

{
    echo "============================================================"
    echo "SABLELINUX CANONICAL SQUASHFS GENERATION"
    echo "============================================================"
    echo "Timestamp: $(date --iso-8601=seconds)"
    echo "Build ID: $BUILD_ID"
    echo "Git commit: $CURRENT_COMMIT"
    echo "Rootfs: $ROOTFS"
    echo "Output: $OUTPUT"
    echo "Processors: $PROCESSORS"
    echo "Source date epoch: $SOURCE_DATE_EPOCH"
    echo "Reproducible option: $REPRODUCIBLE_OPTION"
    echo "mkfs time option: $MKFS_TIME_OPTION"
    echo "all-time option: $ALL_TIME_OPTION"
    echo "Zstd compression level: $ZSTD_LEVEL_OPTION"
    echo
    echo "=== INPUT ROOTFS ==="
    du -x -sh "$ROOTFS"
    printf 'Regular files: '
    find "$ROOTFS" -xdev -type f | wc -l
    echo
    echo "=== INPUT MANIFEST HASH ==="
    sha256sum "$ROOTFS_MANIFEST"
    echo
    echo "=== GENERATOR HASH ==="
    sha256sum "$REPO/scripts/live/build-squashfs.sh"
    echo
    echo "=== MKSQUASHFS VERSION ==="
    "$MKSQUASHFS" -version 2>&1 | head -n 4
    echo
    echo "=== EFFECTIVE OPTIONS ==="
    printf '%q ' "${OPTIONS[@]}"
    echo
    echo
    echo "=== BUILD OUTPUT ==="
} | tee "$REPORT"

"$MKSQUASHFS" \
    "$ROOTFS" \
    "$PARTIAL" \
    "${OPTIONS[@]}" 2>&1 |
    tee "$LOG" |
    tee -a "$REPORT"

test -s "$PARTIAL" ||
    die "mksquashfs produced no output"

mv "$PARTIAL" "$OUTPUT"

chown root:"$BUILD_GROUP" "$OUTPUT"
chmod 0644 "$OUTPUT"

echo |
    tee -a "$REPORT"

echo "=== VALIDATE SQUASHFS ===" |
    tee -a "$REPORT"

FILE_DESCRIPTION="$(file "$OUTPUT")"

echo "$FILE_DESCRIPTION" |
    tee -a "$REPORT"

echo "$FILE_DESCRIPTION" |
    grep -qi 'Squashfs filesystem' ||
    die "output is not recognized as SquashFS"

"$UNSQUASHFS" -s "$OUTPUT" 2>&1 |
    tee "$BUILD_ROOT/reports/squashfs-stat-$TIMESTAMP.txt" |
    tee -a "$REPORT"

EMBEDDED_OS_RELEASE="$BUILD_ROOT/tmp/squashfs-os-release-$TIMESTAMP"
EMBEDDED_BUILD_ENV="$BUILD_ROOT/tmp/squashfs-build-env-$TIMESTAMP"

"$UNSQUASHFS" -cat \
    "$OUTPUT" \
    etc/os-release \
    > "$EMBEDDED_OS_RELEASE"

"$UNSQUASHFS" -cat \
    "$OUTPUT" \
    etc/sablelinux/build.env \
    > "$EMBEDDED_BUILD_ENV"

grep -q '^ID=sablelinux$' "$EMBEDDED_OS_RELEASE" ||
    die "embedded os-release is not SableLinux"

grep -q "^BUILD_ID=$BUILD_ID$" "$EMBEDDED_BUILD_ENV" ||
    die "embedded build ID does not match"

grep -q "^GIT_COMMIT=$CURRENT_COMMIT$" "$EMBEDDED_BUILD_ENV" ||
    die "embedded Git commit does not match"

OUTPUT_BYTES="$(stat -c '%s' "$OUTPUT")"

[ "$OUTPUT_BYTES" -gt 1073741824 ] ||
    die "SquashFS is unexpectedly smaller than 1 GiB"

sha256sum "$OUTPUT" \
    > "$BUILD_ROOT/metadata/squashfs.sha256"

cat > "$BUILD_ROOT/metadata/squashfs.env" <<METADATA
BUILD_ID=$BUILD_ID
GENERATED_AT=$(date --utc +%Y-%m-%dT%H:%M:%SZ)
GIT_COMMIT=$CURRENT_COMMIT
SOURCE_DATE_EPOCH=$SOURCE_DATE_EPOCH
COMPRESSION=zstd
BLOCK_SIZE=1M
COMPRESSION_LEVEL=$ZSTD_LEVEL_OPTION
PROCESSORS=$PROCESSORS
REPRODUCIBLE_OPTION=$REPRODUCIBLE_OPTION
MKFS_TIME_OPTION=$MKFS_TIME_OPTION
ALL_TIME_OPTION=$ALL_TIME_OPTION
OUTPUT=$OUTPUT
OUTPUT_BYTES=$OUTPUT_BYTES
MKSQUASHFS=$MKSQUASHFS
UNSQUASHFS=$UNSQUASHFS
GENERATOR_SHA256=$(sha256sum "$REPO/scripts/live/build-squashfs.sh" | awk '{print $1}')
ROOTFS_MANIFEST_SHA256=$(sha256sum "$ROOTFS_MANIFEST" | awk '{print $1}')
SQUASHFS_SHA256=$(sha256sum "$OUTPUT" | awk '{print $1}')
METADATA

du -h "$OUTPUT" \
    > "$BUILD_ROOT/metadata/squashfs-size.txt"

printf '%s\n' "squashfs-generated" \
    > "$BUILD_ROOT/BUILD_STATE"

sed -i \
    's/^BUILD_STATE=.*/BUILD_STATE=squashfs-generated/' \
    "$BUILD_ENV"

chown root:"$BUILD_GROUP" \
    "$BUILD_ROOT/BUILD_STATE" \
    "$BUILD_ENV" \
    "$BUILD_ROOT/metadata/squashfs.env" \
    "$BUILD_ROOT/metadata/squashfs.sha256" \
    "$BUILD_ROOT/metadata/squashfs-size.txt"

chmod 0664 \
    "$BUILD_ROOT/BUILD_STATE" \
    "$BUILD_ENV" \
    "$BUILD_ROOT/metadata/squashfs.env" \
    "$BUILD_ROOT/metadata/squashfs.sha256" \
    "$BUILD_ROOT/metadata/squashfs-size.txt"

rm -f \
    "$EMBEDDED_OS_RELEASE" \
    "$EMBEDDED_BUILD_ENV"

{
    echo
    echo "PASS: SquashFS generation completed"
    echo "Build state: squashfs-generated"
    echo
    cat "$BUILD_ROOT/metadata/squashfs-size.txt"
    cat "$BUILD_ROOT/metadata/squashfs.sha256"
    echo
    echo "Report: $REPORT"
    echo "Log: $LOG"
} | tee -a "$REPORT"
