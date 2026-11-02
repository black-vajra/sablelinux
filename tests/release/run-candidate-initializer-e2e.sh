#!/usr/bin/env bash
set -Eeuo pipefail

REPO="/home/pepper/sablelinux"
WORKSPACE="/srv/sablelinux"
CID="20261028T212705Z-622d439-linux-6.16.1-xattr-test1"
POINTER="$WORKSPACE/state/current-build-id"
LOCK="$WORKSPACE/state/locks/create-build.lock"

die() {
    printf 'FAIL: %s\n' "$*" >&2
    exit 1
}

[ "$(id -u)" -ne 0 ] ||
    die "invoke as the normal build user, not root"

[ "$(hostname)" = "SableLinux" ] ||
    die "requires canonical Z890"

[ -d "$WORKSPACE/kernel-builds/$CID" ] ||
    die "reference candidate missing"

[ -f "$POINTER" ] && [ ! -L "$POINTER" ] ||
    die "invalid production pointer"

[ ! -e "$LOCK" ] ||
    die "canonical creation lock is present"

command -v sudo >/dev/null || die "sudo missing"
command -v unshare >/dev/null || die "unshare missing"

cd "$REPO"

[ "$(git branch --show-current)" = "development" ] ||
    die "wrong Git branch"

git diff --quiet || die "tracked source modifications present"
git diff --cached --quiet || die "staged changes present"

BEFORE_POINTER="$(sha256sum "$POINTER" | awk '{print $1}')"
BEFORE_BUILDS="$(
    find "$WORKSPACE/builds" -mindepth 1 -maxdepth 1 \
        -printf '%f\n' | LC_ALL=C sort | sha256sum | awk '{print $1}'
)"

TEST_ROOT="$(mktemp -d /var/tmp/sable-init-e2e.XXXXXXXX)" ||
    die "cannot create test directory"

printf 'Test root: %s\n' "$TEST_ROOT"

verify_host() {
    local result=0
    local after_pointer after_builds

    after_pointer="$(sha256sum "$POINTER" | awk '{print $1}')" ||
        result=1

    after_builds="$(
        find "$WORKSPACE/builds" -mindepth 1 -maxdepth 1 \
            -printf '%f\n' | LC_ALL=C sort | sha256sum | awk '{print $1}'
    )" || result=1

    [ "$BEFORE_POINTER" = "$after_pointer" ] || {
        echo "FAIL: Production pointer changed"
        result=1
    }

    [ "$BEFORE_BUILDS" = "$after_builds" ] || {
        echo "FAIL: Production build directory set changed"
        result=1
    }

    [ ! -e "$LOCK" ] || {
        echo "FAIL: Canonical creation lock present"
        result=1
    }

    if [ "$result" -eq 0 ]; then
        echo "PASS: Production pointer, build directory set and lock"
    fi

    return "$result"
}

finish() {
    local exit_status=$?
    trap - EXIT

    verify_host || exit_status=1

    printf 'Test evidence: %s\n' "$TEST_ROOT"
    exit "$exit_status"
}

trap finish EXIT

git clone --quiet --no-hardlinks \
    --branch development --single-branch \
    "$REPO" "$TEST_ROOT/repo"

mkdir -p \
    "$TEST_ROOT/workspace/builds" \
    "$TEST_ROOT/workspace/state/locks" \
    "$TEST_ROOT/workspace/kernel-builds/$CID"

printf '1\n' > "$TEST_ROOT/workspace/state/layout-version"
printf 'previous-test-build\n' \
    > "$TEST_ROOT/workspace/state/current-build-id"

# Create a temporary initializer with exactly two test-only changes.
python3 -B - "$TEST_ROOT" <<'PY'
import sys
from pathlib import Path

root = Path(sys.argv[1])
source = (
    root / "repo/scripts/release/create-build.sh"
).read_text()

changes = (
    (
        '    die "candidate release creation awaits staging integration"',
        '    : # Test-only gate bypass',
    ),
    (
        'WORK_DEVICE="$(findmnt -no SOURCE -T "$WORKSPACE")"',
        'WORK_DEVICE="$ROOT_DEVICE" # Test-only bind-mount adaptation',
    ),
)

for old, new in changes:
    if source.count(old) != 1:
        raise SystemExit(f"STOP: Unexpected initializer source: {old}")
    source = source.replace(old, new, 1)

destination = root / "create-build-test.sh"
destination.write_text(source)
destination.chmod(0o755)
PY

bash -n "$TEST_ROOT/create-build-test.sh"

sudo unshare --mount --propagation private \
    /bin/bash -s -- "$TEST_ROOT" "$CID" <<'INNER'
set -Eeuo pipefail

ROOT="$1"
CID="$2"
SANDBOX="$ROOT/workspace"
SOURCE="/srv/sablelinux/kernel-builds/$CID"
TARGET="$SANDBOX/kernel-builds/$CID"

mount --bind "$SOURCE" "$TARGET"
mount -o remount,bind,ro "$TARGET"

mount --bind "$ROOT/repo" /home/pepper/sablelinux
mount --rbind "$SANDBOX" /srv/sablelinux

OPTIONS="$(findmnt -n -o OPTIONS -T \
    "/srv/sablelinux/kernel-builds/$CID")"

case ",$OPTIONS," in
    *,ro,*) echo "PASS: Candidate mount is read-only" ;;
    *) echo "FAIL: Candidate mount is writable"; exit 1 ;;
esac

[ "$(cat /srv/sablelinux/state/current-build-id)" = \
    "previous-test-build" ]

SUDO_USER=pepper \
    bash "$ROOT/create-build-test.sh" \
    --kernel-candidate "$CID" \
    > "$ROOT/initializer.log" 2>&1 || {
        cat "$ROOT/initializer.log"
        exit 1
    }

cat "$ROOT/initializer.log"

BUILD_ID="$(cat /srv/sablelinux/state/current-build-id)"
BUILD_ROOT="/srv/sablelinux/builds/$BUILD_ID"

[ -d "$BUILD_ROOT" ]
[ "$(cat "$BUILD_ROOT/BUILD_STATE")" = "initialized" ]

grep -Fx "BUILD_STATE=initialized" \
    "$BUILD_ROOT/metadata/build.env"

(
    cd "$BUILD_ROOT/boot"
    sha256sum -c kernel-artifacts.sha256
)

cmp \
    "$BUILD_ROOT/metadata/candidate-kernel-modules.sha256" \
    "/srv/sablelinux/kernel-builds/$CID/metadata/kernel-modules.sha256"

python3 -B \
    /home/pepper/sablelinux/scripts/release/inspect-build-publication.py \
    --build-root "$BUILD_ROOT" \
    --state-dir /srv/sablelinux/state \
    > "$ROOT/inspection.json"

python3 -B - "$ROOT/inspection.json" <<'PY'
import json
import sys
from pathlib import Path

state = json.loads(Path(sys.argv[1]).read_text())

assert state["classification"] == "initialized-selected"
assert state["selected"] is True
assert state["metadata_state"] == "initialized"
assert state["completion_marker"] == "initialized"

print("PASS: Publication inspection")
PY

[ "$(stat -c '%U:%G' \
    /srv/sablelinux/state/current-build-id)" = "root:pepper" ]

[ "$(stat -c '%a' \
    /srv/sablelinux/state/current-build-id)" = "664" ]

printf '%s\n' "$BUILD_ID" > "$ROOT/generated-build-id"

echo "PASS: Complete isolated candidate initialization"
INNER

(
    cd "$TEST_ROOT"
    sha256sum \
        initializer.log \
        inspection.json \
        generated-build-id \
        > SHA256SUMS
    sha256sum -c SHA256SUMS
)

echo "PASS: M1.6F repeatable positive-path integration test"
