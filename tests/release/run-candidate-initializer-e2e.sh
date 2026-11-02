#!/usr/bin/env bash
set -Eeuo pipefail

TEST_MODE="${1:-success}"

case "$TEST_MODE" in
    success|invalid-candidate|staging-failure|provenance-failure|publication-failure)
        ;;
    *)
        printf 'FAIL: Unknown test mode: %s\n' "$TEST_MODE" >&2
        exit 2
        ;;
esac

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

git diff --quiet -- . ':(exclude)tests/release/run-candidate-initializer-e2e.sh' || die "tracked source modifications present"
git diff --cached --quiet -- . ':(exclude)tests/release/run-candidate-initializer-e2e.sh' || die "staged changes present"

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
python3 -B - "$TEST_ROOT" "$TEST_MODE" <<'PY'
import sys
from pathlib import Path

root = Path(sys.argv[1])
mode = sys.argv[2]
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


# Modify only the disposable initializer, never the Git clone.
if mode == "staging-failure":
    old = 'STAGER="$REPO/scripts/release/stage-kernel-artifacts.py"'
    new = 'STAGER="/nonexistent/sable-test/stager.py"'
    if source.count(old) != 1:
        raise SystemExit("STOP: Stager anchor changed")
    source = source.replace(old, new, 1)

elif mode == "provenance-failure":
    needle = '    sha256sum "$KERNEL_IMAGE" "$SYSTEM_MAP" \\'
    fault = (
        '    printf "%s\\n" "INJECTED_PROVENANCE_FAILURE" >> '
        '"$BUILD_ROOT/metadata/candidate-kernel-modules.sha256"\n'
    )
    if source.count(needle) != 1:
        raise SystemExit("STOP: Provenance anchor changed")
    source = source.replace(needle, fault + needle, 1)

elif mode == "publication-failure":
    shim = root / "publish-fault.py"
    shim.write_text(
        "#!/usr/bin/env python3\n"
        "import os\n"
        "import runpy\n"
        "from pathlib import Path\n"
        "original = os.replace\n"
        "def fail_pointer(src, dst):\n"
        "    if Path(dst) == "
        "Path('/srv/sablelinux/state/current-build-id'):\n"
        "        raise OSError('INJECTED_POINTER_WRITE_FAILURE')\n"
        "    return original(src, dst)\n"
        "os.replace = fail_pointer\n"
        "runpy.run_path(\n"
        "    '/home/pepper/sablelinux/scripts/release/"
        "publish-candidate-build.py',\n"
        "    run_name='__main__',\n"
        ")\n"
    )

    old = (
        'PUBLISHER="$REPO/scripts/release/'
        'publish-candidate-build.py"'
    )
    if source.count(old) != 1:
        raise SystemExit("STOP: Publisher anchor changed")
    source = source.replace(
        old, f'PUBLISHER="{shim}"', 1
    )

destination = root / "create-build-test.sh"
destination.write_text(source)
destination.chmod(0o755)
PY

bash -n "$TEST_ROOT/create-build-test.sh"

sudo unshare --mount --propagation private \
    /bin/bash -s -- "$TEST_ROOT" "$CID" "$TEST_MODE" <<'INNER'
set -Eeuo pipefail

ROOT="$1"
CID="$2"
MODE="$3"
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

RUN_CID="$CID"
if [ "$MODE" = "invalid-candidate" ]; then
    RUN_CID="missing-integration-test-candidate"
fi

if SUDO_USER=pepper \
    bash "$ROOT/create-build-test.sh" \
    --kernel-candidate "$RUN_CID" \
    > "$ROOT/initializer.log" 2>&1
then
    INIT_STATUS=0
else
    INIT_STATUS=$?
fi

cat "$ROOT/initializer.log"

if [ "$MODE" = "success" ]; then
    [ "$INIT_STATUS" -eq 0 ] || {
        echo "FAIL: Successful initialization was rejected"
        exit 1
    }
else
    [ "$INIT_STATUS" -ne 0 ] || {
        echo "FAIL: Fault scenario unexpectedly succeeded"
        exit 1
    }

    test "$(cat /srv/sablelinux/state/current-build-id)" = \
        "previous-test-build"

    case "$MODE" in
        invalid-candidate)
            grep -q "candidate directory unavailable" \
                "$ROOT/initializer.log"
            EXPECTED_COUNT=0
            ;;
        staging-failure)
            grep -q "candidate kernel artifact staging failed" \
                "$ROOT/initializer.log"
            EXPECTED_COUNT=1
            ;;
        provenance-failure)
            grep -q "kernel provenance verification failed" \
                "$ROOT/initializer.log"
            EXPECTED_COUNT=1
            ;;
        publication-failure)
            grep -q "INJECTED_POINTER_WRITE_FAILURE" \
                "$ROOT/initializer.log"
            EXPECTED_COUNT=1
            ;;
        *)
            echo "FAIL: Unsupported test scenario"
            exit 1
            ;;
    esac

    mapfile -t BUILDS < <(
        find /srv/sablelinux/builds -mindepth 1 \
            -maxdepth 1 -type d -print
    )

    [ "${#BUILDS[@]}" -eq "$EXPECTED_COUNT" ] || {
        echo "FAIL: Unexpected number of test builds"
        exit 1
    }

    if [ "$EXPECTED_COUNT" -eq 1 ]; then
        FAILED_BUILD="${BUILDS[0]}"
        ENV="$FAILED_BUILD/metadata/build.env"
        MARKER="$FAILED_BUILD/BUILD_STATE"

        if [ "$MODE" = "publication-failure" ]; then
            grep -Fxq "BUILD_STATE=initialized" "$ENV"
            test "$(cat "$MARKER")" = "initialized"
        else
            grep -Fxq "BUILD_STATE=initializing" "$ENV"
            test "$(cat "$MARKER")" = "initializing"
        fi

        if [ "$MODE" = "staging-failure" ]; then
            test ! -e \
                "$FAILED_BUILD/boot/kernel-artifacts.sha256"
        fi

        if [ "$MODE" = "provenance-failure" ]; then
            grep -q "INJECTED_PROVENANCE_FAILURE" \
                "$FAILED_BUILD/metadata/candidate-kernel-modules.sha256"
        fi
    fi

    printf 'MODE=%s\nRESULT=EXPECTED_FAILURE\n' \
        "$MODE" > "$ROOT/failure-result.txt"

    echo "PASS: Expected failure boundary reached"
    echo "PASS: Previous test pointer preserved"
    echo "PASS: Failed build state validated"
    exit 0
fi

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

if [ "$TEST_MODE" = "success" ]; then
    EVIDENCE=(
        initializer.log
        inspection.json
        generated-build-id
    )
else
    EVIDENCE=(
        initializer.log
        failure-result.txt
    )
fi

(
    cd "$TEST_ROOT"
    sha256sum "${EVIDENCE[@]}" > SHA256SUMS
    sha256sum -c SHA256SUMS
)

echo "PASS: Isolated initializer scenario: $TEST_MODE"
