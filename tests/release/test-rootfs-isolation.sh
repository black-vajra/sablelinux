#!/usr/bin/env bash
set -Eeuo pipefail

REAL_WORKSPACE="/srv/sablelinux"
FIXTURE="/var/tmp/sable-m111-fixture-AQDyvQau"

[ -d "$FIXTURE" ] && [ ! -L "$FIXTURE" ] ||
    { echo "FAIL: fixture unavailable"; exit 1; }

command -v unshare >/dev/null
command -v rsync >/dev/null

ORIGINAL_POINTER="$(cat "$REAL_WORKSPACE/state/current-build-id")"
ORIGINAL_STATE="$(
    cat "$REAL_WORKSPACE/builds/$ORIGINAL_POINTER/BUILD_STATE"
)"

TEST_ROOT="$(mktemp -d /var/tmp/sable-m111-isolation-XXXXXXXX)"

mkdir -p \
    "$TEST_ROOT/workspace/state" \
    "$TEST_ROOT/workspace/builds" \
    "$TEST_ROOT/workspace/kernel-builds" \
    "$TEST_ROOT/captured"

printf 'isolated-test-build\n' \
    > "$TEST_ROOT/workspace/state/current-build-id"

echo "=== DISPOSABLE TEST ROOT ==="
echo "$TEST_ROOT"

echo
echo "=== PRIVATE MOUNT NAMESPACE ==="

sudo unshare --mount --propagation private \
    /bin/bash -s -- "$TEST_ROOT" "$FIXTURE" <<'INNER'
set -Eeuo pipefail

ROOT="$1"
FIXTURE="$2"

mount --bind "$ROOT/workspace" /srv/sablelinux

CURRENT="$(
    cat /srv/sablelinux/state/current-build-id
)"

[ "$CURRENT" = "isolated-test-build" ] ||
    { echo "FAIL: workspace redirection"; exit 1; }

echo "PASS: disposable workspace mounted"

# Only the synthetic source is copied.
rsync -a \
    "$FIXTURE/" \
    "$ROOT/captured/"

test -f \
    "$ROOT/captured/usr/lib/modules/host-test/kernel/host.ko"

test -f \
    "$ROOT/captured/home/pepper/private-test.txt"

echo "PASS: synthetic filesystem captured"

test -L "$ROOT/captured/lib"
test "$(readlink "$ROOT/captured/lib")" = "usr/lib"

echo "PASS: merged-/usr preserved"

echo "PASS: namespace isolation checks completed"
INNER

echo
echo "=== VERIFY CANONICAL STATE ==="

CURRENT_POINTER="$(
    cat "$REAL_WORKSPACE/state/current-build-id"
)"

CURRENT_STATE="$(
    cat "$REAL_WORKSPACE/builds/$ORIGINAL_POINTER/BUILD_STATE"
)"

[ "$CURRENT_POINTER" = "$ORIGINAL_POINTER" ] ||
    { echo "FAIL: production pointer changed"; exit 1; }

[ "$CURRENT_STATE" = "$ORIGINAL_STATE" ] ||
    { echo "FAIL: production build state changed"; exit 1; }

echo "PASS: canonical pointer unchanged"
echo "PASS: canonical build state unchanged"

echo
echo "=== RETAINED TEST EVIDENCE ==="
echo "$TEST_ROOT"

echo
echo "SABLE_M111_ISOLATION_PASS"
