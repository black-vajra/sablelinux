#!/usr/bin/env bash
set -Eeuo pipefail

COMMAND="${1:-}"

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WORKSPACE="/srv/sablelinux"
SOURCE_ARCHIVE="/sources/linux-6.16.1.tar.xz"
CONFIG="$REPO/docs/release-validation/gpu-test2-2026-10-08/kernel.config"

EXPECTED_SOURCE_SHA256="ea43491bc7ace1e414b3b2d957f8cf96e7049155123f0acce798accf8da1acba"
EXPECTED_CONFIG_SHA256="1271404d28cc2eb66f9cf2222c4b2f7406cff4a85f57c3ba4ced8d1d45d22fd5"

die() {
    printf 'ERROR: %s\n' "$*" >&2
    exit 1
}

check() {
    printf '%s\n' "=== SableLinux Kernel Build Preflight ==="

    [[ "$(hostname)" == "SableLinux" ]] ||
        die "canonical Z890 hostname required"

    [[ -d "$REPO/.git" ]] ||
        die "SableLinux repository missing"

    [[ "$(git -C "$REPO" branch --show-current)" == "development" ]] ||
        die "development branch required"

    [[ -f "$SOURCE_ARCHIVE" ]] ||
        die "upstream source archive missing"

    [[ -f "$CONFIG" ]] ||
        die "verified GPU Test 2 configuration missing"

    [[ "$(sha256sum "$SOURCE_ARCHIVE" | awk '{print $1}')" == \
        "$EXPECTED_SOURCE_SHA256" ]] ||
        die "upstream source archive SHA256 mismatch"

    [[ "$(sha256sum "$CONFIG" | awk '{print $1}')" == \
        "$EXPECTED_CONFIG_SHA256" ]] ||
        die "GPU Test 2 configuration SHA256 mismatch"

    [[ -f "$WORKSPACE/state/layout-version" ]] ||
        die "canonical workspace not initialized"

    [[ "$(cat "$WORKSPACE/state/layout-version")" == "1" ]] ||
        die "unsupported workspace layout"

    for tool in gcc make ld objcopy flex bison bc openssl perl python3 \
        sha256sum tar xz git; do
        command -v "$tool" >/dev/null 2>&1 ||
            die "missing build tool: $tool"
    done

    free_bytes="$(df -PB1 "$WORKSPACE" | awk 'NR == 2 {print $4}')"
    [[ "$free_bytes" =~ ^[0-9]+$ ]] ||
        die "cannot determine workspace capacity"

    (( free_bytes >= 200 * 1024 * 1024 * 1024 )) ||
        die "less than 200 GiB available"

    printf 'Source SHA256: PASS\n'
    printf 'Config SHA256: PASS\n'
    printf 'Workspace:     PASS\n'
    printf 'Build tools:   PASS\n'
    printf 'Available GiB: %s\n' "$((free_bytes / 1024 / 1024 / 1024))"
    printf 'Git commit:    %s\n' "$(git -C "$REPO" rev-parse --short HEAD)"
    printf '%s\n' "PREFLIGHT PASS"
}

case "$COMMAND" in
    check)
        check
        ;;
    *)
        printf 'Usage: %s check\n' "$0" >&2
        exit 2
        ;;
esac
