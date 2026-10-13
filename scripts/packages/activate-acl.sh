#!/usr/bin/env bash
# ACL-only addition: collisions are rejected, existing directories retained.
set -euo pipefail
export LC_ALL=C
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/common.sh"
REPO=$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)
BUILD=/srv/sablelinux/package-builds/acl/2.4.0/path-normalized-A
STAGE=$BUILD/stage
ACT=$BUILD/activation
MODE=${1:---preflight}
[[ $# -le 1 ]] || sable_die 'one mode argument required'
case $MODE in --preflight|--activate|--validate|--rollback) ;; *) sable_die 'use --preflight, --activate, --validate or --rollback' ;; esac
[[ $(hostname) == SableLinux ]] || sable_die 'canonical host required'
grep -qx 'ID=sablelinux' /etc/os-release || sable_die 'SableLinux required'
[[ $(cat /sys/class/dmi/id/board_name) == *Z890* ]] || sable_die 'canonical Z890 required'
sable_require_repo "$REPO" development
sable_require_command sha256sum find sort diff cmp stat install cp readlink ln rm rmdir \
    tac ldconfig ldd grep awk mkdir chown chmod mktemp
payload_paths() { find "$1" -xdev \( -type f -o -type l \) -printf '%P\n' | sort; }
preflight() {
    [[ -f $BUILD/completed-input.sha256 ]] || sable_die 'ACL build incomplete'
    cmp "$BUILD/staged-files.sha256" "$REPO/docs/testing/packages/acl-path-normalization-2026-10-13/A/staged-files.sha256"
    diff "$BUILD/staged-files.manifest" <(cd "$STAGE"; find . -xdev -printf '%y %m %u:%g %s %p -> %l\n' | sort)
    sable_verify_no_special_files "$STAGE"
    sable_verify_stage_hashes "$STAGE" "$BUILD/staged-files.sha256"
    local vm=$REPO/docs/testing/packages/package-recipes-vm-2026-10-13
    grep -q SABLE_PACKAGE_VM_PASS "$vm/serial.log" || sable_die 'committed VM pass missing'
    grep -F "  $BUILD/staged-files.sha256" "$vm/provenance.txt" | sha256sum -c -
    local rel destination
    while IFS= read -r rel; do
        [[ $rel == usr/* && $rel != *'..'* ]] || sable_die "unexpected payload path: $rel"
        destination=/$rel
        [[ ! -e $destination && ! -L $destination ]] || sable_die "collision: $destination"
    done < <(payload_paths "$STAGE")
    echo 'PASS: exact VM-validated ACL payload; zero destination collisions'
    echo 'Existing installation-directory ownership and modes will be retained.'
}
verify_active() {
    [[ -f $ACT/active-files.sha256 ]] || sable_die 'activation record absent'
    (cd /; sha256sum -c "$ACT/active-files.sha256")
    local rel expected actual
    while IFS= read -r rel; do
        if [[ -L $ACT/payload/$rel ]]; then
            [[ -L /$rel ]] || sable_die "installed symlink missing: /$rel"
            [[ $(readlink "/$rel") == "$(readlink "$ACT/payload/$rel")" ]] || sable_die "symlink changed: /$rel"
        else
            [[ ! -L /$rel ]] || sable_die "unexpected installed symlink: /$rel"
            [[ $(stat -c %a "/$rel") == "$(stat -c %a "$ACT/payload/$rel")" ]] || sable_die "mode changed: /$rel"
        fi
        [[ $(stat -c '%u:%g' "/$rel") == 0:0 ]] || sable_die "ownership changed: /$rel"
    done < "$ACT/installed-paths.txt"
    env -u LD_LIBRARY_PATH /usr/bin/getfacl --version
    env -u LD_LIBRARY_PATH /usr/bin/setfacl --version
    env -u LD_LIBRARY_PATH ldd /usr/bin/getfacl
}
rollback() {
    [[ -f $ACT/installed-paths.txt ]] || sable_die 'rollback inventory absent'
    if ldd /usr/bin/rsync 2>/dev/null | grep -q 'libacl.so'; then
        sable_die 'rsync now depends on libacl; roll back rsync first'
    fi
    local rel
    # Precheck every still-present path before removing any. Edited files stop recovery.
    while IFS= read -r rel; do
        [[ -e /$rel || -L /$rel ]] || continue
        if [[ -L $ACT/payload/$rel ]]; then
            [[ -L /$rel && $(readlink "/$rel") == "$(readlink "$ACT/payload/$rel")" ]] || sable_die "rollback path changed: /$rel"
        else
            [[ -f /$rel && ! -L /$rel ]] || sable_die "rollback type changed: /$rel"
            cmp "$ACT/payload/$rel" "/$rel" || sable_die "rollback content changed: /$rel"
        fi
    done < "$ACT/installed-paths.txt"
    while IFS= read -r rel; do rm -f -- "/$rel"; done < "$ACT/installed-paths.txt"
    if [[ -f $ACT/created-directories.txt ]]; then
        while IFS= read -r rel; do rmdir -- "/$rel" 2>/dev/null || true; done < <(tac "$ACT/created-directories.txt")
    fi
    ldconfig
    printf 'rolled-back\n' > "$ACT/state"
    echo 'PASS: unchanged ACL additions removed; existing payload files were never replaced'
}
if [[ $MODE == --preflight ]]; then preflight; exit 0; fi
[[ $(id -u) == 0 ]] || sable_die 'this mode requires sudo'
if [[ $MODE == --rollback ]]; then rollback; exit 0; fi
if [[ $MODE == --validate ]]; then verify_active; exit 0; fi
if [[ -f $ACT/state && $(cat "$ACT/state") == activated ]]; then
    verify_active
    echo 'PASS: already-active ACL payload verified; no reinstallation'
    exit 0
fi
[[ ! -e $ACT ]] || sable_die 'prior activation attempt preserved; inspect before another activation'
preflight
mkdir -m 0700 "$ACT"
chmod g-s "$ACT"
mkdir "$ACT/payload"
cp -a "$STAGE/." "$ACT/payload/"
(cd "$ACT/payload"; sha256sum -c "$BUILD/staged-files.sha256")
cp "$BUILD/staged-files.sha256" "$ACT/active-files.sha256"
: > "$ACT/installed-paths.txt"
: > "$ACT/created-directories.txt"
printf 'pending\n' > "$ACT/state"
{
    date --iso-8601=seconds
    git -C "$REPO" rev-parse HEAD
    sha256sum "${BASH_SOURCE[0]}" "$BUILD/staged-files.sha256"
    stat -c '%A %u:%g %n' /usr/bin /usr/lib /usr/include /usr/share
} > "$ACT/provenance.txt"
trap 'echo "Activation failed; recovery inventory retained at $ACT" >&2' ERR
while IFS= read -r rel; do
    [[ -d /$rel ]] && continue
    [[ ! -e /$rel && ! -L /$rel ]] || sable_die "directory collision: /$rel"
    mkdir -m "$(stat -c %a "$ACT/payload/$rel")" "/$rel"
    chown root:root "/$rel"
    printf '%s\n' "$rel" >> "$ACT/created-directories.txt"
done < <(find "$ACT/payload" -mindepth 1 -type d -printf '%P\n' | sort)
while IFS= read -r rel; do
    [[ ! -e /$rel && ! -L /$rel ]] || sable_die "late collision: /$rel"
    if [[ -L $ACT/payload/$rel ]]; then
        ln -s "$(readlink "$ACT/payload/$rel")" "/$rel"
        chown -h root:root "/$rel"
    else
        install -o root -g root -m "$(stat -c %a "$ACT/payload/$rel")" "$ACT/payload/$rel" "/$rel"
    fi
    printf '%s\n' "$rel" >> "$ACT/installed-paths.txt"
done < <(payload_paths "$ACT/payload")
ldconfig
verify_active | tee "$ACT/validation.log"
printf 'activated\n' > "$ACT/state"
trap - ERR
echo "PASS: ACL activated and verified; recovery records: $ACT"
