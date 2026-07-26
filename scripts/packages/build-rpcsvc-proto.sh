#!/usr/bin/env bash
set -euo pipefail

PACKAGE="rpcsvc-proto"
VERSION="1.4.4"

REPO="${SABLELINUX_REPO:-$HOME/sablelinux}"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

SOURCE_ROOT="/srv/sablelinux/sources/$PACKAGE"
TARBALL="$SOURCE_ROOT/${PACKAGE}-${VERSION}.tar.xz"
SOURCE_METADATA="$SOURCE_ROOT/source-metadata.env"

BUILD_ROOT="/srv/sablelinux/package-builds/$PACKAGE/$VERSION"
SOURCE_DIR="$BUILD_ROOT/source"
BUILD_DIR="$BUILD_ROOT/build"
STAGE_DIR="$BUILD_ROOT/stage"
LOG_DIR="$BUILD_ROOT/logs"

METADATA="$BUILD_ROOT/build-metadata.env"
FILE_MANIFEST="$BUILD_ROOT/staged-files.manifest"
HASH_MANIFEST="$BUILD_ROOT/staged-files.sha256"

EXPECTED_MD5="bf908de360308d909e9cc469402ff2ef"
JOBS="${JOBS:-$(nproc)}"

usage() {
    cat <<USAGE
Usage:
  $0 --stage
  $0 --inspect
  $0 --clean
USAGE
}

case "${1:-}" in
    --stage)
        ;;
    --inspect)
        test -f "$METADATA" && cat "$METADATA" || true
        test -d "$STAGE_DIR" &&
            find "$STAGE_DIR" -xdev \
                -printf '%y %m %u:%g %s %p -> %l\n' |
                LC_ALL=C sort
        exit 0
        ;;
    --clean)
        rm -rf -- "$BUILD_ROOT"
        echo "Removed: $BUILD_ROOT"
        exit 0
        ;;
    -h|--help|"")
        usage
        exit 0
        ;;
    *)
        sable_die "unknown argument: ${1:-}"
        ;;
esac

echo "=== RPCSVC-PROTO CANONICAL STAGED BUILD ==="

sable_require_repo "$REPO" development
sable_require_command \
    gcc make install tar md5sum sha256sum find sort file readelf git sudo

test -f "$SOURCE_METADATA" ||
    sable_die "missing source metadata"

grep -qx 'ARCHIVE_VERIFIED=true' "$SOURCE_METADATA" ||
    sable_die "source archive is not recorded as verified"

test "$(md5sum "$TARBALL" | awk '{print $1}')" = "$EXPECTED_MD5" ||
    sable_die "source MD5 mismatch"

rm -rf -- "$SOURCE_DIR" "$BUILD_DIR" "$STAGE_DIR" "$LOG_DIR"

install -d -m 0755 \
    "$SOURCE_DIR" \
    "$BUILD_DIR" \
    "$STAGE_DIR" \
    "$LOG_DIR"

tar -xJf "$TARBALL" \
    --strip-components=1 \
    -C "$SOURCE_DIR"

test -x "$SOURCE_DIR/configure" ||
    sable_die "configure script missing"

echo
echo "=== CONFIGURE ==="

(
    cd "$BUILD_DIR"

    "$SOURCE_DIR/configure" \
        --prefix=/usr
) 2>&1 | tee "$LOG_DIR/configure.log"

echo
echo "=== COMPILE ==="

make \
    -C "$BUILD_DIR" \
    -j "$JOBS" \
    2>&1 | tee "$LOG_DIR/build.log"

echo
echo "=== STAGE ==="

make \
    -C "$BUILD_DIR" \
    DESTDIR="$STAGE_DIR" \
    install \
    2>&1 | tee "$LOG_DIR/install.log"

sable_normalize_stage_ownership "$STAGE_DIR"
sable_verify_no_special_files "$STAGE_DIR"

echo
echo "=== VALIDATE STAGED PAYLOAD ==="

test -x "$STAGE_DIR/usr/bin/rpcgen" ||
    sable_die "staged rpcgen executable missing"

test -d "$STAGE_DIR/usr/include/rpcsvc" ||
    sable_die "staged rpcsvc headers missing"

test -f "$STAGE_DIR/usr/include/rpcsvc/nfs_prot.h" ||
    sable_die "representative rpcsvc header missing: nfs_prot.h"

test -f "$STAGE_DIR/usr/include/rpcsvc/mount.h" ||
    sable_die "representative rpcsvc header missing: mount.h"

test -f "$STAGE_DIR/usr/include/rpcsvc/bootparam_prot.h" ||
    sable_die "representative rpcsvc header missing: bootparam_prot.h"

file "$STAGE_DIR/usr/bin/rpcgen"

readelf -d "$STAGE_DIR/usr/bin/rpcgen" |
    grep -E 'NEEDED|RPATH|RUNPATH' || true

echo "PASS: rpcgen staged"
echo "PASS: RPC protocol headers staged"
echo "PASS: no special files staged"

echo
echo "=== CREATE MANIFESTS ==="

sable_write_stage_manifests \
    "$STAGE_DIR" \
    "$FILE_MANIFEST" \
    "$HASH_MANIFEST"

sable_verify_stage_hashes "$STAGE_DIR" "$HASH_MANIFEST"

cat > "$METADATA" <<META
PACKAGE=$PACKAGE
VERSION=$VERSION
BUILD_STATE=staged
BUILT_AT=$(date --iso-8601=seconds)
CANONICAL_HOST=$(hostname)
BUILD_USER=$(id -un)
BUILD_GROUP=$(id -gn)
KERNEL_RELEASE=$(uname -r)
SABLELINUX_REPOSITORY=$REPO
SABLELINUX_GIT_BRANCH=$(git -C "$REPO" branch --show-current)
SABLELINUX_GIT_COMMIT=$(git -C "$REPO" rev-parse HEAD)
SABLELINUX_GIT_DIRTY=$(
    if test -n "$(git -C "$REPO" status --porcelain)"; then
        echo true
    else
        echo false
    fi
)
SOURCE_ARCHIVE=$TARBALL
SOURCE_MD5=$(md5sum "$TARBALL" | awk '{print $1}')
SOURCE_SHA256=$(sha256sum "$TARBALL" | awk '{print $1}')
SOURCE_ARCHIVE_VERIFIED=true
PREFIX=/usr
SOURCE_DIR=$SOURCE_DIR
BUILD_DIR=$BUILD_DIR
STAGE_DIR=$STAGE_DIR
STAGED_MANIFEST=$FILE_MANIFEST
STAGED_MANIFEST_SHA256=$(sha256sum "$FILE_MANIFEST" | awk '{print $1}')
STAGED_FILE_HASHES=$HASH_MANIFEST
STAGED_FILE_HASHES_SHA256=$(sha256sum "$HASH_MANIFEST" | awk '{print $1}')
COMMON_FRAMEWORK=$SCRIPT_DIR/common.sh
COMMON_FRAMEWORK_SHA256=$(sha256sum "$SCRIPT_DIR/common.sh" | awk '{print $1}')
BUILD_SCRIPT=$SCRIPT_DIR/build-rpcsvc-proto.sh
BUILD_SCRIPT_SHA256=$(sha256sum "$SCRIPT_DIR/build-rpcsvc-proto.sh" | awk '{print $1}')
ACTIVATION_REQUIRED=true
META

echo
echo "=== BUILD RESULT ==="
echo "PASS: rpcsvc-proto $VERSION built"
echo "PASS: isolated staged payload validated"
echo "PASS: manifests and metadata generated"
echo "NOT DONE: running-system activation"
