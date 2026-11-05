#!/usr/bin/env bash
set -Eeuo pipefail

# Required inputs: disposable workspace, synthetic fixture, candidate ID.
[ "$#" -eq 3 ] || {
    echo "Usage: $0 TEST_ROOT FIXTURE KERNEL_CANDIDATE_ID" >&2
    exit 2
}

ROOT="$1"
FIXTURE="$2"
CID="$3"
REAL="/srv/sablelinux"
REPO="/home/pepper/sablelinux"

# Never accept the canonical workspace as a writable test root.
[[ "$ROOT" == /var/tmp/sable-m112-e2e-* ]] || {
    echo "STOP: test root must be under /var/tmp/sable-m112-e2e-*" >&2
    exit 2
}

[ -d "$ROOT" ] && [ ! -L "$ROOT" ] || exit 2
[ "$FIXTURE" = "$ROOT/fixture" ] || exit 2
[[ "$CID" =~ ^[A-Za-z0-9._-]+$ ]] || exit 2

[ -d "$ROOT/repo/.git" ] || exit 1
[ -f "$FIXTURE/etc/passwd" ] || exit 1
[ -f "$FIXTURE/usr/lib/modules/host-test/kernel/host.ko" ] || exit 1

BUILD_ID="$(cat "$REAL/state/current-build-id")"


BUILD="$ROOT/workspace/builds/$BUILD_ID"
CANDIDATE="$REAL/kernel-builds/$CID"

[ -d "$CANDIDATE" ] || exit 1
[ -d "$BUILD/rootfs" ] || exit 1
[ -z "$(find "$BUILD/rootfs" -mindepth 1 -print -quit)" ] ||
    { echo "STOP: test rootfs is not empty"; exit 1; }

[ "$(cat "$BUILD/BUILD_STATE")" = "initialized" ] || exit 1

test -z "$(git -C "$ROOT/repo" status --porcelain)" ||
    { echo "STOP: disposable repository is dirty"; exit 1; }

BEFORE_POINTER="$(sha256sum "$REAL/state/current-build-id")"
BEFORE_STATE="$(sha256sum "$REAL/builds/$BUILD_ID/BUILD_STATE")"
BEFORE_ENV="$(sha256sum "$REAL/builds/$BUILD_ID/metadata/build.env")"

verify_production() {
    local result=0

    [ "$BEFORE_POINTER" = "$(sha256sum "$REAL/state/current-build-id")" ] ||
        result=1
    [ "$BEFORE_STATE" = "$(sha256sum "$REAL/builds/$BUILD_ID/BUILD_STATE")" ] ||
        result=1
    [ "$BEFORE_ENV" = "$(sha256sum "$REAL/builds/$BUILD_ID/metadata/build.env")" ] ||
        result=1
    [ -z "$(find "$REAL/builds/$BUILD_ID/rootfs" -mindepth 1 -print -quit)" ] ||
        result=1

    if [ "$result" -eq 0 ]; then
        echo "PASS: canonical pointer, state, metadata and empty rootfs unchanged"
    else
        echo "FAIL: canonical build protection check"
    fi
    return "$result"
}

finish() {
    local status=$?
    trap - EXIT
    verify_production || status=1
    echo "Test evidence: $ROOT"
    exit "$status"
}
trap finish EXIT

# Prepare a test-only generator.
# Abort if the production source differs from our verified anchors.
python3 -B - "$ROOT" "$FIXTURE" <<'PY'
import sys
from pathlib import Path

root = Path(sys.argv[1])
fixture = Path(sys.argv[2])
source = (root / "repo/scripts/live/generate-rootfs.sh").read_text()

changes = [
    (
        'WORK_DEVICE="$(findmnt -no SOURCE -T "$WORKSPACE")"',
        'WORK_DEVICE="$ROOT_DEVICE" # Test namespace adaptation',
    ),
    (
        'rsync "${RSYNC_OPTIONS[@]}" / "$ROOTFS/" 2>&1 |',
        f'rsync "${{RSYNC_OPTIONS[@]}}" "{fixture}/" "$ROOTFS/" 2>&1 |',
    ),
]

for old, new in changes:
    if source.count(old) != 1:
        raise SystemExit(f"STOP: expected test anchor missing: {old}")
    source = source.replace(old, new, 1)

if 'rsync "${RSYNC_OPTIONS[@]}" / "$ROOTFS/"' in source:
    raise SystemExit("STOP: live-root capture source remains")

target = root / "generate-rootfs-test.sh"
target.write_text(source)
target.chmod(0o755)
print("PASS: test-only source substitution verified")
PY

bash -n "$ROOT/generate-rootfs-test.sh"

echo "=== ISOLATED GENERATOR EXECUTION ==="

sudo unshare --mount --propagation private \
    /bin/bash -s -- "$ROOT" "$CID" "$BUILD_ID" <<'INNER'
set -Eeuo pipefail

ROOT="$1"
CID="$2"
BUILD_ID="$3"

SOURCE="/srv/sablelinux/kernel-builds/$CID"
TARGET="$ROOT/workspace/kernel-builds/$CID"

mkdir -p "$TARGET"

mount --bind "$SOURCE" "$TARGET"
mount -o remount,bind,ro "$TARGET"

mount --bind "$ROOT/repo" /home/pepper/sablelinux
mount --rbind "$ROOT/workspace" /srv/sablelinux

test "$(cat /srv/sablelinux/state/current-build-id)" = "$BUILD_ID"

OPTIONS="$(findmnt -n -o OPTIONS -T \
    "/srv/sablelinux/kernel-builds/$CID")"

case ",$OPTIONS," in
    *,ro,*) echo "PASS: candidate mounted read-only" ;;
    *) echo "FAIL: candidate is writable"; exit 1 ;;
esac

echo "PASS: disposable repository and workspace mounted"

if SUDO_USER=pepper \
    bash "$ROOT/generate-rootfs-test.sh" \
    --build-id "$BUILD_ID" --execute \
    > "$ROOT/generator.log" 2>&1
then
    echo "PASS: generator execution completed"
else
    status=$?
    echo "GENERATOR FAILED: exit $status"
    tail -25 "$ROOT/generator.log"
    exit "$status"
fi

BUILD="/srv/sablelinux/builds/$BUILD_ID"
RELEASE="6.16.1-sable-xattr-test1"

test "$(cat "$BUILD/BUILD_STATE")" = "rootfs-generated"
grep -qx 'KERNEL_MODULES_STAGED=true' "$BUILD/metadata/build.env"

(
    cd "$BUILD/rootfs"
    sha256sum --status -c \
        "$BUILD/metadata/candidate-kernel-modules.sha256"
)

test ! -e "$BUILD/rootfs/usr/lib/modules/host-test"
test ! -e "$BUILD/rootfs/home/pepper"

MODULE_DIR="$BUILD/rootfs/usr/lib/modules/$RELEASE"

[ "$(stat -c %a "$MODULE_DIR")" = 755 ] || {
    echo "FAIL: kernel module directory permissions"
    exit 1
}

echo "PASS: kernel module directory permissions 0755"

echo "PASS: final build state and staged modules verified"
echo "PASS: host module and private home excluded"
INNER

echo "SABLE_M111_GENERATOR_E2E_PASS"
