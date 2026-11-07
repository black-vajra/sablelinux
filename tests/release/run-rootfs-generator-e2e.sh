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
FINALIZATION_TEST="${SABLE_TEST_FINALIZATION:-normal}"
case "$FINALIZATION_TEST" in
    normal|normal-with-squashfs|interrupt-after-build-env) ;;
    *) echo "STOP: invalid finalization test mode" >&2; exit 2 ;;
esac
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
python3 -B - "$ROOT" "$FIXTURE" "$FINALIZATION_TEST" <<'PY'
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

if sys.argv[3] == "interrupt-after-build-env":
    anchor = "# The authoritative state marker is published last."
    changes.append((
        anchor,
        'echo "TEST: interrupt after build.env publication" >&2\n'
        'kill -KILL "$BASHPID"\n\n' + anchor,
    ))

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
    /bin/bash -s -- "$ROOT" "$CID" "$BUILD_ID" "$FINALIZATION_TEST" <<'INNER'
set -Eeuo pipefail

ROOT="$1"
CID="$2"
BUILD_ID="$3"
FINALIZATION_TEST="$4"

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

# Verify refusal before any build writes while another process holds the lock.
BUILD="/srv/sablelinux/builds/$BUILD_ID"

snapshot_build() {
    (
        cd "$BUILD"
        find . -xdev -printf '%P\t%y\t%m\t%U\t%G\t%s\t%T@\t%l\n' | sort
        find . -xdev -type f -print0 | sort -z |
            xargs -0 -r sha256sum
    )
}

snapshot_build > "$ROOT/lock-before.txt"

(
    exec {TEST_LOCK_FD}<"$BUILD"
    flock --exclusive --nonblock "$TEST_LOCK_FD"

    if SUDO_USER=pepper bash "$ROOT/generate-rootfs-test.sh" \
        --build-id "$BUILD_ID" --execute \
        > "$ROOT/lock-contention.log" 2>&1
    then
        echo "FAIL: generator accepted a locked build"
        exit 1
    fi

    grep -qx 'ERROR: another operation holds the build lock' \
        "$ROOT/lock-contention.log"
)

snapshot_build > "$ROOT/lock-after.txt"
cmp "$ROOT/lock-before.txt" "$ROOT/lock-after.txt"
echo "PASS: build lock contention refused without build changes"


if [ "$FINALIZATION_TEST" = "interrupt-after-build-env" ]; then
    status=0
    SUDO_USER=pepper bash "$ROOT/generate-rootfs-test.sh" \
        --build-id "$BUILD_ID" --execute \
        > "$ROOT/generator-interrupted.log" 2>&1 || status=$?
    if [ "$status" -ne 137 ]; then
        echo "FAIL: expected SIGKILL exit 137, got $status" >&2
        tail -25 "$ROOT/generator-interrupted.log"
        exit 1
    fi
    grep -qx 'TEST: interrupt after build.env publication' \
        "$ROOT/generator-interrupted.log"
    test "$(cat "$BUILD/BUILD_STATE")" = initialized
    test ! -e "$BUILD/.BUILD_STATE.final"
    grep -qx 'BUILD_STATE=rootfs-generated' "$BUILD/metadata/build.env"
    grep -qx 'KERNEL_MODULES_STAGED=true' "$BUILD/metadata/build.env"
    cmp "$BUILD/metadata/build.env" "$BUILD/rootfs/etc/sablelinux/build.env"
    (
        cd "$BUILD/rootfs"
        sha256sum --status -c \
            "$BUILD/metadata/candidate-kernel-modules.sha256"
    )

    snapshot_build > "$ROOT/interrupted-before.txt"
    for helper in inspect-module-staging.py recover-module-staging.py; do
        action=()
        if [ "$helper" = recover-module-staging.py ]; then
            action=(--quarantine-orphan-manifest)
        fi
        status=0
        python3 -B "/home/pepper/sablelinux/scripts/release/$helper" \
            --build-root "$BUILD" "${action[@]}" \
            > "$ROOT/$helper.interrupted.log" 2>&1 || status=$?
        test "$status" -eq 1
        grep -qx 'ERROR: build state mismatch' "$ROOT/$helper.interrupted.log"
    done
    status=0
    SUDO_USER=pepper bash /home/pepper/sablelinux/scripts/live/build-squashfs.sh \
        --build-id "$BUILD_ID" \
        > "$ROOT/squashfs-interrupted.log" 2>&1 || status=$?
    test "$status" -eq 1
    grep -qx 'ERROR: build must be rootfs-generated' \
        "$ROOT/squashfs-interrupted.log"
    test ! -e "/srv/sablelinux/state/locks/squashfs-$BUILD_ID.lock"
    echo "PASS: SquashFS refused interrupted rootfs state"

    snapshot_build > "$ROOT/interrupted-after.txt"
    cmp "$ROOT/interrupted-before.txt" "$ROOT/interrupted-after.txt"
    cp -p "$BUILD/BUILD_STATE" "$ROOT/interrupted-state.saved"
    cp -p "$BUILD/metadata/build.env" "$ROOT/interrupted-env.saved"
    printf '%s\n' rootfs-generated > "$BUILD/BUILD_STATE"
    sed 's/^BUILD_STATE=.*/BUILD_STATE=initialized/' \
        "$ROOT/interrupted-env.saved" > "$BUILD/metadata/build.env"

    snapshot_build > "$ROOT/reverse-mismatch-before.txt"
    status=0
    SUDO_USER=pepper bash /home/pepper/sablelinux/scripts/live/build-squashfs.sh \
        --build-id "$BUILD_ID" \
        > "$ROOT/squashfs-reverse-mismatch.log" 2>&1 || status=$?
    test "$status" -eq 1
    grep -qx 'ERROR: build metadata must contain exactly one rootfs-generated state' \
        "$ROOT/squashfs-reverse-mismatch.log"
    test ! -e "/srv/sablelinux/state/locks/squashfs-$BUILD_ID.lock"
    snapshot_build > "$ROOT/reverse-mismatch-after.txt"
    cmp "$ROOT/reverse-mismatch-before.txt" "$ROOT/reverse-mismatch-after.txt"

    cp -p "$ROOT/interrupted-state.saved" "$BUILD/BUILD_STATE"
    cp -p "$ROOT/interrupted-env.saved" "$BUILD/metadata/build.env"
    snapshot_build > "$ROOT/interrupted-restored.txt"
    cmp "$ROOT/interrupted-before.txt" "$ROOT/interrupted-restored.txt"
    echo "PASS: SquashFS refused reverse state mismatch"
    echo "PASS: interrupted finalization preserved modules and refused recovery"
    exit 0
fi

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

# Probe the real SquashFS preflight in the disposable namespace.
generation_env="$BUILD/metadata/rootfs-generation.env"
cp -p "$generation_env" "$ROOT/rootfs-generation.env.saved"

status=0
sed 's/^SOURCE_GIT_COMMIT=.*/SOURCE_GIT_COMMIT=0000000000000000000000000000000000000000/' \
    "$ROOT/rootfs-generation.env.saved" > "$generation_env"
SUDO_USER=pepper bash /home/pepper/sablelinux/scripts/live/build-squashfs.sh \
    --build-id "$BUILD_ID" \
    > "$ROOT/squashfs-provenance-mismatch.log" 2>&1 || status=$?
cp -p "$ROOT/rootfs-generation.env.saved" "$generation_env"
test "$status" -eq 1
grep -qx 'ERROR: repository commit does not match rootfs generation provenance' \
    "$ROOT/squashfs-provenance-mismatch.log"

(
    probe="$(mktemp /home/pepper/sablelinux/.squashfs-preflight-XXXXXXXX)"
    trap 'rm -f -- "$probe"' EXIT
    status=0
    SUDO_USER=pepper bash /home/pepper/sablelinux/scripts/live/build-squashfs.sh \
        --build-id "$BUILD_ID" \
        > "$ROOT/squashfs-provenance-valid.log" 2>&1 || status=$?
    test "$status" -eq 1
    grep -qx 'ERROR: repository contains uncommitted changes' \
        "$ROOT/squashfs-provenance-valid.log"
)
test ! -e "/srv/sablelinux/state/locks/squashfs-$BUILD_ID.lock"
echo "PASS: SquashFS accepted valid rootfs provenance and rejected mismatch"

echo "PASS: host module and private home excluded"

if [ "$FINALIZATION_TEST" = "normal-with-squashfs" ]; then
    repo=/home/pepper/sablelinux
    config="$BUILD/boot/config-$RELEASE"
    cp -p "$config" "$ROOT/staged-config.saved"
    printf '\n# injected config corruption\n' >> "$config"
    status=0
    SUDO_USER=pepper bash "$repo/scripts/live/build-squashfs.sh" \
        --build-id "$BUILD_ID" \
        > "$ROOT/squashfs-config-corruption.log" 2>&1 || status=$?
    cp -p "$ROOT/staged-config.saved" "$config"
    test "$status" -eq 1
    grep -qx 'ERROR: staged kernel config checksum mismatch' \
        "$ROOT/squashfs-config-corruption.log"
    test ! -e "/srv/sablelinux/state/locks/squashfs-$BUILD_ID.lock"
    test ! -e "$BUILD/squashfs/filesystem.squashfs"
    echo "PASS: SquashFS refused a corrupted staged kernel config"

    python3 -B - "$repo" "$ROOT/build-squashfs-test.sh" <<'SQUASHFS_PY'
import sys
from pathlib import Path

repo, target = sys.argv[1:]
source = (Path(repo) / "scripts/live/build-squashfs.sh").read_text()
size_anchor = '[ "$OUTPUT_BYTES" -gt 1073741824 ]'
if source.count(size_anchor) != 1:
    raise SystemExit("STOP: unexpected SquashFS size test anchor")
Path(target).write_text(source.replace(size_anchor, '[ "$OUTPUT_BYTES" -gt 0 ]', 1))
SQUASHFS_PY

    bash -n "$ROOT/build-squashfs-test.sh"
    if SUDO_USER=pepper bash "$ROOT/build-squashfs-test.sh" \
        --build-id "$BUILD_ID" > "$ROOT/squashfs-image.log" 2>&1
    then
        echo "PASS: disposable SquashFS generation completed"
    else
        status=$?
        tail -50 "$ROOT/squashfs-image.log"
        exit "$status"
    fi

    test "$(cat "$BUILD/BUILD_STATE")" = squashfs-generated
    grep -qx 'BUILD_STATE=squashfs-generated' "$BUILD/metadata/build.env"
    sha256sum --status -c "$BUILD/metadata/squashfs.sha256"
    init_commit="$(sed -n 's/^GIT_COMMIT=//p' "$BUILD/metadata/build.env")"
    generation_commit="$(git -c safe.directory="$repo" -C "$repo" rev-parse HEAD)"
    test "$init_commit" != "$generation_commit"
    unsquashfs -cat "$BUILD/squashfs/filesystem.squashfs" \
        etc/sablelinux/build.env > "$ROOT/squashfs-embedded-build.env"
    grep -Fxq "GIT_COMMIT=$init_commit" "$ROOT/squashfs-embedded-build.env"
    grep -Fxq "GIT_COMMIT=$generation_commit" "$BUILD/metadata/squashfs.env"
    echo "PASS: SquashFS checksum and distinct provenance records verified"

    (
        # Stop valid input at the clean-checkout gate, before build writes.
        probe="$(mktemp "$repo/.initramfs-preflight-XXXXXXXX")"
        trap 'rm -f -- "$probe"' EXIT
        stage="$repo/scripts/live/build-live-initramfs-stage.sh"
        image="$BUILD/squashfs/filesystem.squashfs"
        env_file="$BUILD/metadata/build.env"

        expect_initramfs_refusal() {
            local label="$1" message="$2" status=0
            local log="$ROOT/initramfs-preflight-$label.log"
            SUDO_USER=pepper bash "$stage" --build-id "$BUILD_ID" \
                > "$log" 2>&1 || status=$?
            if [ "$status" -ne 1 ] || ! grep -Fxq "ERROR: $message" "$log"; then
                echo "FAIL: unexpected initramfs preflight result ($label, exit $status)" >&2
                cat "$log" >&2
                return 1
            fi
            test ! -e "/srv/sablelinux/state/locks/initramfs-$BUILD_ID.lock"
            test ! -e "$BUILD/initramfs/initramfs-live.img"
        }

        expect_initramfs_refusal valid 'repository contains uncommitted changes'

        cp -p "$image" "$ROOT/initramfs-preflight-image.saved"
        printf 'injected corruption\n' >> "$image"
        expect_initramfs_refusal checksum 'SquashFS input checksum mismatch'
        cp -p "$ROOT/initramfs-preflight-image.saved" "$image"

        cp -p "$env_file" "$ROOT/initramfs-preflight-env.saved"
        sed 's/^BUILD_STATE=.*/BUILD_STATE=rootfs-generated/' \
            "$ROOT/initramfs-preflight-env.saved" > "$env_file"
        expect_initramfs_refusal state \
            'build metadata must contain exactly one squashfs-generated state'
        cp -p "$ROOT/initramfs-preflight-env.saved" "$env_file"

        sha256sum --status -c "$BUILD/metadata/squashfs.sha256"
        echo "PASS: initramfs accepted valid SquashFS provenance and refused corrupt or split state"
    )

    stage="$repo/scripts/live/build-live-initramfs-stage.sh"
    kernel="$BUILD/boot/vmlinuz-$RELEASE"
    cp -p "$kernel" "$ROOT/initramfs-staged-kernel.saved"
    printf 'injected corruption\n' >> "$kernel"

    status=0
    SUDO_USER=pepper bash "$stage" --build-id "$BUILD_ID" \
        > "$ROOT/initramfs-kernel-corruption.log" 2>&1 || status=$?
    cp -p "$ROOT/initramfs-staged-kernel.saved" "$kernel"

    if [ "$status" -ne 1 ] ||
       ! grep -Fxq 'ERROR: staged kernel image checksum mismatch' \
            "$ROOT/initramfs-kernel-corruption.log"
    then
        echo "FAIL: unexpected staged kernel preflight result (exit $status)" >&2
        cat "$ROOT/initramfs-kernel-corruption.log" >&2
        exit 1
    fi
    test ! -e "/srv/sablelinux/state/locks/initramfs-$BUILD_ID.lock"
    test ! -e "$BUILD/initramfs/initramfs-live.img"
    echo "PASS: initramfs refused a corrupted staged kernel"

    if SUDO_USER=pepper bash "$stage" --build-id "$BUILD_ID" \
        > "$ROOT/initramfs-image.log" 2>&1
    then
        echo "PASS: disposable live initramfs generation completed"
    else
        status=$?
        tail -60 "$ROOT/initramfs-image.log"
        exit "$status"
    fi

    grep -Fxq 'PASS: repeated initramfs builds are byte-identical' \
        "$ROOT/initramfs-image.log"
    test "$(cat "$BUILD/BUILD_STATE")" = initramfs-generated
    grep -Fxq 'BUILD_STATE=initramfs-generated' "$BUILD/metadata/build.env"
    cmp "$ROOT/initramfs-staged-kernel.saved" "$kernel"
    sha256sum --status -c "$BUILD/metadata/live-boot-inputs.sha256"
    echo "PASS: initramfs reproducibility, state and live boot inputs verified"
fi
INNER

echo "SABLE_M111_GENERATOR_E2E_PASS"
