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

# Lock the existing build directory without creating a lock file.
# Retain this descriptor through capture, validation and finalization.
[ ! -L "$BUILD_ROOT" ] ||
    die "build directory must not be a symlink"

command -v flock >/dev/null ||
    die "flock is required for build locking"

exec {BUILD_LOCK_FD}<"$BUILD_ROOT"
flock --exclusive --nonblock "$BUILD_LOCK_FD" ||
    die "another operation holds the build lock"

[ -d "$ROOTFS" ] ||
    die "rootfs directory is missing: $ROOTFS"

[ -f "$BUILD_ENV" ] ||
    die "build metadata is missing: $BUILD_ENV"

# Release kernel identity is selected at build initialization.
# The running Z890 kernel is not necessarily the release kernel.
KERNEL_RELEASE="$(
    awk -F= '$1 == "KERNEL_RELEASE" {print $2}' "$BUILD_ENV"
)"

[ -n "$KERNEL_RELEASE" ] ||
    die "selected release kernel is missing from build metadata"

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

# Stage-specific provenance:
# Preserve the original initialization commit while allowing
# subsequent release stages to use later committed revisions.
git_repo merge-base --is-ancestor "$BUILD_COMMIT" "$CURRENT_COMMIT" ||
    die "build initialization commit is not an ancestor of HEAD"

# Only the unrelated, untracked boincctl utility is exempt.
# Never allow it to become a tracked release input.
if git_repo ls-files --error-unmatch scripts/boincctl >/dev/null 2>&1; then
    die "scripts/boincctl must not be tracked as a release input"
fi

DIRTY="$(
    git_repo status --porcelain --untracked-files=all -- .         ':(exclude)scripts/boincctl'
)"

[ -z "$DIRTY" ] ||
    die "repository contains uncommitted release-source changes"

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

PRESERVATION_CHECK="$REPO/scripts/live/check-rootfs-preservation.py"
PRESERVATION_REPORT="$BUILD_ROOT/reports/rootfs-preservation-${TIMESTAMP}.txt"
[ -f "$PRESERVATION_CHECK" ] || die "preservation prerequisite is missing"
command -v python3 >/dev/null || die "python3 is required for preservation validation"

# Run directly, outside an if/! context, before any host-root rsync. A failed
# fixture leaves rootfs and BUILD_STATE untouched and retains its report.
echo "Preservation prerequisite report: $PRESERVATION_REPORT"
python3 "$PRESERVATION_CHECK" \
    --workspace "$BUILD_ROOT/tmp" --destination-root "$ROOTFS" \
    --rsync "$(command -v rsync)" > "$PRESERVATION_REPORT" 2>&1
RSYNC_OPTIONS+=(-A -X)
RSYNC_ACL_SUPPORT="verified by actual fixture"
RSYNC_XATTR_SUPPORT="verified by actual fixture"

# Verify the exact baseline library qualified in the no-AVX guest.
LIVE_LIBFFI_SOURCE="/srv/sablelinux/package-builds/libffi/live-runtime-3.5.2/libffi.so.8.2.0"
LIVE_LIBFFI_SHA256="abffb16cc21a1cf23bfb9c2c925e483d84f4040e936ebc449f134f4ffe0ffca7"
[ -f "$LIVE_LIBFFI_SOURCE" ] && [ ! -L "$LIVE_LIBFFI_SOURCE" ] ||
    die "verified live libffi input is missing or symlinked"
printf '%s  %s\n' "$LIVE_LIBFFI_SHA256" "$LIVE_LIBFFI_SOURCE" |
    sha256sum --status -c - ||
    die "live libffi input checksum mismatch"

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
    echo "Preservation prerequisite report: $PRESERVATION_REPORT"
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

# tty1 autologin still runs PAM account checks. Keep password login
# locked and leave aging unset for the live account.
shadow_lines = [
    f"{user}:!:::::::" if user == "sable" else f"{user}:!:0:0:99999:7:::"
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

# Replace only the runtime library in the captured filesystem.
for live_dir in "$ROOTFS/usr" "$ROOTFS/usr/lib"; do
    [ -d "$live_dir" ] && [ ! -L "$live_dir" ] ||
        die "live library path must be a directory: $live_dir"
done
LIVE_LIBFFI_DEST="$ROOTFS/usr/lib/libffi.so.8.2.0"
LIVE_LIBFFI_LINK="$ROOTFS/usr/lib/libffi.so.8"
if [ -e "$LIVE_LIBFFI_LINK" ] || [ -L "$LIVE_LIBFFI_LINK" ]; then
    [ -L "$LIVE_LIBFFI_LINK" ] &&
        [ "$(readlink "$LIVE_LIBFFI_LINK")" = libffi.so.8.2.0 ] ||
        die "unexpected live libffi SONAME path"
fi
[ ! -L "$LIVE_LIBFFI_DEST" ] &&
    { [ ! -e "$LIVE_LIBFFI_DEST" ] || [ -f "$LIVE_LIBFFI_DEST" ]; } ||
    die "unexpected live libffi destination"

# Use a new inode so replacement cannot modify a captured hard link.
LIVE_LIBFFI_TEMP="$(mktemp "$ROOTFS/usr/lib/.libffi.XXXXXXXX")"
install -m 0755 "$LIVE_LIBFFI_SOURCE" "$LIVE_LIBFFI_TEMP"
printf '%s  %s\n' "$LIVE_LIBFFI_SHA256" "$LIVE_LIBFFI_TEMP" |
    sha256sum --status -c - ||
    die "copied live libffi checksum mismatch"
mv -T -- "$LIVE_LIBFFI_TEMP" "$LIVE_LIBFFI_DEST"
if [ ! -L "$LIVE_LIBFFI_LINK" ]; then
    ln -s libffi.so.8.2.0 "$LIVE_LIBFFI_LINK"
fi
echo "PASS: installed verified baseline libffi in staged rootfs"

# Enable the desktop audio stack in the staged system.
LIVE_AUDIO_UNITS=(pipewire.socket pipewire-pulse.socket wireplumber.service)
for unit in "${LIVE_AUDIO_UNITS[@]}"; do
    [ -f "$ROOTFS/usr/lib/systemd/user/$unit" ] ||
        die "live audio unit is missing: $unit"
done
systemctl --root="$ROOTFS" --global enable "${LIVE_AUDIO_UNITS[@]}" ||
    die "could not enable live audio user units"
for unit in "${LIVE_AUDIO_UNITS[@]}"; do
    systemctl --root="$ROOTFS" --global is-enabled --quiet "$unit" ||
        die "live audio unit is not enabled: $unit"
done

# Supply a release-owned login profile instead of inheriting the host's.
for live_dir in "$ROOTFS/home" "$ROOTFS/home/sable"; do
    [ -d "$live_dir" ] && [ ! -L "$live_dir" ] ||
        die "live home path must be a directory: $live_dir"
done

rm -f -- "$ROOTFS/home/sable/.bash_profile"
install -m 0644 \
    "$REPO/configs/live/sable-bash-profile" \
    "$ROOTFS/home/sable/.bash_profile"

install -D -m 0644 \
    "$REPO/configs/desktop/sway/sable-code.png" \
    "$ROOTFS/usr/share/backgrounds/sablelinux/sable-code.png"

install -D -m 0644 \
    "$REPO/configs/desktop/sway/config" \
    "$ROOTFS/home/sable/.config/sway/config"

install -D -m 0755 \
    "$REPO/configs/desktop/waybar/sable-power-menu" \
    "$ROOTFS/home/sable/.local/bin/sable-power-menu"

install -D -m 0644 \
    "$REPO/configs/desktop/fuzzel/fuzzel.ini" \
    "$ROOTFS/home/sable/.config/fuzzel/fuzzel.ini"

install -D -m 0755 \
    "$REPO/configs/desktop/waybar/sable-sensors" \
    "$ROOTFS/home/sable/.local/bin/sable-sensors"

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

# M1.11: Deploy the selected, verified release-kernel modules.
# The running Z890 kernel's module trees are excluded by policy.
echo
echo "=== STAGE VERIFIED RELEASE KERNEL MODULES ===" |
    tee -a "$REPORT"

if [ -L "$ROOTFS/lib" ]; then
    [ "$(readlink "$ROOTFS/lib")" = "usr/lib" ] ||
        die "unsupported rootfs /lib symlink"
    MODULE_PARENT="$ROOTFS/usr/lib/modules"
elif [ -d "$ROOTFS/lib" ]; then
    MODULE_PARENT="$ROOTFS/lib/modules"
else
    die "generated rootfs has no supported /lib layout"
fi

install -d -m 0755 "$MODULE_PARENT"

# Nothing from the host kernel may survive the capture.
[ -z "$(find "$MODULE_PARENT" -mindepth 1 -maxdepth 1 -print -quit)" ] ||
    die "host kernel modules remain in release rootfs"

MODULE_STAGER="$REPO/scripts/release/stage-kernel-modules.py"

python3 -B "$MODULE_STAGER" \
    --build-root "$BUILD_ROOT" \
    --workspace "$WORKSPACE/kernel-builds" \
    || die "release kernel module staging failed"

# Linux 6.16.1 requests this firmware by basename.
if [ "$KERNEL_RELEASE" = "6.16.1-sable-asus-test1" ]; then
    ASUS_FW_REL="intel/iwlwifi/iwlwifi-7265D-29.ucode"
    ASUS_FW_DIR="$(realpath -e -- "$ROOTFS/usr/lib/firmware")" ||
        die "Asus firmware directory is missing"
    case "$ASUS_FW_DIR" in
        "$(realpath -e -- "$ROOTFS")"/*) ;;
        *) die "Asus firmware directory resolves outside the staged root" ;;
    esac

    ASUS_FW_SOURCE="$ASUS_FW_DIR/$ASUS_FW_REL"
    ASUS_FW_LINK="$ASUS_FW_DIR/iwlwifi-7265D-29.ucode"
    [ -f "$ASUS_FW_SOURCE" ] &&
        [ "$(realpath -e -- "$ASUS_FW_SOURCE")" = "$ASUS_FW_SOURCE" ] ||
        die "Asus Wi-Fi firmware is missing or redirected: $ASUS_FW_REL"

    if [ ! -e "$ASUS_FW_LINK" ] && [ ! -L "$ASUS_FW_LINK" ]; then
        ln -sT -- "$ASUS_FW_REL" "$ASUS_FW_LINK" ||
            die "could not create Asus Wi-Fi firmware link"
    fi

    [ -L "$ASUS_FW_LINK" ] &&
        [ "$(readlink -- "$ASUS_FW_LINK")" = "$ASUS_FW_REL" ] &&
        [ "$(realpath -e -- "$ASUS_FW_LINK")" = "$ASUS_FW_SOURCE" ] ||
        die "invalid Asus Wi-Fi firmware link"
fi

# Verify all 57 candidate files against the authoritative manifest.
(
    cd "$ROOTFS"
    sha256sum -c \
        "$BUILD_ROOT/metadata/candidate-kernel-modules.sha256" \
        > "$BUILD_ROOT/reports/rootfs-kernel-modules.sha256.log"
) || die "deployed kernel module checksums failed"

echo "PASS: verified release kernel modules staged" |
    tee -a "$REPORT"

install -d -m 0755 \
    "$ROOTFS/etc/sablelinux"

# Keep build metadata provisional until final validation.
cp "$BUILD_ENV" "$ROOTFS/etc/sablelinux/build.env"

cp "$POLICY" \
    "$ROOTFS/etc/sablelinux/rootfs-generation-policy.md"

{
    echo "BUILD_ID=$BUILD_ID"
    echo "GENERATED_AT=$(date --utc +%Y-%m-%dT%H:%M:%SZ)"
    echo "SOURCE_HOST=$(hostname)"
    echo "SOURCE_GIT_COMMIT=$CURRENT_COMMIT"
    echo "KERNEL_RELEASE=$KERNEL_RELEASE"
    echo "LIVE_LIBFFI_SOURCE=$LIVE_LIBFFI_SOURCE"
    echo "LIVE_LIBFFI_EXPECTED_SHA256=$LIVE_LIBFFI_SHA256"
    echo "LIVE_LIBFFI_STAGED_SHA256=$(sha256sum "$LIVE_LIBFFI_DEST" | awk '{print $1}')"
    echo "GENERATOR_SHA256=$(sha256sum "$REPO/scripts/live/generate-rootfs.sh" | awk '{print $1}')"
    echo "EXCLUDES_SHA256=$(sha256sum "$EXCLUDES" | awk '{print $1}')"
    echo "PRESERVATION_CHECK_SHA256=$(sha256sum "$PRESERVATION_CHECK" | awk '{print $1}')"
    echo "PRESERVATION_REPORT_SHA256=$(sha256sum "$PRESERVATION_REPORT" | awk '{print $1}')"
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
    "$ROOTFS/cvmfs"
    "$ROOTFS/var/lib/cvmfs"
    "$ROOTFS/etc/cvmfs"
    "$ROOTFS/etc/auto.cvmfs"
    "$ROOTFS/etc/auto.master.d/cvmfs.autofs"
    "$ROOTFS/usr/libexec/cvmfs"
    "$ROOTFS/usr/bin/cvmfs2"
    "$ROOTFS/usr/sbin/mount.cvmfs"
    "$ROOTFS/opt/boinc"
    "$ROOTFS/var/lib/boinc-client"
    "$ROOTFS/etc/boinc"
    "$ROOTFS/etc/boinc-client"
    "$ROOTFS/usr/local/bin/boincctl"
    "$ROOTFS/etc/systemd/system/boinc-client.service"
    "$ROOTFS/usr/lib/systemd/system/boinc-client.service"
    "$ROOTFS/lib/systemd/system/boinc-client.service"
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

[ "$(grep -c '^sable:' "$ROOTFS/etc/shadow")" -eq 1 ] &&
    grep -Fxq 'sable:!:::::::' "$ROOTFS/etc/shadow" ||
    die "sable live account must have a locked password and no password aging"

validation_log "PASS: sable live password is locked and password aging is unset"

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

test -d "$ROOTFS/lib/modules/$KERNEL_RELEASE" ||
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

cmp -s \
    "$REPO/configs/live/sable-bash-profile" \
    "$ROOTFS/home/sable/.bash_profile" ||
    die "injected live login profile does not match repository"

cmp -s \
    "$REPO/configs/desktop/sway/sable-code.png" \
    "$ROOTFS/usr/share/backgrounds/sablelinux/sable-code.png" ||
    die "injected Sway wallpaper does not match repository"

cmp -s \
    "$REPO/configs/desktop/fuzzel/fuzzel.ini" \
    "$ROOTFS/home/sable/.config/fuzzel/fuzzel.ini" ||
    die "injected Fuzzel theme does not match repository"

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

for service in llama-server.service sshd.service autofs.service; do
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

# M1.11: Finalize release metadata only after validation.
FINAL_ENV="$BUILD_ROOT/tmp/rootfs-build.env.final"

sed \
    -e 's/^BUILD_STATE=.*/BUILD_STATE=rootfs-generated/' \
    -e 's/^KERNEL_MODULES_STAGED=.*/KERNEL_MODULES_STAGED=true/' \
    "$BUILD_ENV" > "$FINAL_ENV"

grep -qx 'BUILD_STATE=rootfs-generated' "$FINAL_ENV" ||
    die "final build-state metadata missing"

grep -qx 'KERNEL_MODULES_STAGED=true' "$FINAL_ENV" ||
    die "final module-staging metadata missing"

# Publish metadata into the staged root.
install -m 0644 "$FINAL_ENV" \
    "$ROOTFS/etc/sablelinux/.build.env.final"

mv -f \
    "$ROOTFS/etc/sablelinux/.build.env.final" \
    "$ROOTFS/etc/sablelinux/build.env"

# Inventory the completed staged filesystem.
find "$ROOTFS" -xdev \
    -printf '%P\t%y\t%m\t%U\t%G\t%s\t%T@\t%l\n' |
    sort > "$BUILD_ROOT/metadata/rootfs-files.tsv"

# Reverify the authoritative candidate manifest.
(
    cd "$ROOTFS"
    sha256sum --status -c \
        "$BUILD_ROOT/metadata/candidate-kernel-modules.sha256"
) || die "final kernel-module verification failed"

# Prepare authoritative metadata before state promotion.
install -m 0664 -o root -g "$BUILD_GROUP" \
    "$FINAL_ENV" "$BUILD_ROOT/metadata/.build.env.final"

mv -f \
    "$BUILD_ROOT/metadata/.build.env.final" \
    "$BUILD_ENV"

# The authoritative state marker is published last.
printf '%s\n' "rootfs-generated" \
    > "$BUILD_ROOT/.BUILD_STATE.final"

chown root:"$BUILD_GROUP" "$BUILD_ROOT/.BUILD_STATE.final"
chmod 0664 "$BUILD_ROOT/.BUILD_STATE.final"

mv -f "$BUILD_ROOT/.BUILD_STATE.final" \
    "$BUILD_ROOT/BUILD_STATE"

{
    echo
    echo "PASS: rootfs generation completed"
    echo "Build state: rootfs-generated"
    cat "$BUILD_ROOT/metadata/rootfs-size.txt"
    echo
    echo "Report: $REPORT"
    echo "Log: $LOG"
} | tee -a "$REPORT"
