#!/usr/bin/env bash
set -euo pipefail

PACKAGE="libfuse"
VERSION="3.18.2"

REPO="${SABLELINUX_REPO:-$HOME/sablelinux}"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

SOURCE_ROOT="/srv/sablelinux/sources/libfuse"
TARBALL="$SOURCE_ROOT/fuse-${VERSION}.tar.gz"
SOURCE_METADATA="$SOURCE_ROOT/source-metadata.env"

BUILD_ROOT="/srv/sablelinux/package-builds/libfuse/${VERSION}"
SOURCE_DIR="$BUILD_ROOT/source"
BUILD_DIR="$BUILD_ROOT/build"
STAGE_DIR="$BUILD_ROOT/stage"
LOG_DIR="$BUILD_ROOT/logs"

METADATA="$BUILD_ROOT/build-metadata.env"
FILE_MANIFEST="$BUILD_ROOT/staged-files.manifest"
HASH_MANIFEST="$BUILD_ROOT/staged-files.sha256"

EXPECTED_SHA256="f01de85717e20adf5f98aff324acd85dd73d61a5ca3834d573dcf0bd6e54a298"
JOBS="${JOBS:-$(nproc)}"

usage() {
    cat <<USAGE
Usage:
  $0 --stage
  $0 --clean
  $0 --inspect
USAGE
}

inspect_build() {
    echo "=== LIBFUSE3 STAGED BUILD INSPECTION ==="

    if test -f "$METADATA"; then
        cat "$METADATA"
    else
        echo "No completed build metadata."
    fi

    echo
    if test -d "$STAGE_DIR"; then
        du -sh "$STAGE_DIR"
        find "$STAGE_DIR" -xdev \
            -printf '%y %m %u:%g %s %p -> %l\n' |
            LC_ALL=C sort
    else
        echo "No staged payload."
    fi
}

case "${1:-}" in
    --stage)
        ;;
    --clean)
        rm -rf -- "$BUILD_ROOT"
        echo "Removed: $BUILD_ROOT"
        exit 0
        ;;
    --inspect)
        inspect_build
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

echo "=== LIBFUSE3 CANONICAL STAGED BUILD ==="
echo "Package: $PACKAGE"
echo "Version: $VERSION"
echo "Host:    $(hostname)"
echo "Kernel:  $(uname -r)"
echo "Jobs:    $JOBS"

echo
echo "=== PRECONDITIONS ==="

sable_require_repo "$REPO" development

sable_require_command \
    meson ninja pkg-config gcc python3 tar sha256sum \
    find sort file readelf sudo git

test -f "$SOURCE_METADATA" ||
    sable_die "missing source metadata: $SOURCE_METADATA"

grep -qx 'SIGNATURE_VERIFIED=true' "$SOURCE_METADATA" ||
    sable_die "source signature is not recorded as verified"

sable_verify_sha256 "$TARBALL" "$EXPECTED_SHA256"

echo "PASS: source metadata verified"
echo "PASS: pinned source SHA256 matches"
echo "PASS: required tools available"

echo
echo "=== RESET BUILD TREE ==="

rm -rf -- "$SOURCE_DIR" "$BUILD_DIR" "$STAGE_DIR" "$LOG_DIR"

install -d -m 0755 \
    "$SOURCE_DIR" \
    "$BUILD_DIR" \
    "$STAGE_DIR" \
    "$LOG_DIR"

tar -xzf "$TARBALL" \
    --strip-components=1 \
    -C "$SOURCE_DIR"

test -f "$SOURCE_DIR/meson.build" ||
    sable_die "extracted source lacks meson.build"

echo
echo "=== CONFIGURE ==="

meson setup \
    "$BUILD_DIR" \
    "$SOURCE_DIR" \
    --prefix=/usr \
    --libdir=lib \
    --buildtype=release \
    -Dexamples=false \
    -Dtests=false \
    2>&1 | tee "$LOG_DIR/configure.log"

echo
echo "=== COMPILE ==="

meson compile \
    -C "$BUILD_DIR" \
    -j "$JOBS" \
    2>&1 | tee "$LOG_DIR/build.log"

echo
echo "=== CREATE ISOLATED STAGED ARTIFACT ==="

sudo env \
    DESTDIR="$STAGE_DIR" \
    PATH="$PATH" \
    meson install \
        -C "$BUILD_DIR" \
        --no-rebuild \
        2>&1 | tee "$LOG_DIR/install.log"

echo
echo "=== NORMALIZE STAGE OWNERSHIP ==="

sable_normalize_stage_ownership "$STAGE_DIR"

echo
echo "=== SANITIZE STAGED ARTIFACT ==="

sable_remove_runtime_device "$STAGE_DIR" "/dev/fuse"
sable_remove_staged_path "$STAGE_DIR" "/etc/init.d/fuse3"

sable_verify_absent "$STAGE_DIR/dev/fuse"
sable_verify_absent "$STAGE_DIR/etc/init.d/fuse3"
sable_verify_no_special_files "$STAGE_DIR"

echo "PASS: runtime device nodes excluded"
echo "PASS: obsolete SysV integration excluded"
echo "PASS: staged artifact contains no special files"

echo
echo "=== VALIDATE STAGED PAYLOAD ==="

test -x "$STAGE_DIR/usr/bin/fusermount3" ||
    sable_die "missing staged fusermount3"

test -x "$STAGE_DIR/usr/sbin/mount.fuse3" ||
    sable_die "missing staged mount.fuse3"

test -f "$STAGE_DIR/usr/lib/libfuse3.so.3.18.2" ||
    sable_die "missing staged libfuse3 library"

test -L "$STAGE_DIR/usr/lib/libfuse3.so.4" ||
    sable_die "missing staged libfuse3 SONAME link"

test -L "$STAGE_DIR/usr/lib/libfuse3.so" ||
    sable_die "missing staged libfuse3 development link"

test -f "$STAGE_DIR/usr/lib/pkgconfig/fuse3.pc" ||
    sable_die "missing staged fuse3.pc"

test -f "$STAGE_DIR/usr/include/fuse3/fuse.h" ||
    sable_die "missing staged fuse3 headers"

test -f "$STAGE_DIR/etc/fuse.conf" ||
    sable_die "missing staged fuse.conf"

test -f "$STAGE_DIR/usr/lib/udev/rules.d/99-fuse3.rules" ||
    sable_die "missing staged udev rule"

echo "PASS: required runtime payload present"
echo "PASS: required development payload present"
echo "PASS: fuse.conf and udev integration present"

echo
echo "=== BINARY INSPECTION ==="

file \
    "$STAGE_DIR/usr/bin/fusermount3" \
    "$STAGE_DIR/usr/sbin/mount.fuse3" \
    "$STAGE_DIR/usr/lib/libfuse3.so.3.18.2"

readelf -d "$STAGE_DIR/usr/lib/libfuse3.so.3.18.2" |
    grep -E 'NEEDED|SONAME|RPATH|RUNPATH' || true

echo
echo "=== STAGED PKG-CONFIG VALIDATION ==="

PKG_CONFIG_PATH="$STAGE_DIR/usr/lib/pkgconfig" \
pkg-config --modversion fuse3

PKG_CONFIG_PATH="$STAGE_DIR/usr/lib/pkgconfig" \
pkg-config --cflags --libs fuse3

echo
echo "=== CREATE MANIFESTS ==="

sable_write_stage_manifests \
    "$STAGE_DIR" \
    "$FILE_MANIFEST" \
    "$HASH_MANIFEST"

sable_verify_stage_hashes "$STAGE_DIR" "$HASH_MANIFEST"

echo
echo "=== WRITE BUILD METADATA ==="

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
SOURCE_SHA256=$(sha256sum "$TARBALL" | awk '{print $1}')
SOURCE_SIGNATURE_VERIFIED=true
MESON_VERSION=$(meson --version)
NINJA_VERSION=$(ninja --version)
GCC_VERSION=$(gcc -dumpfullversion)
PREFIX=/usr
LIBDIR=lib
BUILD_TYPE=release
EXAMPLES=false
TESTS=false
SOURCE_DIR=$SOURCE_DIR
BUILD_DIR=$BUILD_DIR
STAGE_DIR=$STAGE_DIR
STAGED_MANIFEST=$FILE_MANIFEST
STAGED_MANIFEST_SHA256=$(sha256sum "$FILE_MANIFEST" | awk '{print $1}')
STAGED_FILE_HASHES=$HASH_MANIFEST
STAGED_FILE_HASHES_SHA256=$(sha256sum "$HASH_MANIFEST" | awk '{print $1}')
COMMON_FRAMEWORK=$SCRIPT_DIR/common.sh
COMMON_FRAMEWORK_SHA256=$(sha256sum "$SCRIPT_DIR/common.sh" | awk '{print $1}')
BUILD_SCRIPT=$SCRIPT_DIR/build-libfuse3.sh
BUILD_SCRIPT_SHA256=$(sha256sum "$SCRIPT_DIR/build-libfuse3.sh" | awk '{print $1}')
ACTIVATION_REQUIRED=true
META

echo
echo "=== BUILD METADATA ==="
cat "$METADATA"

echo
echo "=== BUILD RESULT ==="
echo "PASS: libfuse $VERSION compiled"
echo "PASS: sanitized staged artifact created"
echo "PASS: manifests and metadata generated"
echo "NOT DONE: running-system activation"
