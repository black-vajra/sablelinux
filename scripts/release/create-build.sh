#!/usr/bin/env bash
set -Eeuo pipefail

WORKSPACE="/srv/sablelinux"
MIN_FREE_GIB=200
LOCK="$WORKSPACE/state/locks/create-build.lock"

die() {
    echo "ERROR: $*" >&2
    exit 1
}

if [ "$EUID" -ne 0 ]; then
    die "run this script through sudo"
fi

BUILD_USER="${SUDO_USER:-pepper}"
BUILD_GROUP="$(id -gn "$BUILD_USER")"
REPO="/home/$BUILD_USER/sablelinux"

id "$BUILD_USER" >/dev/null 2>&1 ||
    die "build user does not exist: $BUILD_USER"

[ -d "$REPO/.git" ] ||
    die "repository is missing: $REPO"

[ -d "$WORKSPACE/builds" ] ||
    die "canonical workspace is not initialized"

[ -f "$WORKSPACE/state/layout-version" ] ||
    die "workspace layout version is missing"

LAYOUT_VERSION="$(cat "$WORKSPACE/state/layout-version")"

[ "$LAYOUT_VERSION" = "1" ] ||
    die "unsupported workspace layout version: $LAYOUT_VERSION"

git_repo() {
    git -c safe.directory="$REPO" -C "$REPO" "$@"
}

BRANCH="$(git_repo branch --show-current)"
COMMIT="$(git_repo rev-parse HEAD)"
SHORT_COMMIT="$(git_repo rev-parse --short=7 HEAD)"
REPO_STATUS="$(git_repo status --porcelain)"

[ -z "$REPO_STATUS" ] ||
    die "repository contains uncommitted changes"

[ "$BRANCH" = "development" ] ||
    die "canonical builds must currently originate from development"

HOSTNAME_VALUE="$(hostname)"
OS_ID="$(. /etc/os-release && printf '%s' "$ID")"

[ "$HOSTNAME_VALUE" = "SableLinux" ] ||
    die "unexpected canonical hostname: $HOSTNAME_VALUE"

[ "$OS_ID" = "sablelinux" ] ||
    die "running system is not identified as SableLinux"

ROOT_DEVICE="$(findmnt -no SOURCE /)"
WORK_DEVICE="$(findmnt -no SOURCE -T "$WORKSPACE")"

[ "$ROOT_DEVICE" = "$WORK_DEVICE" ] ||
    die "workspace is not on the canonical root filesystem"

FREE_BYTES="$(df -PB1 "$WORKSPACE" | awk 'NR == 2 {print $4}')"
MINIMUM_BYTES=$((MIN_FREE_GIB * 1024 * 1024 * 1024))

case "$FREE_BYTES" in
    ''|*[!0-9]*)
        die "could not determine available workspace capacity"
        ;;
esac

if [ "$FREE_BYTES" -lt "$MINIMUM_BYTES" ]; then
    FREE_GIB=$((FREE_BYTES / 1024 / 1024 / 1024))
    die "only ${FREE_GIB} GiB available; ${MIN_FREE_GIB} GiB required"
fi

if ! mkdir "$LOCK" 2>/dev/null; then
    die "another build-creation process appears to be active"
fi

cleanup() {
    rmdir "$LOCK" 2>/dev/null || true
}

trap cleanup EXIT

CREATED_AT="$(date --utc +%Y-%m-%dT%H:%M:%SZ)"
TIMESTAMP="$(date --utc +%Y%m%dT%H%M%SZ)"
KERNEL_RELEASE="$(uname -r)"
SAFE_KERNEL="${KERNEL_RELEASE//[^A-Za-z0-9._-]/_}"

BUILD_ID="${TIMESTAMP}-${SHORT_COMMIT}-k${SAFE_KERNEL}"
BUILD_ROOT="$WORKSPACE/builds/$BUILD_ID"

[ ! -e "$BUILD_ROOT" ] ||
    die "build directory already exists: $BUILD_ROOT"

DIRECTORIES=(
    "$BUILD_ROOT"
    "$BUILD_ROOT/rootfs"
    "$BUILD_ROOT/boot"
    "$BUILD_ROOT/squashfs"
    "$BUILD_ROOT/initramfs"
    "$BUILD_ROOT/media"
    "$BUILD_ROOT/installer"
    "$BUILD_ROOT/logs"
    "$BUILD_ROOT/metadata"
    "$BUILD_ROOT/reports"
    "$BUILD_ROOT/tmp"
)

for directory in "${DIRECTORIES[@]}"; do
    install -d \
        -o root \
        -g "$BUILD_GROUP" \
        -m 2775 \
        "$directory"
done

cat > "$BUILD_ROOT/BUILD_STATE" <<STATE
initialized
STATE

cat > "$BUILD_ROOT/metadata/build.env" <<METADATA
BUILD_ID=$BUILD_ID
BUILD_STATE=initialized
CREATED_AT=$CREATED_AT
CANONICAL_HOST=$HOSTNAME_VALUE
BUILD_USER=$BUILD_USER
BUILD_GROUP=$BUILD_GROUP
WORKSPACE_LAYOUT_VERSION=$LAYOUT_VERSION
REPOSITORY=$REPO
GIT_BRANCH=$BRANCH
GIT_COMMIT=$COMMIT
GIT_DIRTY=false
KERNEL_RELEASE=$KERNEL_RELEASE
ROOT_DEVICE=$ROOT_DEVICE
METADATA

cp /etc/os-release \
    "$BUILD_ROOT/metadata/os-release"

uname -a \
    > "$BUILD_ROOT/metadata/uname.txt"

hostnamectl \
    > "$BUILD_ROOT/metadata/hostnamectl.txt" 2>&1 ||
    true

findmnt -R / \
    > "$BUILD_ROOT/metadata/mounts.txt"

lsblk -o NAME,PATH,SIZE,FSTYPE,LABEL,UUID,MOUNTPOINTS \
    > "$BUILD_ROOT/metadata/block-devices.txt"

df -hT / "$WORKSPACE" \
    > "$BUILD_ROOT/metadata/storage.txt"

git_repo status --short --branch \
    > "$BUILD_ROOT/metadata/repository-status.txt"

git_repo log -1 --format=fuller \
    > "$BUILD_ROOT/metadata/repository-commit.txt"

git_repo ls-files -s \
    > "$BUILD_ROOT/metadata/repository-index.txt"

cat > "$BUILD_ROOT/metadata/tool-versions.txt" <<TOOLS
$(bash --version | head -n 1)
$(git --version)
$(rsync --version | head -n 1)
$(mksquashfs -version 2>&1 | head -n 1)
$(qemu-system-x86_64 --version | head -n 1)
$(qemu-img --version | head -n 1)
$(grub-install --version)
$(xorriso -version 2>&1 | head -n 1)
TOOLS

KERNEL_IMAGE="/boot/vmlinuz-$KERNEL_RELEASE"
SYSTEM_MAP="/boot/System.map-$KERNEL_RELEASE"
MODULE_ROOT="/lib/modules/$KERNEL_RELEASE"

[ -f "$KERNEL_IMAGE" ] ||
    die "canonical kernel image is missing: $KERNEL_IMAGE"

[ -f "$SYSTEM_MAP" ] ||
    die "canonical System.map is missing: $SYSTEM_MAP"

[ -d "$MODULE_ROOT" ] ||
    die "canonical kernel module tree is missing: $MODULE_ROOT"

sha256sum \
    "$KERNEL_IMAGE" \
    "$SYSTEM_MAP" \
    > "$BUILD_ROOT/metadata/boot-inputs.sha256"

if [ -f "$REPO/build/kernel-config-6.16.1" ]; then
    sha256sum "$REPO/build/kernel-config-6.16.1" \
        > "$BUILD_ROOT/metadata/kernel-config.sha256"
fi

find "$MODULE_ROOT" -type f -print0 |
    sort -z |
    xargs -0 sha256sum \
    > "$BUILD_ROOT/metadata/kernel-modules.sha256"

cat > "$BUILD_ROOT/metadata/package-manifest-status.txt" <<PACKAGES
A current canonical package-manifest generator has not yet been established.

The historical installed-package inventories are evidence only and are not
authoritative for this build. A current manifest must be generated before this
build can be promoted to release-candidate status.
PACKAGES

cat > "$BUILD_ROOT/README.txt" <<README
SableLinux canonical build directory

Build ID: $BUILD_ID
Created: $CREATED_AT
Git commit: $COMMIT
Kernel: $KERNEL_RELEASE
State: initialized

No root filesystem has been generated yet.

The next valid state transition is:

initialized -> rootfs-generated
README

chown -R root:"$BUILD_GROUP" "$BUILD_ROOT"

find "$BUILD_ROOT" -type d -exec chmod 2775 {} +
find "$BUILD_ROOT" -type f -exec chmod 0664 {} +

printf '%s\n' "$BUILD_ID" \
    > "$WORKSPACE/state/current-build-id"

chown root:"$BUILD_GROUP" \
    "$WORKSPACE/state/current-build-id"

chmod 0664 \
    "$WORKSPACE/state/current-build-id"

echo "=== CANONICAL BUILD INITIALIZED ==="
echo "Build ID: $BUILD_ID"
echo "Build root: $BUILD_ROOT"
echo "Git commit: $COMMIT"
echo "Kernel: $KERNEL_RELEASE"
echo "State: initialized"
