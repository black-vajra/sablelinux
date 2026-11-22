#!/usr/bin/env bash
set -Eeuo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PRODUCTION="$REPO/scripts/kernel/build-kernel.sh"
SOURCE="/srv/sablelinux/cache/downloads/linux-6.16.1.tar.xz"
BASELINE="$REPO/docs/release-validation/gpu-test2-2026-10-08/kernel.config"

EXPECTED_SOURCE="ea43491bc7ace1e414b3b2d957f8cf96e7049155123f0acce798accf8da1acba"
EXPECTED_BASELINE="1271404d28cc2eb66f9cf2222c4b2f7406cff4a85f57c3ba4ced8d1d45d22fd5"

die() {
    printf 'FAIL: %s\n' "$*" >&2
    exit 1
}

[[ -f "$PRODUCTION" && -f "$SOURCE" && -f "$BASELINE" ]] ||
    die "required input missing"

[[ "$(sha256sum "$SOURCE" | cut -d' ' -f1)" == "$EXPECTED_SOURCE" ]] ||
    die "source checksum mismatch"

[[ "$(sha256sum "$BASELINE" | cut -d' ' -f1)" == "$EXPECTED_BASELINE" ]] ||
    die "baseline checksum mismatch"

TMP="$(mktemp -d /srv/sablelinux/kernel-builds/beta1-regression-XXXXXXXX)"
echo "Test workspace: $TMP"

# Preserve the complete test workspace for inspection.
mkdir -p "$TMP/repo/scripts/kernel" \
         "$TMP/repo/docs/release-validation/gpu-test2-2026-10-08" \
         "$TMP/workspace/kernel-builds" \
         "$TMP/workspace/state"

cp "$PRODUCTION" "$TMP/repo/scripts/kernel/build-kernel.sh"
cp "$BASELINE" \
   "$TMP/repo/docs/release-validation/gpu-test2-2026-10-08/kernel.config"

printf '1\n' > "$TMP/workspace/state/layout-version"

python3 - "$TMP" <<'PY'
from pathlib import Path
import sys

root = Path(sys.argv[1])
script = root / "repo/scripts/kernel/build-kernel.sh"
text = script.read_text()

replacements = {
    'WORKSPACE="/srv/sablelinux"':
        f'WORKSPACE="{root / "workspace"}"',
    'SOURCE_ARCHIVE="/srv/sablelinux/cache/downloads/linux-6.16.1.tar.xz"':
        'SOURCE_ARCHIVE="/srv/sablelinux/cache/downloads/linux-6.16.1.tar.xz"',
}

for old, new in replacements.items():
    if old == new:
        continue
    if text.count(old) != 1:
        raise SystemExit(f"STOP: unexpected production script structure: {old}")
    text = text.replace(old, new, 1)

limit = '(( free_bytes >= 200 * 1024 * 1024 * 1024 ))'
if text.count(limit) != 1:
    raise SystemExit("STOP: capacity guard not found")

# Only the disposable test script receives this reduced threshold.
text = text.replace(
    limit,
    '(( free_bytes >= 1 * 1024 * 1024 ))',
    1
)

script.write_text(text)
PY

chmod 755 "$TMP/repo/scripts/kernel/build-kernel.sh"

git -C "$TMP/repo" init -q -b development
git -C "$TMP/repo" add .
git -C "$TMP/repo" \
    -c user.name="SableLinux Test" \
    -c user.email="test@localhost" \
    commit -qm "test: isolated Beta 1 configuration fixture"

"$TMP/repo/scripts/kernel/build-kernel.sh" \
    prepare beta1-test1 > "$TMP/prepare.log" 2>&1 || {
        cat "$TMP/prepare.log"
        die "Beta 1 preparation failed"
    }

mapfile -t candidates < <(
    find "$TMP/workspace/kernel-builds" \
        -mindepth 1 -maxdepth 1 -type d -print
)

[[ "${#candidates[@]}" -eq 1 ]] ||
    die "expected exactly one prepared candidate"

CANDIDATE="${candidates[0]}"
CONFIG="$CANDIDATE/obj/.config"

[[ "$(cat "$CANDIDATE/BUILD_STATE")" == "prepared" ]] ||
    die "candidate state incorrect"

assert_config() {
    local option="$1" value="$2"

    grep -Fqx "CONFIG_${option}=${value}" "$CONFIG" ||
        die "CONFIG_${option}=${value} missing"

    printf 'PASS: CONFIG_%s=%s\n' "$option" "$value"
}

for option in \
    BT BT_HCIBTUSB BT_RFCOMM BT_BNEP BT_HIDP \
    BT_INTEL BT_MTK BT_RTL \
    ATH11K ATH11K_PCI IWLMVM \
    MHI_BUS QRTR QRTR_MHI QCOM_QMI_HELPERS
do
    assert_config "$option" m
done

for option in \
    BT_BREDR BT_LE \
    BT_HCIBTUSB_MTK BT_HCIBTUSB_RTL \
    PINCTRL PINCTRL_AMD GPIOLIB GPIOLIB_IRQCHIP \
    GPIO_ACPI COMMON_CLK \
    I2C_DESIGNWARE_CORE I2C_DESIGNWARE_PLATFORM \
    I2C_HID_ACPI HID_MULTITOUCH \
    SQUASHFS SQUASHFS_XATTR
do
    assert_config "$option" y
done

grep -Fqx 'CONFIG_LOCALVERSION="-sable-beta1-test1"' "$CONFIG" ||
    die "incorrect Beta 1 kernel local version"

grep -Fqx '# CONFIG_LOCALVERSION_AUTO is not set' "$CONFIG" ||
    die "unexpected automatic kernel version"

sha256sum -c \
    "$CANDIDATE/metadata/candidate-config.sha256" ||
    die "candidate configuration hash verification failed"

echo "=== FINAL CONFIGURATION SHA256 ==="
sha256sum "$CONFIG"

echo "=== RESULT ==="
echo "PASS: Beta 1 real-Kconfig regression"
echo "Evidence: $TMP"
