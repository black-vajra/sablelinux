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

build() {
    check

    [[ $# -eq 1 ]] ||
        die "usage: build <candidate-id>"

    local candidate_id="$1"
    local root="$WORKSPACE/kernel-builds"
    local stage="$root/$candidate_id"
    local path expected_release recorded_commit

    [[ "$candidate_id" =~ ^[0-9]{8}T[0-9]{6}Z-[0-9a-f]{7}-linux-6[.]16[.]1-xattr-test1$ ]] ||
        die "invalid candidate identifier"

    [[ -d "$root" && ! -L "$root" ]] ||
        die "invalid kernel-build workspace"

    [[ -d "$stage" && ! -L "$stage" ]] ||
        die "candidate directory missing or invalid"

    [[ "$(realpath -- "$stage")" == "$stage" ]] ||
        die "candidate path resolves unexpectedly"

    for path in source obj modules artifacts metadata logs; do
        [[ -d "$stage/$path" && ! -L "$stage/$path" ]] ||
            die "candidate subdirectory missing or invalid: $path"

        [[ "$(realpath -- "$stage/$path")" == "$stage/$path" ]] ||
            die "candidate subdirectory escapes workspace: $path"
    done

    [[ -f "$stage/BUILD_STATE" ]] ||
        die "candidate state file missing"

    [[ "$(cat "$stage/BUILD_STATE")" == "prepared" ]] ||
        die "candidate is not in prepared state"

    [[ -f "$stage/metadata/build.env" ]] ||
        die "candidate provenance metadata missing"

    [[ -f "$stage/metadata/candidate-config.sha256" ]] ||
        die "candidate configuration checksum missing"

    (
        cd "$stage"
        sha256sum -c metadata/candidate-config.sha256
    ) >/dev/null ||
        die "candidate configuration checksum mismatch"

    recorded_commit="$(
        sed -n 's/^GIT_COMMIT=//p' "$stage/metadata/build.env"
    )"

    [[ "$recorded_commit" =~ ^[0-9a-f]{40}$ ]] ||
        die "invalid preparation Git revision"

    git -C "$REPO" cat-file -e "${recorded_commit}^{commit}" ||
        die "preparation Git revision is unavailable"

    expected_release="6.16.1-sable-xattr-test1"

    [[ -f "$stage/obj/.config" ]] ||
        die "candidate configuration missing"

    grep -qx 'CONFIG_LOCALVERSION="-sable-xattr-test1"' \
        "$stage/obj/.config" ||
        die "candidate local version mismatch"

    grep -qx 'CONFIG_SQUASHFS_XATTR=y' "$stage/obj/.config" ||
        die "candidate SquashFS XATTR setting missing"

    # Verify every extracted source entry against the authenticated archive.
    # This gate runs before any compilation or artifact staging.
    python3 "$REPO/scripts/kernel/verify-source.py" \
        "$SOURCE_ARCHIVE" "$stage/source" ||
        die "candidate source integrity verification failed"

    printf '\nBUILD INPUT VALIDATION PASS\n'
    printf 'Candidate: %s\n' "$candidate_id"
    printf 'Kernel:    %s\n' "$expected_release"
    printf 'Prepared:  %s\n' "$recorded_commit"
    printf 'Build HEAD: %s\n' "$(git -C "$REPO" rev-parse HEAD)"
    printf 'Jobs:      8 (planned)\n'
    printf 'Status:    validation only; compilation not started\n'
}

compile_kernel() {
    [[ $# -eq 1 ]] ||
        die "usage: compile <candidate-id>"

    local candidate_id="$1"
    local stage="$WORKSPACE/kernel-builds/$candidate_id"
    local source="$stage/source"
    local obj="$stage/obj"
    local modules="$stage/modules"
    local artifacts="$stage/artifacts"
    local metadata="$stage/metadata"
    local logs="$stage/logs"
    local release build_commit
    local -a module_files

    # Perform all read-only candidate checks before changing build state.
    build "$candidate_id"

    [[ -z "$(git -C "$REPO" status --porcelain --untracked-files=no)" ]] ||
        die "tracked repository changes must be committed before compilation"

    [[ "$(realpath -- "${BASH_SOURCE[0]}")" == \
        "$REPO/scripts/kernel/build-kernel.sh" ]] ||
        die "compilation must execute the canonical repository script"

    [[ -z "$(git -C "$REPO" diff HEAD -- scripts/kernel/build-kernel.sh)" ]] ||
        die "compilation script differs from committed revision"

    for tool in flock depmod install cp; do
        command -v "$tool" >/dev/null 2>&1 ||
            die "missing compilation tool: $tool"
    done

    [[ -f "$source/Makefile" ]] ||
        die "kernel source Makefile missing"

    [[ -f "$metadata/verified-inputs.sha256" ]] ||
        die "verified source-input manifest missing"

    sha256sum -c "$metadata/verified-inputs.sha256" >/dev/null ||
        die "prepared input manifest does not verify"

    # Reject symlink redirection anywhere in the staging ancestry.
    # All paths are expected to be absolute and already exist.
    local expected_path
    for expected_path in \
        "$WORKSPACE" \
        "$WORKSPACE/kernel-builds" \
        "$stage" \
        "$source" "$obj" "$modules" "$artifacts" "$metadata" "$logs"
    do
        [[ -d "$expected_path" && ! -L "$expected_path" ]] ||
            die "invalid candidate directory: $expected_path"
        [[ "$(realpath -e -- "$expected_path")" == "$expected_path" ]] ||
            die "candidate path resolves outside expected location: $expected_path"
    done

    [[ -z "$(find "$modules" "$artifacts" -mindepth 1 -print -quit)" ]] ||
        die "candidate staging directories must be empty"

    # Lock the existing candidate directory itself. No lock file
    # is created, and the open descriptor holds the lock until exit.
    exec {lock_fd}< "$stage"
    flock -n "$lock_fd" ||
        die "candidate compilation is already locked"

    [[ "$(cat "$stage/BUILD_STATE")" == "prepared" ]] ||
        die "candidate state changed before compilation"

    release="$(make -s -C "$source" O="$obj" kernelrelease)"
    [[ "$release" == "6.16.1-sable-xattr-test1" ]] ||
        die "unexpected kernel release: $release"

    build_commit="$(git -C "$REPO" rev-parse HEAD)"

    # Preserve distinct terminal states for failures and interruptions.
    trap 'exit 130' INT
    trap 'exit 143' TERM
    trap 'exit 129' HUP
    trap 'rc=$?; if (( rc != 0 )); then
        case "$rc" in
            129|130|143)
                printf "build-interrupted\n" > "$stage/BUILD_STATE"
                ;;
            *)
                printf "build-failed\n" > "$stage/BUILD_STATE"
                ;;
        esac
    fi' EXIT

    printf 'building\n' > "$stage/BUILD_STATE"

    printf 'Compiling kernel %s with 8 jobs...\n' "$release"
    printf 'Build log: %s\n' "$logs/compile.log"

    make -C "$source" O="$obj" -j8 bzImage modules \
        > "$logs/compile.log" 2>&1 ||
        die "kernel compilation failed; see $logs/compile.log"

    [[ -s "$obj/arch/x86/boot/bzImage" ]] ||
        die "compiled kernel image missing"

    [[ -s "$obj/System.map" ]] ||
        die "compiled System.map missing"

    # Explicit staging prefix: never install modules into the host.
    make -C "$source" O="$obj" \
        INSTALL_MOD_PATH="$modules" \
        modules_install \
        > "$logs/modules-install.log" 2>&1 ||
        die "module staging failed; see $logs/modules-install.log"

    [[ -d "$modules/lib/modules/$release" ]] ||
        die "staged module directory missing"

    # A modular kernel must contain actual loadable modules.
    [[ -n "$(find "$modules/lib/modules/$release/kernel" \
        -type f -name '*.ko' -print -quit)" ]] ||
        die "no staged kernel modules found"

    # Dependency indexes must be generated inside the staging root.
    [[ -f "$modules/lib/modules/$release/modules.dep" ]] ||
        die "missing staged dependency index: modules.dep"

    [[ -s "$modules/lib/modules/$release/modules.dep.bin" ]] ||
        die "missing or empty staged dependency index: modules.dep.bin"

    cp -- "$obj/arch/x86/boot/bzImage" \
        "$artifacts/vmlinuz-$release"

    cp -- "$obj/System.map" \
        "$artifacts/System.map-$release"

    cp -- "$obj/.config" \
        "$artifacts/config-$release"

    (
        cd "$artifacts"
        sha256sum -- * > "$metadata/kernel-artifacts.sha256"
    )

    (
        cd "$modules"
        find lib/modules -type f -print0 |
            sort -z |
            xargs -0 -r sha256sum \
            > "$metadata/kernel-modules.sha256"
    )

    [[ -s "$metadata/kernel-modules.sha256" ]] ||
        die "kernel module checksum manifest is empty"

    (
        cd "$modules"
        sha256sum -c "$metadata/kernel-modules.sha256" >/dev/null
    ) || die "staged module checksum verification failed"

    (
        cd "$artifacts"
        sha256sum -c "$metadata/kernel-artifacts.sha256" >/dev/null
    ) || die "kernel artifact checksum verification failed"

    cat > "$metadata/compilation.env" <<METADATA
KERNEL_RELEASE=$release
BUILD_GIT_COMMIT=$build_commit
BUILD_JOBS=8
COMPILER=$(gcc --version | head -n 1)
LINKER=$(ld --version | head -n 1)
BUILD_COMPLETED_AT=$(date -u +%Y-%m-%dT%H:%M:%SZ)
METADATA

    printf 'built\n' > "$stage/BUILD_STATE"
    trap - EXIT INT TERM HUP

    printf '\nKERNEL BUILD PASS\n'
    printf 'Candidate: %s\n' "$candidate_id"
    printf 'Kernel:    %s\n' "$release"
    printf 'State:     built\n'
}

case "$COMMAND" in
    check)
        check
        ;;
    prepare)
        prepare
        ;;
    build)
        build "${@:2}"
        ;;
    compile)
        compile_kernel "${@:2}"
        ;;
    *)
        printf 'Usage: %s {check|prepare|build <candidate-id>|compile <candidate-id>}\n' "$0" >&2
        exit 2
        ;;
esac
