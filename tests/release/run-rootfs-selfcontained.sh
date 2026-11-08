#!/usr/bin/env bash
set -Eeuo pipefail

REPO="/home/pepper/sablelinux"
WORKSPACE="/srv/sablelinux"

die() {
    printf 'FAIL: %s\n' "$*" >&2
    exit 1
}

cd "$REPO"

[ "$(git branch --show-current)" = development ] ||
    die "expected development branch"

for tool in git python3 rsync unshare mount sha256sum; do
    command -v "$tool" >/dev/null ||
        die "missing required tool: $tool"
done

BUILD_ID="$(cat "$WORKSPACE/state/current-build-id")"
BUILD="$WORKSPACE/builds/$BUILD_ID"
ENV="$BUILD/metadata/build.env"

[ "$(cat "$BUILD/BUILD_STATE")" = initialized ] ||
    die "canonical build must remain initialized"

grep -qx 'BUILD_STATE=initialized' "$ENV" ||
    die "build metadata state mismatch"

grep -qx 'KERNEL_MODULES_STAGED=false' "$ENV" ||
    die "canonical modules must remain unstaged"

CID="$(sed -n 's/^KERNEL_CANDIDATE_ID=//p' "$ENV")"

[[ "$CID" =~ ^[A-Za-z0-9._-]+$ ]] ||
    die "invalid candidate identifier"

[ -d "$WORKSPACE/kernel-builds/$CID" ] ||
    die "kernel candidate missing"

[ -f "$BUILD/README.txt" ] ||
    die "initializer README missing"

[ -f "$BUILD/metadata/candidate-kernel-modules.sha256" ] ||
    die "module manifest missing"

[ -z "$(find "$BUILD/rootfs" -mindepth 1 -print -quit)" ] ||
    die "canonical rootfs is not empty"

echo "PASS: M1.12 canonical preflight"
echo "Build: $BUILD_ID"
echo "Candidate: $CID"

echo
echo "=== CREATE DISPOSABLE TEST ENVIRONMENT ==="

TEST_ROOT="$(mktemp -d /var/tmp/sable-m112-e2e-XXXXXXXX)"
echo "Test root: $TEST_ROOT"

mkdir -p "$TEST_ROOT/fixture"

bash tests/release/create-rootfs-fixture.sh \
    "$TEST_ROOT/fixture"

# Seed the install metadata probe outside paths subject to user sanitation.
sudo python3 - "$TEST_ROOT/fixture" <<'METADATA_FIXTURE'
import os
import sys
from pathlib import Path

directory = Path(sys.argv[1]) / "usr/share/sable-install-test"
directory.mkdir(parents=True)
probe = directory / "metadata"
with probe.open("xb") as stream:
    stream.write(b"SableLinux install metadata fixture\n")
os.chown(probe, 12345, 23456)
os.chmod(probe, 0o640)
os.setxattr(probe, "user.sable_install_test", b"preserved")
os.link(probe, directory / "metadata.link")

info = probe.stat()
assert (info.st_uid, info.st_gid, info.st_mode & 0o7777) == (12345, 23456, 0o640)
assert (directory / "metadata.link").stat().st_ino == info.st_ino
assert info.st_nlink == 2
assert os.getxattr(probe, "user.sable_install_test") == b"preserved"
print("PASS: source install metadata fixture verified")
METADATA_FIXTURE

[ -f "$TEST_ROOT/fixture/usr/lib/modules/host-test/kernel/host.ko" ] ||
    die "synthetic host module missing"

# Supply the distribution identity checked in the generated image.
printf '%s\n' 'NAME="SableLinux"' 'ID=sablelinux' \
    > "$TEST_ROOT/fixture/etc/os-release"

echo "PASS: synthetic fixture generated"

echo
echo "=== CREATE DISPOSABLE GIT REVISION ==="

git clone --quiet --no-hardlinks \
    --branch development --single-branch \
    "$REPO" "$TEST_ROOT/repo"

# Import only the test changes, not unrelated files.
cp -p tests/release/create-rootfs-fixture.sh "$TEST_ROOT/repo/tests/release/"
git -C "$TEST_ROOT/repo" add -- tests/release/create-rootfs-fixture.sh

cp -p scripts/live/generate-rootfs.sh \
    "$TEST_ROOT/repo/scripts/live/"

cp -p scripts/live/build-squashfs.sh \
    scripts/live/build-live-initramfs-stage.sh \
    "$TEST_ROOT/repo/scripts/live/"

git -C "$TEST_ROOT/repo" add -- \
    scripts/live/generate-rootfs.sh scripts/live/build-squashfs.sh \
    scripts/live/build-live-initramfs-stage.sh

cp -p tests/release/run-rootfs-generator-e2e.sh \
    "$TEST_ROOT/repo/tests/release/"

cp -p tests/release/run-rootfs-selfcontained.sh \
    "$TEST_ROOT/repo/tests/release/"

git -C "$TEST_ROOT/repo" add -- \
    tests/release/run-rootfs-generator-e2e.sh \
    tests/release/run-rootfs-selfcontained.sh

if ! git -C "$TEST_ROOT/repo" diff --cached --quiet; then
    git -C "$TEST_ROOT/repo" \
        -c user.name="SableLinux Integration Test" \
        -c user.email="integration-test@localhost" \
        commit -qm "TEST ONLY: M1.12 integration harness"
fi

[ -z "$(git -C "$TEST_ROOT/repo" status --porcelain)" ] ||
    die "disposable checkout is dirty"

BUILD_COMMIT="$(sed -n 's/^GIT_COMMIT=//p' "$ENV")"

git -C "$TEST_ROOT/repo" merge-base --is-ancestor \
    "$BUILD_COMMIT" HEAD ||
    die "build provenance mismatch"

echo "PASS: clean disposable Git revision"
git -C "$TEST_ROOT/repo" log -1 --oneline

echo
echo "=== RETAINED TEST EVIDENCE ==="
echo "$TEST_ROOT"


echo
echo "=== INITIALIZE DISPOSABLE BUILD ==="

DEST="$TEST_ROOT/workspace/builds/$BUILD_ID"

mkdir -p \
    "$TEST_ROOT/workspace/state/locks" \
    "$TEST_ROOT/workspace/kernel-builds" \
    "$DEST"/{rootfs,boot,squashfs,initramfs,media,installer,logs,metadata,reports,tmp}

printf '%s\n' "$BUILD_ID" \
    > "$TEST_ROOT/workspace/state/current-build-id"

printf '%s\n' initialized > "$DEST/BUILD_STATE"

cp -p "$BUILD/README.txt" "$DEST/README.txt"
cp -p "$ENV" "$DEST/metadata/build.env"
cp -p "$BUILD/metadata/candidate-kernel-modules.sha256" \
    "$DEST/metadata/candidate-kernel-modules.sha256"

[ -z "$(find "$DEST/rootfs" -mindepth 1 -print -quit)" ] ||
    die "disposable rootfs is not empty"

[ -f "$DEST/README.txt" ] ||
    die "disposable README missing"

grep -qx 'BUILD_STATE=initialized' "$DEST/metadata/build.env" ||
    die "disposable metadata state mismatch"

grep -qx 'KERNEL_MODULES_STAGED=false' "$DEST/metadata/build.env" ||
    die "disposable module state mismatch"

[ "$(wc -l < "$DEST/metadata/candidate-kernel-modules.sha256")" -eq 57 ] ||
    die "unexpected module manifest entry count"

RELEASE="$(sed -n 's/^KERNEL_RELEASE=//p' "$ENV")"
[[ "$RELEASE" =~ ^[A-Za-z0-9][A-Za-z0-9._+-]*$ ]] ||
    die "invalid fixture kernel release"
cp -p "$BUILD/boot/config-$RELEASE" "$BUILD/boot/kernel-artifacts.sha256" \
    "$DEST/boot/"
cp -p "$BUILD/metadata/kernel-artifacts.sha256" "$DEST/metadata/"
cp -p "$BUILD/boot/vmlinuz-$RELEASE" "$DEST/boot/"

echo "PASS: complete disposable build initialized"
echo "PASS: README and metadata preserved"
echo "PASS: 57-entry candidate module manifest"

echo
echo
echo "=== M1.12 ISOLATED GENERATOR TEST ==="

bash "$REPO/tests/release/run-rootfs-generator-e2e.sh" \
    "$TEST_ROOT" \
    "$TEST_ROOT/fixture" \
    "$CID"

echo
echo "SABLE_M112_SELFCONTAINED_E2E_PASS"
