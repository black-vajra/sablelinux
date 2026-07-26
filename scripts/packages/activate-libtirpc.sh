#!/usr/bin/env bash
set -euo pipefail

PACKAGE="libtirpc"
VERSION="1.3.7"

REPO="${SABLELINUX_REPO:-$HOME/sablelinux}"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

BUILD_ROOT="/srv/sablelinux/package-builds/$PACKAGE/$VERSION"
STAGE_DIR="$BUILD_ROOT/stage"
BUILD_METADATA="$BUILD_ROOT/build-metadata.env"
FILE_MANIFEST="$BUILD_ROOT/staged-files.manifest"
HASH_MANIFEST="$BUILD_ROOT/staged-files.sha256"

BACKUP_ROOT="/srv/sablelinux/package-backups/$PACKAGE"
ACTIVATION_METADATA="$BUILD_ROOT/activation-metadata.env"

usage() {
    cat <<USAGE
Usage:
  $0 --preflight
  sudo $0 --activate
USAGE
}

verify_stage() {
    test -d "$STAGE_DIR" ||
        sable_die "staged payload missing"

    test -f "$BUILD_METADATA" ||
        sable_die "build metadata missing"

    test -f "$FILE_MANIFEST" ||
        sable_die "file manifest missing"

    test -f "$HASH_MANIFEST" ||
        sable_die "hash manifest missing"

    grep -qx 'PACKAGE=libtirpc' "$BUILD_METADATA" ||
        sable_die "wrong package metadata"

    grep -qx 'VERSION=1.3.7' "$BUILD_METADATA" ||
        sable_die "wrong package version"

    grep -qx 'BUILD_STATE=staged' "$BUILD_METADATA" ||
        sable_die "build is not staged"

    grep -qx 'STAGED_LIBTIRPC_VERSION=1.3.7' "$BUILD_METADATA" ||
        sable_die "staged version metadata mismatch"

    grep -qx 'GSSAPI_SUPPORT=false' "$BUILD_METADATA" ||
        sable_die "unexpected GSSAPI build state"

    sable_verify_stage_hashes "$STAGE_DIR" "$HASH_MANIFEST"

    test -f "$STAGE_DIR/usr/lib/libtirpc.so.3.0.0" ||
        sable_die "staged shared library missing"

    test -L "$STAGE_DIR/usr/lib/libtirpc.so.3" ||
        sable_die "staged SONAME symlink missing"

    test -L "$STAGE_DIR/usr/lib/libtirpc.so" ||
        sable_die "staged linker symlink missing"

    test -f "$STAGE_DIR/usr/lib/pkgconfig/libtirpc.pc" ||
        sable_die "staged pkg-config metadata missing"

    test -f "$STAGE_DIR/usr/include/tirpc/rpc/rpc.h" ||
        sable_die "staged RPC header missing"

    test -f "$STAGE_DIR/etc/netconfig" ||
        sable_die "staged netconfig missing"

    test -f "$STAGE_DIR/etc/bindresvport.blacklist" ||
        sable_die "staged bindresvport blacklist missing"

    staged_version="$(
        env \
            -u PKG_CONFIG_PATH \
            PKG_CONFIG_DISABLE_UNINSTALLED=1 \
            PKG_CONFIG_LIBDIR="$STAGE_DIR/usr/lib/pkgconfig" \
            PKG_CONFIG_SYSROOT_DIR="$STAGE_DIR" \
            pkg-config --modversion libtirpc
    )"

    test "$staged_version" = "$VERSION" ||
        sable_die "staged pkg-config version mismatch"

    if find "$STAGE_DIR" -xdev \
        \( -type b -o -type c -o -type p -o -type s \) \
        -print -quit |
        grep -q .
    then
        sable_die "staged payload contains special files"
    fi

    if find "$STAGE_DIR/usr/lib" \
        -maxdepth 1 \
        -type f \
        -name '*.a' \
        -print -quit |
        grep -q .
    then
        sable_die "staged static library present"
    fi
}

verify_repository() {
    sable_require_repo "$REPO" development

    test -z "$(git -C "$REPO" status --porcelain)" ||
        sable_die "repository must be clean before activation"
}

preflight() {
    verify_repository
    verify_stage

    command -v ldconfig >/dev/null 2>&1 ||
        sable_die "ldconfig missing"

    command -v gcc >/dev/null 2>&1 ||
        sable_die "gcc missing"

    command -v pkg-config >/dev/null 2>&1 ||
        sable_die "pkg-config missing"

    if command -v rpcbind >/dev/null 2>&1; then
        sable_die "rpcbind is installed; coordinated review required"
    fi

    live_version="$(
        env \
            -u PKG_CONFIG_PATH \
            PKG_CONFIG_DISABLE_UNINSTALLED=1 \
            pkg-config --modversion libtirpc
    )"

    test "$live_version" = "1.3.6" ||
        sable_die "unexpected pre-activation live version: $live_version"

    live_soname="$(
        readelf -d /usr/lib/libtirpc.so.3.0.0 |
        sed -n 's/.*SONAME.*\[\(.*\)\].*/\1/p'
    )"

    staged_soname="$(
        readelf -d "$STAGE_DIR/usr/lib/libtirpc.so.3.0.0" |
        sed -n 's/.*SONAME.*\[\(.*\)\].*/\1/p'
    )"

    test "$live_soname" = "libtirpc.so.3" ||
        sable_die "unexpected live SONAME"

    test "$staged_soname" = "libtirpc.so.3" ||
        sable_die "unexpected staged SONAME"

    echo "PASS: repository clean"
    echo "PASS: staged payload and hashes valid"
    echo "PASS: live version is 1.3.6"
    echo "PASS: staged version is 1.3.7"
    echo "PASS: SONAME remains libtirpc.so.3"
    echo "PASS: rpcbind absent"
    echo "PASS: activation preflight complete"
}

backup_existing_paths() {
    activation_id="$(date -u +%Y%m%dT%H%M%SZ)"
    backup_dir="$BACKUP_ROOT/$activation_id"
    backup_archive="$backup_dir/pre-activation.tar"
    backup_path_list="$backup_dir/preexisting-paths.txt"

    install -d -m 0755 "$backup_dir"
    : > "$backup_path_list"

    while IFS= read -r staged_path; do
        destination="${staged_path#"$STAGE_DIR"}"

        if test -e "$destination" || test -L "$destination"; then
            printf '%s\n' "${destination#/}" >> "$backup_path_list"
        fi
    done < <(
        find "$STAGE_DIR" \
            \( -type f -o -type l \) \
            -printf '%p\n' |
        LC_ALL=C sort
    )

    if test -s "$backup_path_list"; then
        tar \
            --create \
            --file "$backup_archive" \
            --directory=/ \
            --files-from="$backup_path_list"
    else
        tar \
            --create \
            --file "$backup_archive" \
            --files-from=/dev/null
    fi

    sha256sum "$backup_archive" > "$backup_archive.sha256"

    printf '%s\n' "$activation_id"
}

install_stage() {
    cp \
        --archive \
        --no-preserve=ownership \
        "$STAGE_DIR"/. \
        /

    chown -R root:root \
        /usr/include/tirpc \
        /usr/lib/libtirpc.so.3.0.0 \
        /usr/lib/libtirpc.la \
        /usr/lib/pkgconfig/libtirpc.pc \
        /usr/share/man/man3 \
        /usr/share/man/man5/netconfig.5 \
        /etc/netconfig \
        /etc/bindresvport.blacklist

    chmod 0755 /usr/lib/libtirpc.so.3.0.0
    chmod 0644 /usr/lib/libtirpc.la
    chmod 0644 /usr/lib/pkgconfig/libtirpc.pc
    chmod 0644 /etc/netconfig
    chmod 0644 /etc/bindresvport.blacklist

    ldconfig
}

verify_live() {
    local live_version
    local test_program
    local test_binary

    test -f /usr/lib/libtirpc.so.3.0.0 ||
        sable_die "live shared library missing"

    test -L /usr/lib/libtirpc.so.3 ||
        sable_die "live SONAME symlink missing"

    test -L /usr/lib/libtirpc.so ||
        sable_die "live linker symlink missing"

    test "$(readlink /usr/lib/libtirpc.so.3)" = "libtirpc.so.3.0.0" ||
        sable_die "wrong SONAME symlink target"

    test "$(readlink /usr/lib/libtirpc.so)" = "libtirpc.so.3.0.0" ||
        sable_die "wrong linker symlink target"

    live_version="$(
        env \
            -u PKG_CONFIG_PATH \
            PKG_CONFIG_DISABLE_UNINSTALLED=1 \
            pkg-config --modversion libtirpc
    )"

    test "$live_version" = "$VERSION" ||
        sable_die "live pkg-config version is not $VERSION"

    ldconfig -p |
        grep -q 'libtirpc\.so\.3.*=> /usr/lib/libtirpc\.so\.3' ||
        sable_die "loader cache does not resolve libtirpc.so.3"

    readelf -d /usr/lib/libtirpc.so.3.0.0 |
        grep -q 'SONAME.*\[libtirpc.so.3\]' ||
        sable_die "live SONAME validation failed"

    test -f /etc/netconfig ||
        sable_die "/etc/netconfig missing"

    test -f /etc/bindresvport.blacklist ||
        sable_die "/etc/bindresvport.blacklist missing"

    /usr/bin/lsof -v >/dev/null 2>&1 ||
        sable_die "lsof runtime validation failed"

    ldd /usr/bin/lsof |
        grep -q 'libtirpc\.so\.3 => /usr/lib/libtirpc\.so\.3' ||
        sable_die "lsof does not resolve live libtirpc"

    test_program="$(mktemp --suffix=.c)"
    test_binary="${test_program%.c}"

    cat > "$test_program" <<'C_EOF'
#include <rpc/rpc.h>
#include <stdio.h>
#include <stdlib.h>

int main(void)
{
    char buffer[128];
    XDR xdrs;
    unsigned int input = 0x12345678U;
    unsigned int output = 0U;

    xdrmem_create(&xdrs, buffer, sizeof(buffer), XDR_ENCODE);

    if (!xdr_u_int(&xdrs, &input)) {
        fprintf(stderr, "XDR encode failed\n");
        return EXIT_FAILURE;
    }

    xdr_destroy(&xdrs);

    xdrmem_create(&xdrs, buffer, sizeof(buffer), XDR_DECODE);

    if (!xdr_u_int(&xdrs, &output)) {
        fprintf(stderr, "XDR decode failed\n");
        return EXIT_FAILURE;
    }

    xdr_destroy(&xdrs);

    if (output != input) {
        fprintf(stderr, "XDR round-trip mismatch\n");
        return EXIT_FAILURE;
    }

    printf("libtirpc XDR round-trip PASS: 0x%08x\n", output);
    return EXIT_SUCCESS;
}
C_EOF

    gcc \
        -Wall \
        -Wextra \
        -Werror \
        "$test_program" \
        $(pkg-config --cflags --libs libtirpc) \
        -o "$test_binary"

    "$test_binary"

    rm -f -- "$test_program" "$test_binary"

    echo "PASS: live pkg-config version is $live_version"
    echo "PASS: loader cache refreshed"
    echo "PASS: live SONAME remains libtirpc.so.3"
    echo "PASS: lsof executes with new libtirpc"
    echo "PASS: compiled XDR round-trip test succeeded"
    echo "PASS: configuration files installed"
}

activate() {
    local previous_version
    local activation_id
    local backup_archive

    test "$(id -u)" -eq 0 ||
        sable_die "activation requires root"

    verify_stage

    if command -v rpcbind >/dev/null 2>&1; then
        sable_die "rpcbind is installed; coordinated review required"
    fi

    previous_version="$(
        env \
            -u PKG_CONFIG_PATH \
            PKG_CONFIG_DISABLE_UNINSTALLED=1 \
            pkg-config --modversion libtirpc
    )"

    test "$previous_version" = "1.3.6" ||
        sable_die "unexpected pre-activation live version: $previous_version"

    activation_id="$(backup_existing_paths)"

    install_stage
    verify_live

    backup_archive="$BACKUP_ROOT/$activation_id/pre-activation.tar"

    cat > "$ACTIVATION_METADATA" <<META
PACKAGE=$PACKAGE
VERSION=$VERSION
ACTIVATION_STATE=active
ACTIVATED_AT=$(date --iso-8601=seconds)
ACTIVATION_ID=$activation_id
CANONICAL_HOST=$(hostname)
ACTIVATION_USER=${SUDO_USER:-root}
ACTIVATION_UID=${SUDO_UID:-0}
KERNEL_RELEASE=$(uname -r)
PREVIOUS_VERSION=$previous_version
ACTIVE_VERSION=$VERSION
SONAME=libtirpc.so.3
BACKUP_ARCHIVE=$backup_archive
BACKUP_ARCHIVE_SHA256=$(sha256sum "$backup_archive" | awk '{print $1}')
STAGED_HASH_MANIFEST=$HASH_MANIFEST
STAGED_HASH_MANIFEST_SHA256=$(sha256sum "$HASH_MANIFEST" | awk '{print $1}')
RPCBIND_PRESENT=false
GSSAPI_SUPPORT=false
RUNTIME_LSOF_VALIDATED=true
XDR_ROUNDTRIP_VALIDATED=true
META

    echo
    echo "=== ACTIVATION RESULT ==="
    echo "PASS: libtirpc $VERSION activated"
    echo "PASS: rollback archive created"
    echo "PASS: loader cache refreshed"
    echo "PASS: lsof runtime validation completed"
    echo "PASS: XDR functional validation completed"
}

case "${1:-}" in
    --preflight)
        preflight
        ;;
    --activate)
        activate
        ;;
    -h|--help|"")
        usage
        ;;
    *)
        sable_die "unknown argument: ${1:-}"
        ;;
esac
