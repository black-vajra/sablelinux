#!/usr/bin/env bash
set -Eeuo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SOURCE_SCRIPT="$REPO/scripts/kernel/build-kernel.sh"

PASS=0
FAIL=0

report() {
    local name="$1"
    local expected="$2"
    local actual="$3"

    if [[ "$expected" == "$actual" ]]; then
        printf 'PASS: %s\n' "$name"
        ((PASS+=1))
    else
        printf 'FAIL: %s (expected %s, got %s)\n' \
            "$name" "$expected" "$actual"
        ((FAIL+=1))
    fi
}

TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT

# Preserve the script's relative repository path calculation.
mkdir -p "$TMP/repo/scripts/kernel"
cp "$SOURCE_SCRIPT" "$TMP/repo/scripts/kernel/build-kernel.sh"

SCRIPT="$TMP/repo/scripts/kernel/build-kernel.sh"

# Test copies must resolve the real repository so negative tests
# reach the specific input validation being exercised.
reset_test_script() {
    cp "$SOURCE_SCRIPT" "$SCRIPT"
    sed -i 's|^REPO=.*|REPO="/home/pepper/sablelinux"|' "$SCRIPT"
}

reset_test_script

run_expect() {
    local name="$1"
    local expected="$2"
    shift 2

    local actual=0
    "$@" > "$TMP/output" 2>&1 || actual=$?

    if [[ "$expected" == "success" ]]; then
        [[ "$actual" -eq 0 ]] &&
            report "$name" success success ||
            report "$name" success failure
    else
        [[ "$actual" -ne 0 ]] &&
            report "$name" failure failure ||
            report "$name" failure success
    fi
}

run_expect "Production preflight" success "$SOURCE_SCRIPT" check

run_expect "Invalid command" failure "$SOURCE_SCRIPT" invalid

run_expect "Missing command" failure "$SOURCE_SCRIPT"

# A nonexistent source archive must be rejected.
sed -i \
    's|SOURCE_ARCHIVE="/sources/linux-6.16.1.tar.xz"|SOURCE_ARCHIVE="/nonexistent/sable-kernel-test.tar.xz"|' \
    "$SCRIPT"

run_expect "Missing source archive" failure "$SCRIPT" check
grep -Fq 'upstream source archive missing' "$TMP/output" ||
    { echo "FAIL: Wrong missing-source rejection reason"; exit 1; }
echo "PASS: Missing-source error verified"

# Restore the test script and corrupt the expected source hash.
reset_test_script

sed -i \
    's|EXPECTED_SOURCE_SHA256="ea43491bc7ace1e414b3b2d957f8cf96e7049155123f0acce798accf8da1acba"|EXPECTED_SOURCE_SHA256="0000000000000000000000000000000000000000000000000000000000000000"|' \
    "$SCRIPT"

run_expect "Incorrect source checksum" failure "$SCRIPT" check
grep -Fq 'upstream source archive SHA256 mismatch' "$TMP/output" ||
    { echo "FAIL: Wrong checksum rejection reason"; exit 1; }
echo "PASS: Source-checksum error verified"

printf '\nResults: %d PASS, %d FAIL\n' "$PASS" "$FAIL"
[[ "$FAIL" -eq 0 ]]
