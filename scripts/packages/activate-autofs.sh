#!/bin/bash
set -Eeuo pipefail

ROOT="/srv/sablelinux/package-builds/autofs/5.1.9"
STAGE="$ROOT/stage"
MANIFEST="$ROOT/manifests/staged-sha256.txt"
REPORT="$ROOT/reports/activation-report.txt"
REPO="/home/pepper/sablelinux"

ACTIVATION_STARTED=false
ACTIVATION_COMPLETE=false

mkdir -p "$ROOT/reports"
exec > >(tee "$REPORT") 2>&1

fail()
{
    echo "STOP: $*" >&2
    return 1
}

rollback()
{
    status=$?

    if test "$ACTIVATION_STARTED" = true &&
       test "$ACTIVATION_COMPLETE" != true; then
        echo
        echo "=== AUTOMATIC ROLLBACK ==="

        systemctl stop autofs.service 2>/dev/null || true
        systemctl disable autofs.service 2>/dev/null || true

        while IFS= read -r -d '' staged_object
        do
            relative="${staged_object#"$STAGE"/}"
            rm -f -- "/$relative"
        done < <(
            find "$STAGE" \( -type f -o -type l \) -print0
        )

        rm -rf /usr/lib/autofs
        rmdir /etc/auto.master.d 2>/dev/null || true

        ldconfig
        systemctl daemon-reload
        systemctl reset-failed autofs.service 2>/dev/null || true

        echo "ROLLBACK: newly installed autofs payload removed"
    fi

    exit "$status"
}

trap rollback ERR INT TERM

echo "=== AUTOFS 5.1.9 GUARDED ACTIVATION ==="

test "$(id -u)" -eq 0 ||
    fail "activation must run as root"

test -d "$STAGE" ||
    fail "staging root missing: $STAGE"

test -f "$MANIFEST" ||
    fail "staged SHA256 manifest missing: $MANIFEST"

test -d "$REPO/.git" ||
    fail "canonical repository missing"

test "$(git -C "$REPO" branch --show-current)" = "development" ||
    fail "repository is not on development"

test -z "$(git -C "$REPO" status --porcelain)" || {
    git -C "$REPO" status --short
    fail "repository is not clean"
}

echo "PASS: canonical repository state verified"

echo
echo "=== VERIFY STAGED MANIFEST ==="

(
    cd "$STAGE"
    sha256sum -c "$MANIFEST"
)

echo "PASS: staged SHA256 manifest validates"

echo
echo "=== VERIFY STAGED POLICY ==="

ACTIVE_MASTER_ENTRIES="$(
    grep -Ev '^[[:space:]]*(#|$)' "$STAGE/etc/auto.master"
)"

test "$ACTIVE_MASTER_ENTRIES" = "+dir:/etc/auto.master.d" ||
    fail "unexpected active auto.master policy"

test -d "$STAGE/etc/auto.master.d" ||
    fail "staged auto.master.d directory missing"

for omitted in auto.misc auto.net auto.smb
do
    test ! -e "$STAGE/etc/$omitted" ||
        fail "demonstration map staged: $omitted"
done

echo "PASS: canonical empty master-map policy verified"
echo "PASS: demonstration maps absent"

echo
echo "=== VERIFY NO LIVE COLLISIONS ==="

while IFS= read -r -d '' staged_object
do
    relative="${staged_object#"$STAGE"/}"
    live_object="/$relative"

    if test -e "$live_object" || test -L "$live_object"; then
        echo "COLLISION: $live_object"
        fail "live filesystem collision detected"
    fi
done < <(
    find "$STAGE" \( -type f -o -type l \) -print0
)

for package_directory in \
    /usr/lib/autofs \
    /etc/auto.master.d
do
    test ! -e "$package_directory" ||
        fail "package-owned directory already exists: $package_directory"
done

echo "PASS: no live payload collisions detected"

echo
echo "=== RECORD ACTIVATION METADATA ==="

cat <<EOF
ACTIVATED_AT=$(date --iso-8601=seconds)
CANONICAL_HOST=$(hostname)
KERNEL_RELEASE=$(uname -r)
REPOSITORY_BRANCH=$(git -C "$REPO" branch --show-current)
REPOSITORY_COMMIT=$(git -C "$REPO" rev-parse HEAD)
BUILD_SCRIPT_SHA256=$(cut -d' ' -f1 "$ROOT/scripts/build-autofs-5.1.9.sh.sha256")
STAGE_ROOT=$STAGE
SERVICE_POLICY=temporary-runtime-test-then-disabled
EOF

echo
echo "=== INSTALL VALIDATED STAGED PAYLOAD ==="

ACTIVATION_STARTED=true

tar -C "$STAGE" -cf - . |
    tar -C / --no-same-owner -xpf -

echo "PASS: staged payload copied into live filesystem"

echo
echo "=== REFRESH RUNTIME STATE ==="

ldconfig
systemctl daemon-reload

echo "PASS: dynamic-linker cache refreshed"
echo "PASS: systemd manager reloaded"

echo
echo "=== VERIFY LIVE PAYLOAD AGAINST STAGE ==="

while IFS= read -r -d '' staged_file
do
    relative="${staged_file#"$STAGE"/}"
    live_file="/$relative"

    test -f "$live_file" ||
        fail "installed file missing: $live_file"

    staged_hash="$(sha256sum "$staged_file" | awk '{print $1}')"
    live_hash="$(sha256sum "$live_file" | awk '{print $1}')"

    test "$staged_hash" = "$live_hash" ||
        fail "installed file hash mismatch: $live_file"
done < <(find "$STAGE" -type f -print0)

while IFS= read -r -d '' staged_link
do
    relative="${staged_link#"$STAGE"/}"
    live_link="/$relative"

    test -L "$live_link" ||
        fail "installed symlink missing: $live_link"

    test "$(readlink "$staged_link")" = "$(readlink "$live_link")" ||
        fail "installed symlink target mismatch: $live_link"
done < <(find "$STAGE" -type l -print0)

echo "PASS: installed files match staged SHA256 values"
echo "PASS: installed symlinks match staged targets"

echo
echo "=== VERIFY EXECUTABLE AND LIBRARIES ==="

/usr/sbin/automount --version

ldd /usr/sbin/automount |
    tee "$ROOT/reports/live-automount-ldd.txt"

if grep -q 'not found' "$ROOT/reports/live-automount-ldd.txt"; then
    fail "live automount has unresolved dependencies"
fi

grep -q 'libtirpc\.so' "$ROOT/reports/live-automount-ldd.txt" ||
    fail "live automount does not link against libtirpc"

grep -Fq 'libautofs.so => /usr/lib/libautofs.so' \
    "$ROOT/reports/live-automount-ldd.txt" ||
    fail "live automount does not resolve /usr/lib/libautofs.so"

echo "PASS: automount executable runs"
echo "PASS: live dynamic dependencies resolve"
echo "PASS: libtirpc and libautofs linkage verified"

echo
echo "=== VERIFY SYSTEMD INSTALLATION POLICY ==="

systemctl cat autofs.service

enabled_state="$(systemctl is-enabled autofs.service 2>/dev/null || true)"

case "$enabled_state" in
    disabled)
        ;;
    *)
        fail "autofs service is unexpectedly enabled: $enabled_state"
        ;;
esac

echo "PASS: autofs.service is installed"
echo "PASS: autofs.service remains disabled"

echo
echo "=== TEMPORARY RUNTIME VALIDATION ==="

systemctl start autofs.service

systemctl is-active --quiet autofs.service ||
    fail "autofs.service did not reach active state"

systemctl status autofs.service --no-pager |
    tee "$ROOT/reports/runtime-service-status.txt"

journalctl -u autofs.service \
    --since '-2 minutes' \
    --no-pager |
    tee "$ROOT/reports/runtime-service-journal.txt"

echo "PASS: autofs.service started successfully"

echo
echo "=== RETURN SERVICE TO DISABLED, STOPPED STATE ==="

systemctl stop autofs.service

test "$(systemctl is-active autofs.service 2>/dev/null || true)" = "inactive" ||
    fail "autofs.service did not stop cleanly"

test "$(systemctl is-enabled autofs.service 2>/dev/null || true)" = "disabled" ||
    fail "autofs.service is not disabled"

echo "PASS: autofs.service stopped cleanly"
echo "PASS: autofs.service remains disabled"

echo
echo "=== FINAL LIVE VALIDATION ==="

test -x /usr/sbin/automount ||
    fail "live automount executable missing"

test -f /usr/lib/libautofs.so ||
    fail "live libautofs.so missing"

test -d /usr/lib/autofs ||
    fail "live autofs module directory missing"

test -f /etc/autofs.conf ||
    fail "live autofs.conf missing"

test -f /etc/auto.master ||
    fail "live auto.master missing"

test -d /etc/auto.master.d ||
    fail "live auto.master.d missing"

FINAL_MASTER_ENTRIES="$(
    grep -Ev '^[[:space:]]*(#|$)' /etc/auto.master
)"

test "$FINAL_MASTER_ENTRIES" = "+dir:/etc/auto.master.d" ||
    fail "live auto.master policy changed unexpectedly"

test -z "$(git -C "$REPO" status --porcelain)" ||
    fail "repository changed during activation"

ACTIVATION_COMPLETE=true
trap - ERR INT TERM

echo
echo "=== ACTIVATION RESULT ==="
echo "PASS: autofs 5.1.9 installed on canonical Z890"
echo "PASS: installed payload matches validated staging root"
echo "PASS: automount executable and libraries validated"
echo "PASS: temporary service start succeeded"
echo "PASS: service stopped cleanly after validation"
echo "PASS: service remains disabled"
echo "PASS: canonical empty auto.master policy active"
echo "PASS: repository remains clean"
echo "REPORT=$REPORT"
echo "NEXT: document package build and activation in repository"
