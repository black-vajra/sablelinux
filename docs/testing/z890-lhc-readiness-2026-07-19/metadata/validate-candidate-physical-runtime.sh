#!/bin/bash

set -u

BUILD_ID="20260719T211841Z-eb762ba-k6.16.1-sable-lhc-test1"
BUILD_ROOT="/srv/sablelinux/builds/20260719T211841Z-eb762ba-k6.16.1-sable-lhc-test1"

CURRENT_RELEASE="6.16.1-sable-compat"
TARGET_RELEASE="6.16.1-sable-lhc-test1"

STATE_FILE="$BUILD_ROOT/metadata/build-state.env"

CANDIDATE_KERNEL="/boot/vmlinuz-$TARGET_RELEASE"
CANDIDATE_INITRAMFS="/boot/initramfs-$TARGET_RELEASE.img"
CANDIDATE_CONFIG="/boot/config-$TARGET_RELEASE"
CANDIDATE_SYSTEM_MAP="/boot/System.map-$TARGET_RELEASE"
CANDIDATE_MODULES="/lib/modules/$TARGET_RELEASE"

CURRENT_KERNEL="/boot/vmlinuz-$CURRENT_RELEASE"
CURRENT_INITRAMFS="/boot/initramfs-$CURRENT_RELEASE.img"

CUSTOM_CFG="/boot/grub/custom.cfg"
GRUB_CONFIG="/boot/grub/grub.cfg"

REPORT="$BUILD_ROOT/reports/candidate-physical-runtime-validation.txt"
MANIFEST="$BUILD_ROOT/metadata/candidate-physical-runtime-manifest.env"

EXPECTED_KERNEL_HASH="77c2a123bb8c3eb5c1b376c8af502052e5731715680d46ccf7c2ace0b863237c"
EXPECTED_INITRAMFS_HASH="b21e2e1adf6a7622fedc803e444ea065b9c049de690de06da2d60e6a1d46b5f3"
EXPECTED_CONFIG_HASH="9a9dd3fc7ac49707c95daafce792b77badd35802221e70c51caab85d6b084933"
EXPECTED_SYSTEM_MAP_HASH="67e9b0ca0032dc01bbbeabb9694d2bb95f899d2e84139f6f864f34441cce3de1"

EXPECTED_CURRENT_KERNEL_HASH="d58468c6102b95162fc35b6fb88743e4ad5505adb5566afc96cc4f61973bc9c6"
EXPECTED_CURRENT_INITRAMFS_HASH="e6f85c3232570684e86da7cd5c33e347ad05081cb5a9816c0278c909b47cf3b2"
EXPECTED_GRUB_HASH="1827589b3bbd04f8121fd8268f31a82693cc181d62ce842e8ece7a178c5dceca"
EXPECTED_CUSTOM_HASH="3a581fc11b16aed03b7ec84e5d6ad22dbe3e82f9b888632818a9832e45a5b7b6"

ROOT_UUID="70148917-ed5a-466c-b71b-444596ca684a"
BOOT_UUID="13816e16-93ea-4e55-9b82-cfbb7946b7a0"

echo "=== VALIDATE PHYSICAL CANDIDATE KERNEL RUNTIME ==="

if [ "$(id -u)" -eq 0 ]; then
    echo "STOP: run this validation as pepper, not as root."
    exit 1
fi

if [ -e "$REPORT" ] || [ -e "$MANIFEST" ]; then
    echo "STOP: runtime evidence already exists."
    echo "report=$REPORT"
    echo "manifest=$MANIFEST"
    exit 1
fi

exec > >(tee "$REPORT") 2>&1

FAILURES=0
WARNINGS=0

pass() {
    echo "PASS: $*"
}

fail() {
    echo "FAIL: $*"
    FAILURES=$((FAILURES + 1))
}

warn() {
    echo "WARN: $*"
    WARNINGS=$((WARNINGS + 1))
}

verify_hash() {
    DESCRIPTION="$1"
    PATHNAME="$2"
    EXPECTED="$3"

    ACTUAL="$(
        sudo sha256sum "$PATHNAME" 2>/dev/null |
            awk '{print $1}'
    )"

    echo "${DESCRIPTION}_sha256=$ACTUAL"

    if [ "$ACTUAL" = "$EXPECTED" ]; then
        pass "$DESCRIPTION hash matches"
    else
        fail "$DESCRIPTION hash mismatch"
    fi
}

read_state() {
    sed -n "s/^$1=//p" "$STATE_FILE" 2>/dev/null |
        tail -n 1
}

echo
echo "=== PRIVILEGE AND BUILD STATE ==="

OUTER_UID="$(id -u)"
OUTER_GID="$(id -g)"

echo "validation_outer_uid=$OUTER_UID"
echo "validation_outer_gid=$OUTER_GID"

if [ "$OUTER_UID" = "1000" ] &&
   [ "$OUTER_GID" = "1000" ]; then
    pass "validation is running as UID/GID 1000"
else
    fail "validation is not running as UID/GID 1000"
fi

if sudo -v; then
    pass "sudo authentication is available"
else
    fail "sudo authentication failed"
fi

BUILD_STATE="$(read_state BUILD_STATE)"
echo "initial_build_state=$BUILD_STATE"

if [ "$BUILD_STATE" = "kernel-candidate-reboot-ready" ]; then
    pass "build state permits physical runtime validation"
else
    fail "unexpected build state"
fi

echo
echo "=== RUNNING KERNEL ==="

RUNNING_RELEASE="$(uname -r)"
echo "running_release=$RUNNING_RELEASE"

if [ "$RUNNING_RELEASE" = "$TARGET_RELEASE" ]; then
    pass "candidate kernel is running on physical Z890 hardware"
else
    fail "candidate kernel is not running"
fi

echo
echo "=== BOINC SAFETY ==="

if systemctl is-active --quiet boinc-client.service; then
    fail "BOINC is active"
else
    pass "BOINC remains inactive"
fi

if systemctl is-enabled --quiet boinc-client.service; then
    fail "BOINC is enabled at boot"
else
    pass "BOINC remains disabled at boot"
fi

echo
echo "=== KERNEL CONFIGURATION ==="

if [ -r /proc/config.gz ]; then
    pass "/proc/config.gz is available"

    if zgrep -Fqx 'CONFIG_USER_NS=y' /proc/config.gz; then
        pass "CONFIG_USER_NS=y"
    else
        fail "CONFIG_USER_NS is not enabled"
    fi

    if zgrep -Fqx 'CONFIG_FUSE_FS=m' /proc/config.gz; then
        pass "CONFIG_FUSE_FS=m"
    else
        fail "CONFIG_FUSE_FS is not modular"
    fi

    if zgrep -Fqx \
        'CONFIG_LOCALVERSION="-sable-lhc-test1"' \
        /proc/config.gz; then
        pass "candidate local version is correct"
    else
        fail "candidate local version is incorrect"
    fi
else
    fail "/proc/config.gz is unavailable"
fi

echo
echo "=== UNPRIVILEGED USER NAMESPACE ==="

if [ -e /proc/self/ns/user ]; then
    pass "user namespace interface exists"
else
    fail "user namespace interface is absent"
fi

MAX_USER_NAMESPACES="$(
    cat /proc/sys/user/max_user_namespaces 2>/dev/null ||
        echo unavailable
)"

echo "max_user_namespaces=$MAX_USER_NAMESPACES"

if [ "$MAX_USER_NAMESPACES" != "unavailable" ] &&
   [ "$MAX_USER_NAMESPACES" -gt 0 ] 2>/dev/null; then
    pass "user namespaces are permitted by runtime sysctl"
else
    fail "runtime user-namespace limit is zero or unavailable"
fi

USERNS_OUTPUT="$(
    unshare \
        --user \
        --map-root-user \
        /bin/sh -c '
            echo "inner_uid=$(id -u)"
            echo "inner_gid=$(id -g)"
            test "$(id -u)" = 0
            test "$(id -g)" = 0
            test -e /proc/self/ns/user
        ' 2>&1
)"

USERNS_STATUS=$?

printf '%s\n' "$USERNS_OUTPUT"

if [ "$USERNS_STATUS" -eq 0 ] &&
   printf '%s\n' "$USERNS_OUTPUT" |
       grep -Fqx 'inner_uid=0' &&
   printf '%s\n' "$USERNS_OUTPUT" |
       grep -Fqx 'inner_gid=0'; then
    pass "unprivileged UID/GID 1000 created a mapped user namespace"
else
    fail "unprivileged user namespace creation failed"
fi

echo
echo "=== FUSE RUNTIME ==="

FUSE_PATH="$CANDIDATE_MODULES/kernel/fs/fuse/fuse.ko"

FUSE_VERMAGIC="$(
    modinfo -F vermagic "$FUSE_PATH" 2>/dev/null |
        awk '{print $1}'
)"

echo "fuse_vermagic=$FUSE_VERMAGIC"

if [ "$FUSE_VERMAGIC" = "$TARGET_RELEASE" ]; then
    pass "installed FUSE vermagic matches running kernel"
else
    fail "installed FUSE vermagic mismatch"
fi

modprobe \
    --show-depends \
    fuse |
    tee "$BUILD_ROOT/reports/candidate-physical-fuse-resolution.txt"

MODPROBE_RESOLVE_STATUS="${PIPESTATUS[0]}"

if [ "$MODPROBE_RESOLVE_STATUS" -eq 0 ]; then
    pass "running kernel resolves FUSE through kmod"
else
    fail "running kernel cannot resolve FUSE"
fi

if sudo modprobe fuse; then
    pass "candidate FUSE module loaded"
else
    fail "candidate FUSE module failed to load"
fi

if [ -d /sys/module/fuse ]; then
    pass "FUSE module is registered in sysfs"
else
    fail "FUSE module is absent from sysfs"
fi

if [ -c /dev/fuse ]; then
    pass "/dev/fuse exists as a character device"
else
    fail "/dev/fuse is unavailable"
fi

echo
echo "=== FILESYSTEM AND BOOT MOUNTS ==="

ROOT_SOURCE="$(findmnt -n -o SOURCE /)"
ROOT_UUID_ACTUAL="$(findmnt -n -o UUID /)"
ROOT_FSTYPE="$(findmnt -n -o FSTYPE /)"
ROOT_OPTIONS="$(findmnt -n -o OPTIONS /)"

BOOT_SOURCE="$(findmnt -n -o SOURCE /boot)"
BOOT_UUID_ACTUAL="$(findmnt -n -o UUID /boot)"
BOOT_FSTYPE="$(findmnt -n -o FSTYPE /boot)"
BOOT_OPTIONS="$(findmnt -n -o OPTIONS /boot)"

echo "root_source=$ROOT_SOURCE"
echo "root_uuid=$ROOT_UUID_ACTUAL"
echo "root_fstype=$ROOT_FSTYPE"
echo "root_options=$ROOT_OPTIONS"

echo "boot_source=$BOOT_SOURCE"
echo "boot_uuid=$BOOT_UUID_ACTUAL"
echo "boot_fstype=$BOOT_FSTYPE"
echo "boot_options=$BOOT_OPTIONS"

if [ "$ROOT_SOURCE" = "/dev/nvme1n1p3" ] &&
   [ "$ROOT_UUID_ACTUAL" = "$ROOT_UUID" ] &&
   [ "$ROOT_FSTYPE" = "ext4" ]; then
    pass "canonical root filesystem mounted correctly"
else
    fail "canonical root filesystem differs from expected state"
fi

if printf '%s\n' "$ROOT_OPTIONS" |
   tr ',' '\n' |
   grep -Fqx rw; then
    pass "root filesystem is writable"
else
    fail "root filesystem is not writable"
fi

if [ "$BOOT_SOURCE" = "/dev/nvme1n1p2" ] &&
   [ "$BOOT_UUID_ACTUAL" = "$BOOT_UUID" ] &&
   [ "$BOOT_FSTYPE" = "ext4" ]; then
    pass "separate /boot filesystem mounted correctly"
else
    fail "/boot filesystem differs from expected state"
fi

echo
echo "=== INSTALLED ARTIFACT INTEGRITY ==="

verify_hash \
    candidate_kernel \
    "$CANDIDATE_KERNEL" \
    "$EXPECTED_KERNEL_HASH"

verify_hash \
    candidate_initramfs \
    "$CANDIDATE_INITRAMFS" \
    "$EXPECTED_INITRAMFS_HASH"

verify_hash \
    candidate_config \
    "$CANDIDATE_CONFIG" \
    "$EXPECTED_CONFIG_HASH"

verify_hash \
    candidate_system_map \
    "$CANDIDATE_SYSTEM_MAP" \
    "$EXPECTED_SYSTEM_MAP_HASH"

verify_hash \
    compatibility_kernel \
    "$CURRENT_KERNEL" \
    "$EXPECTED_CURRENT_KERNEL_HASH"

verify_hash \
    compatibility_initramfs \
    "$CURRENT_INITRAMFS" \
    "$EXPECTED_CURRENT_INITRAMFS_HASH"

verify_hash \
    generated_grub_config \
    "$GRUB_CONFIG" \
    "$EXPECTED_GRUB_HASH"

verify_hash \
    candidate_custom_config \
    "$CUSTOM_CFG" \
    "$EXPECTED_CUSTOM_HASH"

echo
echo "=== HARDWARE REGRESSION SIGNALS ==="

if [ -c /dev/kvm ]; then
    pass "/dev/kvm is available"
else
    fail "/dev/kvm is unavailable"
fi

if compgen -G '/dev/dri/card*' >/dev/null; then
    pass "DRM card device is available"
else
    fail "DRM card device is unavailable"
fi

if compgen -G '/dev/dri/renderD*' >/dev/null; then
    pass "DRM render device is available"
else
    fail "DRM render device is unavailable"
fi

if [ -c /dev/kfd ]; then
    pass "/dev/kfd is available"
else
    fail "/dev/kfd is unavailable"
fi

if compgen -G '/dev/snd/controlC*' >/dev/null; then
    pass "audio control device is available"
else
    fail "audio control device is unavailable"
fi

echo
echo "=== NETWORK SIGNALS ==="

ip -brief link
ip route

if ip -brief link |
   awk '
       $1 != "lo" && $2 == "UP" {
           found = 1
       }
       END {
           exit found ? 0 : 1
       }
   '; then
    pass "at least one non-loopback interface is up"
else
    warn "no non-loopback interface is currently up"
fi

if ip route show default |
   grep -q '^default '; then
    pass "default network route is present"
else
    warn "default network route is absent"
fi

echo
echo "=== SYSTEMD STATE ==="

SYSTEM_STATE="$(
    systemctl is-system-running 2>/dev/null ||
        true
)"

echo "system_state=$SYSTEM_STATE"

case "$SYSTEM_STATE" in
    running)
        pass "systemd reports the system as running"
        ;;
    degraded)
        warn "systemd reports degraded state"
        ;;
    *)
        fail "systemd reports unexpected state: $SYSTEM_STATE"
        ;;
esac

FAILED_UNIT_COUNT="$(
    systemctl \
        --failed \
        --no-legend \
        --no-pager |
        sed '/^[[:space:]]*$/d' |
        wc -l
)"

echo "failed_unit_count=$FAILED_UNIT_COUNT"

if [ "$FAILED_UNIT_COUNT" -eq 0 ]; then
    pass "no failed systemd units are present"
else
    warn "$FAILED_UNIT_COUNT failed systemd unit(s) are present"

    systemctl \
        --failed \
        --no-pager
fi

echo
echo "=== FINAL RESULT ==="

echo "failure_count=$FAILURES"
echo "warning_count=$WARNINGS"

if [ "$FAILURES" -ne 0 ]; then
    echo "SABLE_PHYSICAL_RUNTIME_RESULT=FAIL"
    echo "Build state was not advanced."
    exit 1
fi

{
    echo "BUILD_ID=$BUILD_ID"
    echo "VALIDATED_AT=$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
    echo "CANONICAL_HOST=SableLinux"
    echo "PHYSICAL_HOST=Z890"
    echo "RUNNING_KERNEL_RELEASE=$RUNNING_RELEASE"
    echo "USERNS_OUTER_ID=$OUTER_UID:$OUTER_GID"
    echo "USERNS_INNER_ID=0:0"
    echo "USER_NAMESPACE_RUNTIME=pass"
    echo "FUSE_MODULE_RUNTIME=pass"
    echo "DEV_FUSE_RUNTIME=pass"
    echo "ROOT_FILESYSTEM_RUNTIME=pass"
    echo "BOOT_FILESYSTEM_RUNTIME=pass"
    echo "KVM_DEVICE_RUNTIME=pass"
    echo "DRM_RUNTIME=pass"
    echo "KFD_RUNTIME=pass"
    echo "AUDIO_DEVICE_RUNTIME=pass"
    echo "NETWORK_WARNINGS=$WARNINGS"
    echo "BOINC_ACTIVE=false"
    echo "BOINC_ENABLED=false"
    echo "BUILD_STATE=kernel-physical-runtime-validated"
} >"$MANIFEST"

python3 - "$STATE_FILE" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])

updates = {
    "BUILD_STATE": "kernel-physical-runtime-validated",
    "PHYSICAL_VALIDATION_HOST": "Z890",
    "PHYSICAL_KERNEL_RUNTIME": "pass",
    "PHYSICAL_USER_NAMESPACE": "pass",
    "PHYSICAL_FUSE_MODULE": "pass",
    "PHYSICAL_DEV_FUSE": "pass",
    "PHYSICAL_KVM_DEVICE": "pass",
    "PHYSICAL_DRM_DEVICES": "pass",
    "PHYSICAL_KFD_DEVICE": "pass",
    "PHYSICAL_AUDIO_DEVICES": "pass",
    "PHYSICAL_BOINC_ACTIVE": "false",
    "PHYSICAL_BOINC_ENABLED": "false",
}

lines = path.read_text(encoding="utf-8").splitlines()
result = []
seen = set()

for line in lines:
    if "=" in line:
        key = line.split("=", 1)[0]

        if key in updates:
            result.append(f"{key}={updates[key]}")
            seen.add(key)
            continue

    result.append(line)

for key, value in updates.items():
    if key not in seen:
        result.append(f"{key}={value}")

path.write_text(
    "\n".join(result) + "\n",
    encoding="utf-8",
)
PY

echo "SABLE_PHYSICAL_RUNTIME_RESULT=PASS"

echo
echo "=== PHYSICAL VALIDATION MANIFEST ==="
cat "$MANIFEST"

echo
echo "=== UPDATED BUILD STATE ==="
cat "$STATE_FILE"

echo
echo "=== EVIDENCE HASHES ==="

sha256sum \
    "$REPORT" \
    "$MANIFEST" \
    "$BUILD_ROOT/reports/candidate-physical-fuse-resolution.txt"
