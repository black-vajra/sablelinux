#!/usr/bin/env bash
set -euo pipefail

PACKAGE="libtirpc"
VERSION="1.3.7"

REPO="${SABLELINUX_REPO:-$HOME/sablelinux}"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

SOURCE_ROOT="/srv/sablelinux/sources/$PACKAGE"
TARBALL="$SOURCE_ROOT/${PACKAGE}-${VERSION}.tar.bz2"
SOURCE_METADATA="$SOURCE_ROOT/source-metadata.env"

BUILD_ROOT="/srv/sablelinux/package-builds/$PACKAGE/$VERSION"
SOURCE_DIR="$BUILD_ROOT/source"
BUILD_DIR="$BUILD_ROOT/build"
STAGE_DIR="$BUILD_ROOT/stage"
LOG_DIR="$BUILD_ROOT/logs"

METADATA="$BUILD_ROOT/build-metadata.env"
FILE_MANIFEST="$BUILD_ROOT/staged-files.manifest"
HASH_MANIFEST="$BUILD_ROOT/staged-files.sha256"

EXPECTED_MD5="74f97df306b8d6149d3d9898a1d44c6e"
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

        if test -d "$STAGE_DIR"; then
            find "$STAGE_DIR" -xdev \
                -printf '%y %m %u:%g %s %p -> %l\n' |
                LC_ALL=C sort
        fi
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

echo "=== LIBTIRPC 1.3.7 CANONICAL STAGED BUILD ==="

sable_require_repo "$REPO" development
sable_require_command \
    gcc make install tar md5sum sha256sum find sort \
    file readelf pkg-config rpcgen git

test -f "$SOURCE_METADATA" ||
    sable_die "missing source metadata"

grep -qx 'ARCHIVE_VERIFIED=true' "$SOURCE_METADATA" ||
    sable_die "source archive is not recorded as verified"

test "$(md5sum "$TARBALL" | awk '{print $1}')" = "$EXPECTED_MD5" ||
    sable_die "source MD5 mismatch"

command -v rpcgen >/dev/null 2>&1 ||
    sable_die "rpcgen is required to build libtirpc"

test "$(command -v rpcgen)" = "/usr/bin/rpcgen" ||
    sable_die "unexpected rpcgen path"

rm -rf -- "$SOURCE_DIR" "$BUILD_DIR" "$STAGE_DIR" "$LOG_DIR"

install -d -m 0755 \
    "$SOURCE_DIR" \
    "$BUILD_DIR" \
    "$STAGE_DIR" \
    "$LOG_DIR"

tar -xjf "$TARBALL" \
    --strip-components=1 \
    -C "$SOURCE_DIR"

test -x "$SOURCE_DIR/configure" ||
    sable_die "configure script missing"

echo
echo "=== CONFIGURE ==="

(
    cd "$BUILD_DIR"

    "$SOURCE_DIR/configure" \
        --prefix=/usr \
        --sysconfdir=/etc \
        --disable-static \
        --disable-gssapi
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

test -f "$STAGE_DIR/usr/lib/pkgconfig/libtirpc.pc" ||
    sable_die "staged libtirpc pkg-config metadata missing"

test -f "$STAGE_DIR/usr/include/tirpc/rpc/rpc.h" ||
    sable_die "staged primary RPC header missing"

test -f "$STAGE_DIR/usr/include/tirpc/netconfig.h" ||
    sable_die "staged netconfig header missing"

test -f "$STAGE_DIR/etc/netconfig" ||
    sable_die "staged /etc/netconfig missing"

LIBRARY_REAL="$(
    find "$STAGE_DIR/usr/lib" \
        -maxdepth 1 \
        -type f \
        -name 'libtirpc.so.*' \
        -printf '%p\n' |
        LC_ALL=C sort |
        head -n 1
)"

test -n "$LIBRARY_REAL" ||
    sable_die "staged versioned libtirpc shared library missing"

test -L "$STAGE_DIR/usr/lib/libtirpc.so" ||
    sable_die "staged libtirpc linker symlink missing"

file "$LIBRARY_REAL"

readelf -d "$LIBRARY_REAL" |
    grep -E 'SONAME|NEEDED|RPATH|RUNPATH' ||
    sable_die "unable to inspect staged libtirpc dynamic metadata"

if readelf -d "$LIBRARY_REAL" |
    grep -Eq '\((RPATH|RUNPATH)\)'
then
    sable_die "staged libtirpc contains RPATH or RUNPATH"
fi

if find "$STAGE_DIR/usr/lib" \
    -maxdepth 1 \
    -type f \
    -name '*.a' \
    -print -quit |
    grep -q .
then
    sable_die "static libtirpc archive was staged unexpectedly"
fi

STAGED_VERSION="$(
    env \
        -u PKG_CONFIG_PATH \
        PKG_CONFIG_DISABLE_UNINSTALLED=1 \
        PKG_CONFIG_LIBDIR="$STAGE_DIR/usr/lib/pkgconfig" \
        PKG_CONFIG_SYSROOT_DIR="$STAGE_DIR" \
        pkg-config --modversion libtirpc
)"

test "$STAGED_VERSION" = "$VERSION" ||
    sable_die "staged pkg-config version is not $VERSION"

echo "PASS: libtirpc shared library staged"
echo "PASS: libtirpc headers staged"
echo "PASS: /etc/netconfig staged"
echo "PASS: pkg-config reports version $STAGED_VERSION"
echo "PASS: no static library staged"
echo "PASS: no RPATH or RUNPATH present"
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
CONFIGURE_PREFIX=/usr
CONFIGURE_SYSCONFDIR=/etc
STATIC_LIBRARIES=false
GSSAPI_SUPPORT=false
RPCGEN_PATH=$(command -v rpcgen)
RPCGEN_OWNER=$(stat -c '%U:%G' "$(command -v rpcgen)")
SOURCE_DIR=$SOURCE_DIR
BUILD_DIR=$BUILD_DIR
STAGE_DIR=$STAGE_DIR
STAGED_LIBTIRPC_VERSION=$STAGED_VERSION
STAGED_LIBRARY_REAL=$LIBRARY_REAL
STAGED_MANIFEST=$FILE_MANIFEST
STAGED_MANIFEST_SHA256=$(sha256sum "$FILE_MANIFEST" | awk '{print $1}')
STAGED_FILE_HASHES=$HASH_MANIFEST
STAGED_FILE_HASHES_SHA256=$(sha256sum "$HASH_MANIFEST" | awk '{print $1}')
COMMON_FRAMEWORK=$SCRIPT_DIR/common.sh
COMMON_FRAMEWORK_SHA256=$(sha256sum "$SCRIPT_DIR/common.sh" | awk '{print $1}')
BUILD_SCRIPT=$SCRIPT_DIR/build-libtirpc.sh
BUILD_SCRIPT_SHA256=$(sha256sum "$SCRIPT_DIR/build-libtirpc.sh" | awk '{print $1}')
ACTIVATION_REQUIRED=true
RPCBIND_REBUILD_REVIEW_REQUIRED=true
META

echo
echo "=== BUILD RESULT ==="
echo "PASS: libtirpc $VERSION built"
echo "PASS: isolated staged payload validated"
echo "PASS: manifests and metadata generated"
echo "NOT DONE: running-system activation"
echo "NOT DONE: rpcbind compatibility decision"
