#!/usr/bin/env bash
set -euo pipefail

PACKAGE="rpcsvc-proto"
VERSION="1.4.4"

REPO="${SABLELINUX_REPO:-$HOME/sablelinux}"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

BUILD_ROOT="/srv/sablelinux/package-builds/$PACKAGE/$VERSION"
STAGE_DIR="$BUILD_ROOT/stage"
BUILD_METADATA="$BUILD_ROOT/build-metadata.env"
HASH_MANIFEST="$BUILD_ROOT/staged-files.sha256"

ACTIVATION_ROOT="$BUILD_ROOT/activation"
BACKUP_TREE="$ACTIVATION_ROOT/backup/root"
COLLISION_MANIFEST="$ACTIVATION_ROOT/preexisting-paths.txt"
INSTALLED_MANIFEST="$ACTIVATION_ROOT/installed-paths.txt"
ACTIVE_HASHES="$ACTIVATION_ROOT/active-files.sha256"
ACTIVATION_METADATA="$ACTIVATION_ROOT/activation-metadata.env"

usage() {
    cat <<USAGE
Usage:
  $0 --preflight
  $0 --activate
  $0 --validate
USAGE
}

list_payload_paths() {
    find "$STAGE_DIR" \
        \( -type f -o -type l \) \
        -printf '%p\n' |
        LC_ALL=C sort
}

list_collisions() {
    local staged
    local destination

    while IFS= read -r staged; do
        destination="${staged#"$STAGE_DIR"}"

        if test -e "$destination" || test -L "$destination"; then
            printf '%s\n' "$destination"
        fi
    done < <(list_payload_paths)
}

verify_stage() {
    sable_require_repo "$REPO" development
    sable_require_command \
        find sort sha256sum stat install readlink cp rm mkdir \
        sudo file git

    test -f "$BUILD_METADATA" ||
        sable_die "missing build metadata"

    grep -qx 'BUILD_STATE=staged' "$BUILD_METADATA" ||
        sable_die "package is not marked staged"

    test -x "$STAGE_DIR/usr/bin/rpcgen" ||
        sable_die "staged rpcgen missing"

    for header in \
        nfs_prot.h \
        mount.h \
        bootparam_prot.h
    do
        test -f "$STAGE_DIR/usr/include/rpcsvc/$header" ||
            sable_die "staged header missing: $header"
    done

    sable_verify_no_special_files "$STAGE_DIR"
    sable_verify_stage_hashes "$STAGE_DIR" "$HASH_MANIFEST"
}

preflight() {
    local collisions

    echo "=== RPCSVC-PROTO ACTIVATION PREFLIGHT ==="

    verify_stage

    echo "PASS: staged hashes verified"
    echo "PASS: rpcgen staged"
    echo "PASS: representative RPC headers staged"
    echo "PASS: no special files staged"

    echo
    echo "=== DESTINATION COLLISIONS ==="

    collisions="$(list_collisions)"

    if test -n "$collisions"; then
        printf '%s\n' "$collisions"
        echo
        echo "Collision count: $(printf '%s\n' "$collisions" | wc -l)"
    else
        echo "None"
        echo
        echo "Collision count: 0"
    fi

    echo
    echo "=== CURRENT LIVE RPCGEN STATE ==="

    if command -v rpcgen >/dev/null 2>&1; then
        command -v rpcgen
        file "$(command -v rpcgen)"
    else
        echo "rpcgen absent"
    fi

    echo
    echo "PASS: activation preflight completed"
}

backup_collisions() {
    local destination

    rm -rf -- "$ACTIVATION_ROOT"
    install -d -m 0755 "$BACKUP_TREE"
    : > "$COLLISION_MANIFEST"

    while IFS= read -r destination; do
        test -n "$destination" || continue

        printf '%s\n' "$destination" >> "$COLLISION_MANIFEST"

        sudo cp -a --parents \
            "$destination" \
            "$BACKUP_TREE"
    done < <(list_collisions)
}

install_payload() {
    local staged
    local destination
    local mode
    local target

    : > "$INSTALLED_MANIFEST"

    while IFS= read -r staged; do
        destination="${staged#"$STAGE_DIR"}"

        sudo install -d -m 0755 "$(dirname "$destination")"

        if test -L "$staged"; then
            target="$(readlink "$staged")"

            sudo rm -f -- "$destination"
            sudo ln -s "$target" "$destination"
        else
            mode="$(stat -c '%a' "$staged")"

            sudo install \
                -o root \
                -g root \
                -m "$mode" \
                "$staged" \
                "$destination"
        fi

        printf '%s\n' "$destination" >> "$INSTALLED_MANIFEST"
    done < <(list_payload_paths)
}

rollback_activation() {
    local destination

    echo
    echo "=== AUTOMATIC ROLLBACK ===" >&2

    if test -f "$INSTALLED_MANIFEST"; then
        tac "$INSTALLED_MANIFEST" |
        while IFS= read -r destination; do
            test -n "$destination" || continue
            sudo rm -f -- "$destination"
        done
    fi

    if test -d "$BACKUP_TREE"; then
        sudo cp -a "$BACKUP_TREE/." /
    fi

    echo "Rollback attempted; inspect the system before retrying." >&2
}

write_active_hashes() {
    local staged
    local destination

    : > "$ACTIVE_HASHES"

    while IFS= read -r staged; do
        test -f "$staged" || continue

        destination="${staged#"$STAGE_DIR"}"
        sha256sum "$destination" >> "$ACTIVE_HASHES"
    done < <(list_payload_paths)
}

validate_runtime() {
    local test_root
    local protocol
    local generated_c
    local generated_h

    echo "=== VALIDATE ACTIVE RPCSVC-PROTO ==="

    command -v rpcgen >/dev/null 2>&1 ||
        sable_die "rpcgen is not on PATH"

    test "$(command -v rpcgen)" = "/usr/bin/rpcgen" ||
        sable_die "unexpected rpcgen path"

    test -x /usr/bin/rpcgen ||
        sable_die "/usr/bin/rpcgen is not executable"

    test "$(stat -c '%U:%G' /usr/bin/rpcgen)" = "root:root" ||
        sable_die "rpcgen ownership is incorrect"

    test "$(stat -c '%a' /usr/bin/rpcgen)" = "755" ||
        sable_die "rpcgen mode is incorrect"

    for header in \
        nfs_prot.h \
        mount.h \
        bootparam_prot.h
    do
        test -f "/usr/include/rpcsvc/$header" ||
            sable_die "runtime header missing: $header"
    done

    file /usr/bin/rpcgen

    stat -c '%A %a %U:%G %s %n' \
        /usr/bin/rpcgen \
        /usr/include/rpcsvc/nfs_prot.h \
        /usr/include/rpcsvc/mount.h \
        /usr/include/rpcsvc/bootparam_prot.h

    echo
    echo "=== RPCGEN FUNCTIONAL TEST ==="

    test_root="$(mktemp -d /tmp/sable-rpcgen-test.XXXXXX)"
    protocol="$test_root/sable_test.x"
    generated_c="$test_root/sable_test_xdr.c"
    generated_h="$test_root/sable_test.h"

    cleanup_test() {
        rm -rf -- "$test_root"
    }

    trap cleanup_test RETURN

    cat > "$protocol" <<'XDR'
struct sable_rpcgen_test {
    int value;
    string label<64>;
};
XDR

    rpcgen -c -o "$generated_c" "$protocol"
    rpcgen -h -o "$generated_h" "$protocol"

    test -s "$generated_c" ||
        sable_die "rpcgen did not generate XDR source"

    test -s "$generated_h" ||
        sable_die "rpcgen did not generate protocol header"

    grep -q 'xdr_sable_rpcgen_test' "$generated_c" ||
        sable_die "generated XDR function missing"

    grep -q 'struct sable_rpcgen_test' "$generated_h" ||
        sable_die "generated structure missing"

    echo "PASS: rpcgen generated XDR C source"
    echo "PASS: rpcgen generated protocol header"

    cleanup_test
    trap - RETURN

    echo
    echo "PASS: active rpcsvc-proto runtime validated"
}

activate_package() {
    echo "=== ACTIVATE RPCSVC-PROTO $VERSION ==="

    verify_stage

    test -z "$(git -C "$REPO" status --porcelain)" ||
        sable_die "repository must be clean before activation"

    backup_collisions
    trap rollback_activation ERR

    echo
    echo "=== INSTALL STAGED PAYLOAD ==="

    install_payload
    validate_runtime
    write_active_hashes

    cat > "$ACTIVATION_METADATA" <<META
PACKAGE=$PACKAGE
VERSION=$VERSION
ACTIVATION_STATE=active
ACTIVATED_AT=$(date --iso-8601=seconds)
CANONICAL_HOST=$(hostname)
ACTIVATION_USER=$(id -un)
KERNEL_RELEASE=$(uname -r)
SABLELINUX_REPOSITORY=$REPO
SABLELINUX_GIT_BRANCH=$(git -C "$REPO" branch --show-current)
SABLELINUX_GIT_COMMIT=$(git -C "$REPO" rev-parse HEAD)
STAGE_DIR=$STAGE_DIR
STAGED_FILE_HASHES=$HASH_MANIFEST
PREEXISTING_PATHS=$COLLISION_MANIFEST
INSTALLED_PATHS=$INSTALLED_MANIFEST
ACTIVE_FILE_HASHES=$ACTIVE_HASHES
RPCGEN_PATH=$(command -v rpcgen)
RPCGEN_MODE=$(stat -c '%a' /usr/bin/rpcgen)
RPCGEN_OWNER=$(stat -c '%U:%G' /usr/bin/rpcgen)
META

    trap - ERR

    echo
    echo "=== ACTIVATION RESULT ==="
    echo "PASS: rpcsvc-proto $VERSION activated"
    echo "PASS: rpcgen functional test completed"
    echo "PASS: active runtime validated"
}

case "${1:-}" in
    --preflight)
        preflight
        ;;
    --activate)
        activate_package
        ;;
    --validate)
        validate_runtime
        ;;
    -h|--help|"")
        usage
        ;;
    *)
        sable_die "unknown argument: ${1:-}"
        ;;
esac
