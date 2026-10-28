#!/usr/bin/env bash
set -Eeuo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
VERIFIER="$REPO/scripts/kernel/verify-source.py"

TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT

mkdir -p "$TMP/archive/linux-6.16.1"
mkdir -p "$TMP/extracted"

printf 'original\n' > "$TMP/archive/linux-6.16.1/test.c"
printf 'second\n' > "$TMP/archive/linux-6.16.1/other.c"

tar -cJf "$TMP/source.tar.xz" \
    -C "$TMP/archive" linux-6.16.1

cp "$TMP/archive/linux-6.16.1/"* "$TMP/extracted/"

verify() {
    python3 "$VERIFIER" \
        "$TMP/source.tar.xz" \
        "$TMP/extracted" \
        > "$TMP/result.log" 2>&1
}

verify || {
    cat "$TMP/result.log"
    exit 1
}
echo "PASS: Valid source accepted"

printf 'modified\n' > "$TMP/extracted/test.c"
if verify; then
    echo "FAIL: Modified source accepted"
    exit 1
fi
grep -Fq 'content mismatch: test.c' "$TMP/result.log"
echo "PASS: Modified source rejected"

printf 'original\n' > "$TMP/extracted/test.c"
rm "$TMP/extracted/other.c"

if verify; then
    echo "FAIL: Missing source accepted"
    exit 1
fi
grep -Fq 'missing/nonregular: other.c' "$TMP/result.log"
echo "PASS: Missing source rejected"

printf 'second\n' > "$TMP/extracted/other.c"
printf 'unexpected\n' > "$TMP/extracted/extra.c"

if verify; then
    echo "FAIL: Unexpected source accepted"
    exit 1
fi
grep -Fq 'unexpected extracted entry: extra.c' "$TMP/result.log"
echo "PASS: Unexpected source rejected"

echo "SOURCE VERIFIER REGRESSION PASS"
