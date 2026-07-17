#!/usr/bin/env bash
set -Eeuo pipefail

WORKSPACE="/srv/sablelinux"
MODE="dry-run"
REQUESTED_BUILD_ID=""

usage() {
    cat <<'USAGE'
Usage:

  sudo scripts/live/generate-rootfs.sh --dry-run
  sudo scripts/live/generate-rootfs.sh --execute
  sudo scripts/live/generate-rootfs.sh --build-id BUILD_ID --dry-run
USAGE
}

die() {
    echo "ERROR: $*" >&2
    exit 1
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --dry-run)
            MODE="dry-run"
            shift
            ;;
        --execute)
            MODE="execute"
            shift
            ;;
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

EXCLUDES="$REPO/configs/live/rootfs-excludes.rsync"
DISABLED_SERVICES="$REPO/configs/live/disabled-services.list"
POLICY="$REPO/docs/release/rootfs-generation-policy.md"

[ -f "$EXCLUDES" ] ||
    die "exclusion policy is missing: $EXCLUDES"

[ -f "$DISABLED_SERVICES" ] ||
    die "disabled-service policy is missing: $DISABLED_SERVICES"

[ -f "$POLICY" ] ||
    die "rootfs policy is missing: $POLICY"

if [ -n "$REQUESTED_BUILD_ID" ]; then
    BUILD_ID="$REQUESTED_BUILD_ID"
else
    BUILD_ID="$(cat "$WORKSPACE/state/current-build-id")"
fi

BUILD_ROOT="$WORKSPACE/builds/$BUILD_ID"
ROOTFS="$BUILD_ROOT/rootfs"
BUILD_ENV="$BUILD_ROOT/metadata/build.env"

[ -d "$BUILD_ROOT" ] ||
    die "build directory is missing: $BUILD_ROOT"

[ -d "$ROOTFS" ] ||
    die "rootfs directory is missing: $ROOTFS"

[ -f "$BUILD_ENV" ] ||
    die "build metadata is missing: $BUILD_ENV"

BUILD_STATE="$(cat "$BUILD_ROOT/BUILD_STATE")"

[ "$BUILD_STATE" = "initialized" ] ||
    die "build must be initialized; current state is: $BUILD_STATE"

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

ROOT_DEVICE="$(findmnt -no SOURCE /)"
WORK_DEVICE="$(findmnt -no SOURCE -T "$WORKSPACE")"

[ "$ROOT_DEVICE" = "$WORK_DEVICE" ] ||
    die "workspace is not on the canonical root filesystem"

OBJECT_COUNT="$(
    find "$ROOTFS" -mindepth 1 -print |
    wc -l
)"

[ "$OBJECT_COUNT" -eq 0 ] ||
    die "rootfs is not empty"

TIMESTAMP="$(date --utc +%Y%m%dT%H%M%SZ)"
REPORT="$BUILD_ROOT/reports/rootfs-${MODE}-${TIMESTAMP}.txt"
LOG="$BUILD_ROOT/logs/rootfs-${MODE}-${TIMESTAMP}.log"

RSYNC_OPTIONS=(
    -aH
    -x
    --numeric-ids
    --delete
    --delete-excluded
    --human-readable
    --stats
    --exclude-from="$EXCLUDES"
)

PROBE_ROOT="$BUILD_ROOT/tmp/rsync-capability-probe"
PROBE_SOURCE="$PROBE_ROOT/source"
PROBE_DESTINATION="$PROBE_ROOT/destination"

rm -rf "$PROBE_ROOT"
mkdir -p "$PROBE_SOURCE" "$PROBE_DESTINATION"
touch "$PROBE_SOURCE/test-file"

RSYNC_ACL_SUPPORT="no"
RSYNC_XATTR_SUPPORT="no"

if rsync -aH -A --dry-run     "$PROBE_SOURCE/" "$PROBE_DESTINATION/"     >/dev/null 2>&1
then
    RSYNC_OPTIONS+=(-A)
    RSYNC_ACL_SUPPORT="yes"
fi

if rsync -aH -X --dry-run     "$PROBE_SOURCE/" "$PROBE_DESTINATION/"     >/dev/null 2>&1
then
    RSYNC_OPTIONS+=(-X)
    RSYNC_XATTR_SUPPORT="yes"
fi

rm -rf "$PROBE_ROOT"

if [ "$MODE" = "dry-run" ]; then
    RSYNC_OPTIONS+=(--dry-run)
fi

{
    echo "============================================================"
    echo "SABLELINUX ROOTFS GENERATION"
    echo "============================================================"
    echo "Mode: $MODE"
    echo "Timestamp: $(date --iso-8601=seconds)"
    echo "Build ID: $BUILD_ID"
    echo "Build root: $BUILD_ROOT"
    echo "Source: /"
    echo "Destination: $ROOTFS"
    echo "Git commit: $CURRENT_COMMIT"
    echo "Kernel: $(uname -r)"
    echo "Rsync ACL preservation: $RSYNC_ACL_SUPPORT"
    echo "Rsync xattr preservation: $RSYNC_XATTR_SUPPORT"
    echo

    echo "=== EXCLUSION POLICY HASH ==="
    sha256sum "$EXCLUDES"
    echo

    echo "=== GENERATOR HASH ==="
    sha256sum "$REPO/scripts/live/generate-rootfs.sh"
    echo

    echo "=== EXCLUSION POLICY ==="
    cat "$EXCLUDES"
    echo

    echo "=== RSYNC RESULT ==="
} | tee "$REPORT"

rsync "${RSYNC_OPTIONS[@]}" / "$ROOTFS/" 2>&1 |
    tee "$LOG" |
    tee -a "$REPORT"

if [ "$MODE" = "dry-run" ]; then
    {
        echo
        echo "PASS: dry run completed"
        echo "No rootfs files were copied."
        echo "Build state remains initialized."
        echo
        echo "Report: $REPORT"
        echo "Log: $LOG"
    } | tee -a "$REPORT"

    exit 0
fi

echo
echo "=== SANITIZE GENERATED ROOTFS ===" |
    tee -a "$REPORT"

install -d -m 0755 \
    "$ROOTFS/boot" \
    "$ROOTFS/dev" \
    "$ROOTFS/proc" \
    "$ROOTFS/sys" \
    "$ROOTFS/run" \
    "$ROOTFS/mnt" \
    "$ROOTFS/media" \
    "$ROOTFS/home" \
    "$ROOTFS/var/log" \
    "$ROOTFS/var/cache"

install -d -m 1777 \
    "$ROOTFS/tmp" \
    "$ROOTFS/var/tmp"

install -d -m 0700 \
    "$ROOTFS/root"

rm -rf \
    "$ROOTFS/home/pepper" \
    "$ROOTFS/home/tester"

rm -f \
    "$ROOTFS/etc/ssh"/ssh_host_* \
    "$ROOTFS/var/lib/systemd/random-seed"

rm -rf \
    "$ROOTFS/etc/wireguard" \
    "$ROOTFS/etc/NetworkManager/system-connections" \
    "$ROOTFS/etc/wpa_supplicant" \
    "$ROOTFS/etc/ssl/private" \
    "$ROOTFS/etc/pki/private" \
    "$ROOTFS/etc/letsencrypt"

printf '%s\n' "sablelinux" \
    > "$ROOTFS/etc/hostname"

cat > "$ROOTFS/etc/hosts" <<'HOSTS'
127.0.0.1 localhost
127.0.1.1 sablelinux

::1 localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
HOSTS

cat > "$ROOTFS/etc/fstab" <<'FSTAB'
# SableLinux live-root filesystem table

tmpfs /tmp tmpfs defaults,nosuid,nodev 0 0
FSTAB

: > "$ROOTFS/etc/machine-id"
chmod 0444 "$ROOTFS/etc/machine-id"

install -d -m 0755 "$ROOTFS/var/lib/dbus"
rm -f "$ROOTFS/var/lib/dbus/machine-id"
ln -s ../../../etc/machine-id \
    "$ROOTFS/var/lib/dbus/machine-id"

PEPPER_UID="$(
    awk -F: '$1 == "pepper" {print $3}' "$ROOTFS/etc/passwd"
)"

PEPPER_GID="$(
    awk -F: '$1 == "pepper" {print $3}' "$ROOTFS/etc/group"
)"

TESTER_UID="$(
    awk -F: '$1 == "tester" {print $3}' "$ROOTFS/etc/passwd"
)"

TESTER_GID="$(
    awk -F: '$1 == "tester" {print $3}' "$ROOTFS/etc/group"
)"

python3 - "$ROOTFS" <<'PY'
from pathlib import Path
import sys

root = Path(sys.argv[1])
removed = {"pepper", "tester"}

passwd_path = root / "etc/passwd"
group_path = root / "etc/group"
shadow_path = root / "etc/shadow"
gshadow_path = root / "etc/gshadow"

passwd_lines = []
users = []

for raw in passwd_path.read_text().splitlines():
    fields = raw.split(":")
    if len(fields) < 7:
        continue
    if fields[0] in removed:
        continue
    users.append(fields[0])
    passwd_lines.append(":".join(fields))

passwd_path.write_text("\n".join(passwd_lines) + "\n")

group_lines = []
groups = []

for raw in group_path.read_text().splitlines():
    fields = raw.split(":")
    if len(fields) < 4:
        continue
    if fields[0] in removed:
        continue
    members = [
        member
        for member in fields[3].split(",")
        if member and member not in removed
    ]
    fields[3] = ",".join(members)
    groups.append((fields[0], fields[3]))
    group_lines.append(":".join(fields))

group_path.write_text("\n".join(group_lines) + "\n")

shadow_lines = [
    f"{user}:!:0:0:99999:7:::"
    for user in users
]

gshadow_lines = [
    f"{name}:!::{members}"
    for name, members in groups
]

shadow_path.write_text("\n".join(shadow_lines) + "\n")
gshadow_path.write_text("\n".join(gshadow_lines) + "\n")

shadow_path.chmod(0o600)
gshadow_path.chmod(0o600)
PY

grep -q '^sable:' "$ROOTFS/etc/passwd" ||
    die "sable live account is missing"

for database in subuid subgid; do
    path="$ROOTFS/etc/$database"

    if [ -f "$path" ]; then
        sed -i -E '/^(pepper|tester):/d' "$path"
    fi
done

if [ -f "$ROOTFS/etc/sudoers" ]; then
    sed -i -E \
        '/^[[:space:]]*(pepper|tester|%pepper|%tester)[[:space:]]/d' \
        "$ROOTFS/etc/sudoers"
fi

install -d -m 0750 "$ROOTFS/etc/sudoers.d"
find "$ROOTFS/etc/sudoers.d" \
    -mindepth 1 \
    -maxdepth 1 \
    -type f \
    -delete

cat > "$ROOTFS/etc/sudoers.d/90-sable-live" <<'SUDOERS'
sable ALL=(ALL) NOPASSWD: ALL
SUDOERS

chmod 0440 "$ROOTFS/etc/sudoers.d/90-sable-live"

if [ -x "$ROOTFS/usr/bin/agetty" ]; then
    AGETTY_PATH="/usr/bin/agetty"
elif [ -x "$ROOTFS/usr/sbin/agetty" ]; then
    AGETTY_PATH="/usr/sbin/agetty"
else
    die "agetty is missing from generated rootfs"
fi

install -d -m 0755 \
    "$ROOTFS/etc/systemd/system/getty@tty1.service.d"

cat > \
    "$ROOTFS/etc/systemd/system/getty@tty1.service.d/autologin.conf" <<AUTOLOGIN
[Service]
ExecStart=
ExecStart=-$AGETTY_PATH --autologin sable --noclear %I \$TERM
Type=idle
AUTOLOGIN

while IFS= read -r service; do
    case "$service" in
        ''|\#*)
            continue
            ;;
    esac

    find "$ROOTFS/etc/systemd/system" \
        -type l \
        -lname "*$service" \
        -print \
        -delete
done < "$DISABLED_SERVICES"

install -D -m 0644 \
    "$REPO/configs/desktop/sway/config" \
    "$ROOTFS/home/sable/.config/sway/config"

install -D -m 0644 \
    "$REPO/configs/desktop/waybar/config" \
    "$ROOTFS/home/sable/.config/waybar/config"

install -D -m 0644 \
    "$REPO/configs/desktop/waybar/style.css" \
    "$ROOTFS/home/sable/.config/waybar/style.css"

SABLE_UID="$(
    awk -F: '$1 == "sable" {print $3}' "$ROOTFS/etc/passwd"
)"

SABLE_GID="$(
    awk -F: '$1 == "sable" {print $4}' "$ROOTFS/etc/passwd"
)"

chown -R "$SABLE_UID:$SABLE_GID" \
    "$ROOTFS/home/sable"

for uid in "$PEPPER_UID" "$TESTER_UID"; do
    [ -n "$uid" ] || continue

    find "$ROOTFS" -xdev -uid "$uid" \
        -exec chown -h root {} +
done

for gid in "$PEPPER_GID" "$TESTER_GID"; do
    [ -n "$gid" ] || continue

    find "$ROOTFS" -xdev -gid "$gid" \
        -exec chgrp -h root {} +
done

find "$ROOTFS/var/log" \
    -mindepth 1 \
    -delete 2>/dev/null ||
    true

find "$ROOTFS/var/cache" \
    -mindepth 1 \
    -delete 2>/dev/null ||
    true

install -d -m 0755 \
    "$ROOTFS/etc/sablelinux"

sed \
    's/^BUILD_STATE=.*/BUILD_STATE=rootfs-generated/' \
    "$BUILD_ENV" \
    > "$ROOTFS/etc/sablelinux/build.env"

cp "$POLICY" \
    "$ROOTFS/etc/sablelinux/rootfs-generation-policy.md"

{
    echo "BUILD_ID=$BUILD_ID"
    echo "GENERATED_AT=$(date --utc +%Y-%m-%dT%H:%M:%SZ)"
    echo "SOURCE_HOST=$(hostname)"
    echo "SOURCE_GIT_COMMIT=$CURRENT_COMMIT"
    echo "KERNEL_RELEASE=$(uname -r)"
    echo "GENERATOR_SHA256=$(sha256sum "$REPO/scripts/live/generate-rootfs.sh" | awk '{print $1}')"
    echo "EXCLUDES_SHA256=$(sha256sum "$EXCLUDES" | awk '{print $1}')"
    echo "POLICY_SHA256=$(sha256sum "$POLICY" | awk '{print $1}')"
} > "$BUILD_ROOT/metadata/rootfs-generation.env"

find "$ROOTFS" \
    -xdev \
    -printf '%P\t%y\t%m\t%U\t%G\t%s\t%T@\t%l\n' |
    sort \
    > "$BUILD_ROOT/metadata/rootfs-files.tsv"

du -x -sh "$ROOTFS" \
    > "$BUILD_ROOT/metadata/rootfs-size.txt"

find "$ROOTFS" -xdev -type f |
    wc -l \
    > "$BUILD_ROOT/metadata/rootfs-regular-file-count.txt"

echo
echo "=== VALIDATE GENERATED ROOTFS ===" |
    tee -a "$REPORT"

VALIDATION_REPORT="$BUILD_ROOT/reports/rootfs-validation-${TIMESTAMP}.txt"
: > "$VALIDATION_REPORT"

validation_log() {
    printf '%s\n' "$*" |
        tee -a "$VALIDATION_REPORT" "$REPORT"
}

REQUIRED_ABSENT=(
    "$ROOTFS/sources"
    "$ROOTFS/srv"
    "$ROOTFS/swapfile"
    "$ROOTFS/home/pepper"
    "$ROOTFS/home/tester"
    "$ROOTFS/opt/models"
    "$ROOTFS/var/lib/qemu"
    "$ROOTFS/var/lib/libvirt"
    "$ROOTFS/etc/wireguard"
    "$ROOTFS/etc/wpa_supplicant"
    "$ROOTFS/etc/NetworkManager/system-connections"
    "$ROOTFS/etc/ssl/private"
    "$ROOTFS/etc/pki/private"
    "$ROOTFS/etc/letsencrypt"
    "$ROOTFS/.bash_history"
)

for path in "${REQUIRED_ABSENT[@]}"; do
    if [ -e "$path" ] || [ -L "$path" ]; then
        die "excluded path exists in generated rootfs: $path"
    fi
done

validation_log "PASS: excluded host and credential paths are absent"

[ ! -s "$ROOTFS/etc/machine-id" ] ||
    die "generated machine-id is not empty"

validation_log "PASS: machine-id is empty"

if grep -Eq 'UUID=|PARTUUID=' "$ROOTFS/etc/fstab"; then
    die "generated fstab contains host-specific UUID data"
fi

validation_log "PASS: fstab contains no host UUIDs"

for database in passwd group shadow gshadow; do
    if grep -Eq '^(pepper|tester):' "$ROOTFS/etc/$database"; then
        die "build-host account remains in $database"
    fi
done

validation_log "PASS: pepper and tester accounts were removed"

grep -q '^sable:' "$ROOTFS/etc/passwd" ||
    die "sable account is missing"

validation_log "PASS: sable live account exists"

[ "$(stat -c '%a' "$ROOTFS/etc/shadow")" = "600" ] ||
    die "incorrect mode on generated shadow file"

[ "$(stat -c '%a' "$ROOTFS/etc/gshadow")" = "600" ] ||
    die "incorrect mode on generated gshadow file"

validation_log "PASS: shadow database permissions are correct"

SSH_HOST_KEY="$(
    find "$ROOTFS/etc/ssh" \
        -maxdepth 1 \
        -type f \
        -name 'ssh_host_*' \
        -print -quit 2>/dev/null ||
        true
)"

[ -z "$SSH_HOST_KEY" ] ||
    die "SSH host identity remains: $SSH_HOST_KEY"

validation_log "PASS: SSH host keys are absent"

ROOT_CONTENT="$(
    find "$ROOTFS/root" \
        -mindepth 1 \
        -print -quit 2>/dev/null ||
        true
)"

[ -z "$ROOT_CONTENT" ] ||
    die "root home contains copied host data"

validation_log "PASS: root home is empty"

test -d "$ROOTFS/var/log" ||
    die "generated /var/log is missing"

test -d "$ROOTFS/var/cache" ||
    die "generated /var/cache is missing"

test -d "$ROOTFS/var/tmp" ||
    die "generated /var/tmp is missing"

validation_log "PASS: required empty runtime directories exist"

test -x "$ROOTFS/sbin/init" ||
test -x "$ROOTFS/usr/lib/systemd/systemd" ||
    die "generated rootfs has no executable init"

validation_log "PASS: executable init is present"

test -d "$ROOTFS/lib/modules/$(uname -r)" ||
    die "matching kernel module tree is absent"

validation_log "PASS: matching kernel module tree is present"

cmp -s \
    "$REPO/configs/desktop/sway/config" \
    "$ROOTFS/home/sable/.config/sway/config" ||
    die "injected Sway profile does not match repository"

cmp -s \
    "$REPO/configs/desktop/waybar/config" \
    "$ROOTFS/home/sable/.config/waybar/config" ||
    die "injected Waybar configuration does not match repository"

cmp -s \
    "$REPO/configs/desktop/waybar/style.css" \
    "$ROOTFS/home/sable/.config/waybar/style.css" ||
    die "injected Waybar stylesheet does not match repository"

validation_log "PASS: repository desktop profile was injected exactly"

for uid in "$PEPPER_UID" "$TESTER_UID"; do
    [ -n "$uid" ] || continue

    LEFTOVER="$(
        find "$ROOTFS" \
            -xdev \
            -uid "$uid" \
            -print -quit 2>/dev/null ||
            true
    )"

    [ -z "$LEFTOVER" ] ||
        die "removed host UID still owns rootfs content: $LEFTOVER"
done

validation_log "PASS: removed host UIDs own no rootfs content"

for service in llama-server.service sshd.service; do
    ENABLED_LINK="$(
        find "$ROOTFS/etc/systemd/system" \
            -type l \
            -lname "*$service" \
            -print -quit 2>/dev/null ||
            true
    )"

    [ -z "$ENABLED_LINK" ] ||
        die "disabled service remains enabled: $ENABLED_LINK"
done

validation_log "PASS: prohibited live services are not enabled"

validation_log "PASS: generated rootfs validation completed"

printf '%s\n' "rootfs-generated" \
    > "$BUILD_ROOT/BUILD_STATE"

sed -i \
    's/^BUILD_STATE=.*/BUILD_STATE=rootfs-generated/' \
    "$BUILD_ENV"

CONTROL_DIRECTORIES=(
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

chown root:"$BUILD_GROUP" "${CONTROL_DIRECTORIES[@]}"
chmod 2775 "${CONTROL_DIRECTORIES[@]}"

chown -R root:"$BUILD_GROUP" \
    "$BUILD_ROOT/logs" \
    "$BUILD_ROOT/metadata" \
    "$BUILD_ROOT/reports"

find \
    "$BUILD_ROOT/logs" \
    "$BUILD_ROOT/metadata" \
    "$BUILD_ROOT/reports" \
    -type d \
    -exec chmod 2775 {} +

find \
    "$BUILD_ROOT/logs" \
    "$BUILD_ROOT/metadata" \
    "$BUILD_ROOT/reports" \
    -type f \
    -exec chmod g+rw {} +

chown root:"$BUILD_GROUP" \
    "$BUILD_ROOT/BUILD_STATE" \
    "$BUILD_ROOT/README.txt"

chmod 0664 \
    "$BUILD_ROOT/BUILD_STATE" \
    "$BUILD_ROOT/README.txt"

{
    echo
    echo "PASS: rootfs generation completed"
    echo "Build state: rootfs-generated"
    cat "$BUILD_ROOT/metadata/rootfs-size.txt"
    echo
    echo "Report: $REPORT"
    echo "Log: $LOG"
} | tee -a "$REPORT"
