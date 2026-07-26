#!/usr/bin/env bash

sable_die() {
    echo "STOP: $*" >&2
    exit 1
}

sable_require_command() {
    local command_name

    for command_name in "$@"; do
        command -v "$command_name" >/dev/null 2>&1 ||
            sable_die "missing required command: $command_name"
    done
}

sable_require_repo() {
    local repository="$1"
    local required_branch="${2:-}"

    test -d "$repository/.git" ||
        sable_die "missing repository: $repository"

    if test -n "$required_branch"; then
        test "$(git -C "$repository" branch --show-current)" = "$required_branch" ||
            sable_die "repository is not on branch $required_branch"
    fi
}

sable_verify_sha256() {
    local file="$1"
    local expected="$2"
    local actual

    test -f "$file" ||
        sable_die "missing file: $file"

    actual="$(sha256sum "$file" | awk '{print $1}')"

    if test "$actual" != "$expected"; then
        echo "Expected: $expected" >&2
        echo "Actual:   $actual" >&2
        sable_die "SHA256 mismatch: $file"
    fi
}

sable_reset_directory() {
    local directory="$1"

    rm -rf -- "$directory"
    install -d -m 0755 "$directory"
}

sable_normalize_stage_ownership() {
    local stage="$1"

    sudo chown -R "$(id -u):$(id -g)" "$stage"
}

sable_remove_runtime_device() {
    local stage="$1"
    local runtime_path="$2"
    local staged_path="$stage$runtime_path"

    rm -f -- "$staged_path"

    while test "$(dirname "$staged_path")" != "$stage"; do
        staged_path="$(dirname "$staged_path")"
        rmdir "$staged_path" 2>/dev/null || break
    done
}

sable_remove_staged_path() {
    local stage="$1"
    local relative_path="$2"
    local staged_path="$stage$relative_path"

    rm -rf -- "$staged_path"

    staged_path="$(dirname "$staged_path")"

    while test "$staged_path" != "$stage"; do
        rmdir "$staged_path" 2>/dev/null || break
        staged_path="$(dirname "$staged_path")"
    done
}

sable_list_special_files() {
    local stage="$1"

    find "$stage" -xdev \
        \( -type b -o -type c -o -type p -o -type s \) \
        -printf '%y %m %u:%g %p\n'
}

sable_verify_no_special_files() {
    local stage="$1"
    local output

    output="$(sable_list_special_files "$stage")"

    if test -n "$output"; then
        echo "$output" >&2
        sable_die "staged artifact contains special files"
    fi
}

sable_verify_absent() {
    local path="$1"

    test ! -e "$path" && test ! -L "$path" ||
        sable_die "forbidden staged path exists: $path"
}

sable_write_stage_manifests() {
    local stage="$1"
    local file_manifest="$2"
    local hash_manifest="$3"

    (
        cd "$stage"

        find . -xdev \
            -printf '%y %m %u:%g %s %p -> %l\n' |
            LC_ALL=C sort
    ) > "$file_manifest"

    (
        cd "$stage"

        find . -xdev -type f -print0 |
            LC_ALL=C sort -z |
            xargs -0 sha256sum
    ) > "$hash_manifest"
}

sable_verify_stage_hashes() {
    local stage="$1"
    local hash_manifest="$2"

    (
        cd "$stage"
        sha256sum -c "$hash_manifest"
    )
}

sable_count_collisions() {
    local stage="$1"
    local staged_path
    local destination
    local count=0

    while IFS= read -r staged_path; do
        destination="${staged_path#"$stage"}"

        if test -e "$destination" || test -L "$destination"; then
            printf '%s\n' "$destination"
            count=$((count + 1))
        fi
    done < <(
        find "$stage" \
            \( -type f -o -type l \) |
            LC_ALL=C sort
    )

    printf '%s\n' "$count"
}
