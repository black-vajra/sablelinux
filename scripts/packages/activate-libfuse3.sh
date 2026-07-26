#!/usr/bin/env bash
set -euo pipefail

PACKAGE="libfuse"
VERSION="3.18.2"

REPO="${SABLELINUX_REPO:-$HOME/sablelinux}"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

BUILD_ROOT="/srv/sablelinux/package-builds/libfuse/${VERSION}"
STAGE_DIR="$BUILD_ROOT/stage"
BUILD_METADATA="$BUILD_ROOT/build-metadata.env"
HASH_MANIFEST="$BUILD_ROOT/staged-files.sha256"

usage() {
    cat <<USAGE
Usage:
  $0 --preflight
  $0 --validate

Activation is intentionally disabled until preflight is reviewed and approved.
USAGE
}

preflight() {
    local collisions

    echo "=== LIBFUSE3 ACTIVATION PREFLIGHT ==="

    sable_require_repo "$REPO" development
    sable_require_command find sort sha256sum git pkg-config

    test -f "$BUILD_METADATA" ||
        sable_die "missing staged build metadata"

    grep -qx 'BUILD_STATE=staged' "$BUILD_METADATA" ||
        sable_die "package is not marked staged"

    test -d "$STAGE_DIR/usr" ||
        sable_die "staged /usr payload is missing"

    sable_verify_absent "$STAGE_DIR/dev/fuse"
    sable_verify_absent "$STAGE_DIR/etc/init.d/fuse3"
    sable_verify_no_special_files "$STAGE_DIR"
    sable_verify_stage_hashes "$STAGE_DIR" "$HASH_MANIFEST"

    echo "PASS: staged payload contains no special files"
    echo "PASS: no packaged runtime /dev/fuse node"
    echo "PASS: no packaged SysV fuse3 script"
    echo "PASS: staged file hashes verified"

    echo
    echo "=== STAGED UDEV RULE ==="
    cat "$STAGE_DIR/usr/lib/udev/rules.d/99-fuse3.rules"

    echo
    echo "=== STAGED FUSE CONFIGURATION ==="
    sed -n '1,200p' "$STAGE_DIR/etc/fuse.conf"

    echo
    echo "=== STAGED PAYLOAD ==="

    find "$STAGE_DIR" -xdev \
        -printf '%y %m %u:%g %s %p -> %l\n' |
        LC_ALL=C sort

    echo
    echo "=== EXISTING DESTINATION COLLISIONS ==="

    collisions="$(
        {
            while IFS= read -r staged_path; do
                destination="${staged_path#"$STAGE_DIR"}"

                if test -e "$destination" || test -L "$destination"; then
                    printf '%s\n' "$destination"
                fi
            done < <(
                find "$STAGE_DIR" \
                    \( -type f -o -type l \) |
                    LC_ALL=C sort
            )
        }
    )"

    if test -n "$collisions"; then
        printf '%s\n' "$collisions"
        echo
        echo "Collision count: $(printf '%s\n' "$collisions" | wc -l)"
    else
        echo "None"
        echo
        echo "Collision count: 0"
    fi

    echo
    echo "=== LIVE FUSE STATE ==="

    if test -e /dev/fuse; then
        stat -c '%F %A %a %U:%G %t:%T %n' /dev/fuse
    else
        echo "/dev/fuse is absent"
    fi

    lsmod | grep '^fuse' || echo "fuse kernel module not listed"
    grep -w fuse /proc/filesystems || true

    echo
    echo "PASS: activation preflight completed"
    echo "NOT DONE: running-system activation"
}

validate_runtime() {
    echo "=== VALIDATE ACTIVE LIBFUSE3 ==="

    command -v fusermount3 >/dev/null 2>&1 ||
        sable_die "fusermount3 is not on PATH"

    test -x /usr/sbin/mount.fuse3 ||
        sable_die "/usr/sbin/mount.fuse3 is missing"

    test -e /dev/fuse ||
        sable_die "/dev/fuse is missing"

    pkg-config --exists fuse3 ||
        sable_die "pkg-config cannot find fuse3"

    echo "fusermount3: $(command -v fusermount3)"
    ls -l /usr/bin/fusermount3 /usr/sbin/mount.fuse3
    stat -c '%F %A %a %U:%G %t:%T %n' /dev/fuse
    pkg-config --modversion fuse3
    pkg-config --cflags --libs fuse3
    ldconfig -p | grep 'libfuse3\.so' || true

    echo "PASS: active libfuse3 runtime validated"
}

case "${1:-}" in
    --preflight)
        preflight
        ;;
    --validate)
        validate_runtime
        ;;
    --activate)
        sable_die "activation remains intentionally disabled pending review"
        ;;
    -h|--help|"")
        usage
        ;;
    *)
        sable_die "unknown argument: ${1:-}"
        ;;
esac
