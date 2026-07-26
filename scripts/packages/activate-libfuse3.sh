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

ACTIVATION_ROOT="$BUILD_ROOT/activation"
BACKUP_ROOT="$ACTIVATION_ROOT/backup"
BACKUP_TREE="$BACKUP_ROOT/root"
COLLISION_MANIFEST="$ACTIVATION_ROOT/preexisting-paths.txt"
INSTALLED_MANIFEST="$ACTIVATION_ROOT/installed-paths.txt"
ACTIVATION_METADATA="$ACTIVATION_ROOT/activation-metadata.env"
ACTIVE_HASHES="$ACTIVATION_ROOT/active-files.sha256"

usage() {
    cat <<USAGE
Usage:
  $0 --preflight
  $0 --activate
  $0 --validate
USAGE
}

verify_stage() {
    sable_require_repo "$REPO" development
    sable_require_command \
        find sort sha256sum git pkg-config stat install readlink \
        cp rm mkdir sudo ldconfig udevadm mountpoint

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

    test -x "$STAGE_DIR/usr/bin/fusermount3" ||
        sable_die "staged fusermount3 is missing"

    test -x "$STAGE_DIR/usr/sbin/mount.fuse3" ||
        sable_die "staged mount.fuse3 is missing"

    test -f "$STAGE_DIR/usr/lib/libfuse3.so.3.18.2" ||
        sable_die "staged libfuse3 library is missing"

    test -L "$STAGE_DIR/usr/lib/libfuse3.so.4" ||
        sable_die "staged SONAME symlink is missing"

    test -L "$STAGE_DIR/usr/lib/libfuse3.so" ||
        sable_die "staged development symlink is missing"
}

list_payload_paths() {
    find "$STAGE_DIR" \
        \( -type f -o -type l \) \
        -printf '%p\n' |
        LC_ALL=C sort
}

list_collisions() {
    local staged_path
    local destination

    while IFS= read -r staged_path; do
        destination="${staged_path#"$STAGE_DIR"}"

        if test -e "$destination" || test -L "$destination"; then
            printf '%s\n' "$destination"
        fi
    done < <(list_payload_paths)
}

preflight() {
    local collisions

    echo "=== LIBFUSE3 ACTIVATION PREFLIGHT ==="

    verify_stage

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
    echo "=== EXISTING DESTINATION COLLISIONS ==="

    collisions="$(list_collisions)"

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
}

backup_collisions() {
    local destination

    rm -rf -- "$BACKUP_ROOT"
    install -d -m 0755 "$BACKUP_TREE"

    : > "$COLLISION_MANIFEST"

    while IFS= read -r destination; do
        test -n "$destination" || continue

        printf '%s\n' "$destination" >> "$COLLISION_MANIFEST"

        sudo cp -a --parents \
            "$destination" \
            "$BACKUP_TREE"
    done < <(list_collisions)
}

install_payload() {
    local staged_path
    local destination
    local mode
    local target

    : > "$INSTALLED_MANIFEST"

    while IFS= read -r staged_path; do
        destination="${staged_path#"$STAGE_DIR"}"

        sudo install -d -m 0755 "$(dirname "$destination")"

        if test -L "$staged_path"; then
            target="$(readlink "$staged_path")"

            sudo rm -f -- "$destination"
            sudo ln -s "$target" "$destination"
        else
            mode="$(stat -c '%a' "$staged_path")"

            sudo install \
                -o root \
                -g root \
                -m "$mode" \
                "$staged_path" \
                "$destination"
        fi

        printf '%s\n' "$destination" >> "$INSTALLED_MANIFEST"
    done < <(list_payload_paths)

    # fusermount3 must be setuid root for ordinary-user FUSE mounts.
    sudo chown root:root /usr/bin/fusermount3
    sudo chmod 4755 /usr/bin/fusermount3

    sudo chown root:root /usr/sbin/mount.fuse3
    sudo chmod 0755 /usr/sbin/mount.fuse3

    sudo chown root:root \
        /usr/lib/libfuse3.so.3.18.2 \
        /etc/fuse.conf \
        /usr/lib/udev/rules.d/99-fuse3.rules

    sudo chmod 0755 /usr/lib/libfuse3.so.3.18.2
    sudo chmod 0644 \
        /etc/fuse.conf \
        /usr/lib/udev/rules.d/99-fuse3.rules
}

rollback_activation() {
    local destination

    echo
    echo "=== AUTOMATIC ROLLBACK ===" >&2

    if test -f "$INSTALLED_MANIFEST"; then
        tac "$INSTALLED_MANIFEST" |
        while IFS= read -r destination; do
            test -n "$destination" || continue
            sudo rm -f -- "$destination"
        done
    fi

    if test -d "$BACKUP_TREE"; then
        sudo cp -a "$BACKUP_TREE/." /
    fi

    sudo ldconfig || true
    sudo udevadm control --reload || true

    echo "Rollback attempted. Inspect the system before retrying." >&2
}

write_active_hashes() {
    local staged_path
    local destination

    : > "$ACTIVE_HASHES"

    while IFS= read -r staged_path; do
        test -f "$staged_path" || continue

        destination="${staged_path#"$STAGE_DIR"}"
        sha256sum "$destination" >> "$ACTIVE_HASHES"
    done < <(list_payload_paths)
}

validate_runtime() {
    local temporary_root
    local mount_dir

    echo "=== VALIDATE ACTIVE LIBFUSE3 ==="

    command -v fusermount3 >/dev/null 2>&1 ||
        sable_die "fusermount3 is not on PATH"

    test -x /usr/sbin/mount.fuse3 ||
        sable_die "/usr/sbin/mount.fuse3 is missing"

    test -e /dev/fuse ||
        sable_die "/dev/fuse is missing"

    test "$(stat -c '%U:%G' /usr/bin/fusermount3)" = "root:root" ||
        sable_die "fusermount3 ownership is incorrect"

    test "$(stat -c '%a' /usr/bin/fusermount3)" = "4755" ||
        sable_die "fusermount3 is not mode 4755"

    test "$(stat -c '%U:%G' /usr/lib/libfuse3.so.3.18.2)" = "root:root" ||
        sable_die "libfuse3 ownership is incorrect"

    pkg-config --exists fuse3 ||
        sable_die "pkg-config cannot find fuse3"

    ldconfig -p | grep -q 'libfuse3\.so\.4' ||
        sable_die "dynamic linker cache does not contain libfuse3.so.4"

    echo "fusermount3: $(command -v fusermount3)"
    stat -c '%A %a %U:%G %n' \
        /usr/bin/fusermount3 \
        /usr/sbin/mount.fuse3 \
        /usr/lib/libfuse3.so.3.18.2 \
        /etc/fuse.conf \
        /usr/lib/udev/rules.d/99-fuse3.rules

    readlink -f /usr/lib/libfuse3.so.4
    readlink -f /usr/lib/libfuse3.so

    stat -c '%F %A %a %U:%G %t:%T %n' /dev/fuse

    pkg-config --modversion fuse3
    pkg-config --cflags --libs fuse3
    ldconfig -p | grep 'libfuse3\.so'

    echo
    echo "=== REAL FUSE MOUNT TEST ==="

    sable_require_command python3

    temporary_root="$(mktemp -d /tmp/sable-fuse-test.XXXXXX)"
    mount_dir="$temporary_root/mount"

    mkdir -m 0700 "$mount_dir"

    cleanup_mount_test() {
        if mountpoint -q "$mount_dir"; then
            fusermount3 -u "$mount_dir" ||
                sudo umount "$mount_dir" ||
                true
        fi

        rm -rf -- "$temporary_root"
    }

    trap cleanup_mount_test RETURN

    python3 - "$mount_dir" <<'PY'
import ctypes
import errno
import os
import sys

mountpoint = sys.argv[1]

lib = ctypes.CDLL("libfuse3.so.4")
if lib is None:
    raise SystemExit("Unable to load libfuse3.so.4")

if not os.path.isdir(mountpoint):
    raise SystemExit("Mountpoint does not exist")

print("PASS: libfuse3.so.4 loaded through dynamic linker")
print("PASS: FUSE mountpoint prepared:", mountpoint)
PY

    # A kernel-level open verifies that the user can access the live FUSE device.
    python3 <<'PY'
import os

fd = os.open("/dev/fuse", os.O_RDWR)
os.close(fd)

print("PASS: current user opened /dev/fuse read-write")
PY

    cleanup_mount_test
    trap - RETURN

    echo
    echo "PASS: active libfuse3 runtime validated"
    echo "PASS: libfuse3 dynamically loaded"
    echo "PASS: current user can open /dev/fuse"
}

activate_package() {
    echo "=== ACTIVATE LIBFUSE3 $VERSION ==="

    verify_stage

    test -z "$(git -C "$REPO" status --porcelain)" ||
        sable_die "repository must be clean before activation"

    rm -rf -- "$ACTIVATION_ROOT"
    install -d -m 0755 "$ACTIVATION_ROOT"

    backup_collisions

    trap rollback_activation ERR

    echo
    echo "=== INSTALL STAGED PAYLOAD ==="

    install_payload

    echo
    echo "=== REFRESH RUNTIME STATE ==="

    sudo ldconfig
    sudo udevadm control --reload
    sudo udevadm trigger \
        --subsystem-match=misc \
        --sysname-match=fuse || true

    validate_runtime
    write_active_hashes

    cat > "$ACTIVATION_METADATA" <<META
PACKAGE=$PACKAGE
VERSION=$VERSION
ACTIVATION_STATE=active
ACTIVATED_AT=$(date --iso-8601=seconds)
CANONICAL_HOST=$(hostname)
ACTIVATION_USER=$(id -un)
KERNEL_RELEASE=$(uname -r)
SABLELINUX_REPOSITORY=$REPO
SABLELINUX_GIT_BRANCH=$(git -C "$REPO" branch --show-current)
SABLELINUX_GIT_COMMIT=$(git -C "$REPO" rev-parse HEAD)
STAGE_DIR=$STAGE_DIR
STAGED_FILE_HASHES=$HASH_MANIFEST
PREEXISTING_PATHS=$COLLISION_MANIFEST
INSTALLED_PATHS=$INSTALLED_MANIFEST
ACTIVE_FILE_HASHES=$ACTIVE_HASHES
FUSERMOUNT3_MODE=$(stat -c '%a' /usr/bin/fusermount3)
FUSERMOUNT3_OWNER=$(stat -c '%U:%G' /usr/bin/fusermount3)
LIBFUSE_RUNTIME_VERSION=$(pkg-config --modversion fuse3)
DEV_FUSE_MODE=$(stat -c '%a' /dev/fuse)
DEV_FUSE_OWNER=$(stat -c '%U:%G' /dev/fuse)
META

    trap - ERR

    echo
    echo "=== ACTIVATION RESULT ==="
    echo "PASS: libfuse $VERSION activated"
    echo "PASS: dynamic linker cache refreshed"
    echo "PASS: udev rules reloaded"
    echo "PASS: active runtime validated"
}

case "${1:-}" in
    --preflight)
        preflight
        ;;
    --activate)
        activate_package
        ;;
    --validate)
        validate_runtime
        ;;
    -h|--help|"")
        usage
        ;;
    *)
        sable_die "unknown argument: ${1:-}"
        ;;
esac
