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
        sha256sum tar xz git realpath; do
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

prepare() {
    check

    [[ -z "$(git -C "$REPO" status --porcelain --untracked-files=no)" ]] ||
        die "tracked repository changes must be committed before preparation"

    # Authoritative preparation must execute the repository script.
    local expected_script="$REPO/scripts/kernel/build-kernel.sh"
    local actual_script

    actual_script="$(realpath -- "${BASH_SOURCE[0]}")"

    [[ "$actual_script" == "$expected_script" ]] ||
        die "prepare must run the canonical repository script"

    # Require the executable to match its committed Git revision.
    git -C "$REPO" diff --quiet HEAD -- scripts/kernel/build-kernel.sh ||
        die "kernel-build script differs from committed version"

    local root="$WORKSPACE/kernel-builds"
    local timestamp commit candidate stage
    local source_dir config_file

    [[ -d "$root" && ! -L "$root" ]] ||
        die "kernel-build workspace missing or invalid: $root"

    [[ -w "$root" ]] ||
        die "kernel-build workspace is not writable"

    timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
    commit="$(git -C "$REPO" rev-parse --short=7 HEAD)"
    candidate="${timestamp}-${commit}-linux-6.16.1-xattr-test1"
    stage="$root/$candidate"

    [[ ! -e "$stage" && ! -L "$stage" ]] ||
        die "candidate already exists: $stage"

    mkdir "$stage" ||
        die "failed to create candidate directory"

    # Preserve failed candidates for diagnosis.
    # Never modify an existing candidate directory.
    trap 'rc=$?; if (( rc != 0 )); then
        printf "failed\\n" > "$stage/BUILD_STATE"
    fi' EXIT

    trap 'exit 130' INT
    trap 'exit 143' TERM
    trap 'exit 129' HUP

    mkdir -p \
        "$stage/source" \
        "$stage/obj" \
        "$stage/modules" \
        "$stage/artifacts" \
        "$stage/metadata" \
        "$stage/logs"

    printf 'preparing\n' > "$stage/BUILD_STATE"

    printf 'Extracting authenticated source...\n'

    if ! tar -xJf "$SOURCE_ARCHIVE" \
        -C "$stage/source" \
        --strip-components=1; then
        printf 'failed\n' > "$stage/BUILD_STATE"
        die "source extraction failed; candidate retained: $stage"
    fi

    source_dir="$stage/source"
    config_file="$stage/obj/.config"

    [[ -f "$source_dir/Makefile" ]] ||
        die "extracted kernel Makefile is missing"

    cp "$CONFIG" "$config_file"

    python3 - "$config_file" <<'CONFIG_PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text()

changes = (
    (
        'CONFIG_LOCALVERSION="-sable-gpu-test2"',
        'CONFIG_LOCALVERSION="-sable-xattr-test1"',
    ),
    (
        '# CONFIG_SQUASHFS_XATTR is not set',
        'CONFIG_SQUASHFS_XATTR=y',
    ),
)

for old, new in changes:
    if text.count(old) != 1:
        raise SystemExit(
            f"STOP: Expected configuration setting not unique: {old}"
        )
    text = text.replace(old, new, 1)

path.write_text(text)
CONFIG_PY

    # Resolve the candidate configuration against upstream Kconfig.
    # All generated files remain inside the isolated obj directory.
    make -C "$source_dir" O="$stage/obj" olddefconfig \
        > "$stage/logs/olddefconfig.log" 2>&1 ||
        die "candidate Kconfig validation failed; see $stage/logs/olddefconfig.log"

    grep -qx 'CONFIG_LOCALVERSION="-sable-xattr-test1"' "$config_file" ||
        die "candidate local version was not retained"

    grep -qx 'CONFIG_SQUASHFS=y' "$config_file" ||
        die "SquashFS support was not retained"

    grep -qx 'CONFIG_SQUASHFS_XATTR=y' "$config_file" ||
        die "SquashFS XATTR support was not retained"

    grep -qx '# CONFIG_LOCALVERSION_AUTO is not set' "$config_file" ||
        die "automatic local-version generation was unexpectedly enabled"

    sha256sum "$SOURCE_ARCHIVE" "$CONFIG" \
        > "$stage/metadata/verified-inputs.sha256"

    sha256sum "$config_file" \
        > "$stage/metadata/candidate-config.sha256"

    cat > "$stage/metadata/build.env" <<METADATA
CANDIDATE_ID=$candidate
CREATED_AT=$(date -u +%Y-%m-%dT%H:%M:%SZ)
CANONICAL_HOST=$(hostname)
GIT_COMMIT=$(git -C "$REPO" rev-parse HEAD)
UPSTREAM_KERNEL=6.16.1
KERNEL_LOCALVERSION=-sable-xattr-test1
SOURCE_ARCHIVE=$SOURCE_ARCHIVE
BASELINE_CONFIG=$CONFIG
CANDIDATE_CONFIG=$config_file
METADATA

    printf 'prepared\n' > "$stage/BUILD_STATE"

    printf '\nPREPARE PASS\n'
    printf 'Candidate: %s\n' "$candidate"
    printf 'Location:  %s\n' "$stage"
    printf 'State:     prepared\n'
}

case "$COMMAND" in
    check)
        check
        ;;
    prepare)
        prepare
        ;;
    *)
        printf 'Usage: %s {check|prepare}\n' "$0" >&2
        exit 2
        ;;
esac
