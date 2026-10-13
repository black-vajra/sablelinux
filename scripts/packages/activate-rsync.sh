#!/usr/bin/env bash
# Replace only the five reviewed rsync files; retain originals and recovery state.
set -euo pipefail
export LC_ALL=C
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/common.sh"
REPO=$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)
BUILD=/srv/sablelinux/package-builds/rsync/3.5.1/A
STAGE=$BUILD/stage
ACL=/srv/sablelinux/package-builds/acl/2.4.0/path-normalized-A
ACT=$BUILD/activation
ROOT=/
MODE=${1:---preflight}
[[ $# -le 1 ]] || sable_die 'one mode argument required'
case $MODE in --preflight|--exercise|--activate|--validate|--rollback) ;; *) sable_die 'use --preflight, --exercise, --activate, --validate or --rollback' ;; esac
[[ $(hostname) == SableLinux ]] || sable_die 'canonical host required'
grep -qx 'ID=sablelinux' /etc/os-release || sable_die 'SableLinux required'
[[ $(cat /sys/class/dmi/id/board_name) == *Z890* ]] || sable_die 'canonical Z890 required'
sable_require_repo "$REPO" development
sable_require_command sha256sum find sort diff cmp stat install cp readlink mv \
    grep awk mkdir chmod mktemp ldd getfacl setfacl getfattr
paths=(usr/bin/rsync usr/bin/rsync-ssl usr/share/man/man1/rsync-ssl.1 \
    usr/share/man/man1/rsync.1 usr/share/man/man5/rsyncd.conf.5)
original_hashes() {
    cat <<'HASHES'
63d8dae610cc36cc6db2feae26587715da91972e3ba027e120ae4a0dd9576601  ./usr/bin/rsync
b25e002f448246d7271adb0d9e72281e33aa822b07afff4c96c476d79fe1fc80  ./usr/bin/rsync-ssl
1eeb598a93516fb0e75145ca1a6877a3544538aee41d6f761d8351f4a85b96e7  ./usr/share/man/man1/rsync-ssl.1
ca2ecf8ff1655ff47ddd9e66da63b07edd43aebc7aea43fd24650aa0b420a9f7  ./usr/share/man/man1/rsync.1
632b8ac13e2b08782cf60b5d59affdbd49a05f8c48fa757c68f5e408e00574a3  ./usr/share/man/man5/rsyncd.conf.5
HASHES
}
verify_originals() {
    local rel mode
    for rel in "${paths[@]}"; do
        [[ -f $ROOT/$rel && ! -L $ROOT/$rel ]] || sable_die "original is not regular: $rel"
        mode=644; [[ $rel == usr/bin/* ]] && mode=755
        [[ $(stat -c '%a %u:%g' "$ROOT/$rel") == "$mode 0:0" ]] || sable_die "original metadata changed: $rel"
    done
    (cd "$ROOT"; original_hashes | sha256sum -c -)
}
verify_inputs() {
    [[ -f $BUILD/completed-input.sha256 ]] || sable_die 'rsync recipe build incomplete'
    cmp "$BUILD/staged-files.sha256" "$REPO/docs/testing/packages/rsync-recipe-2026-10-13/A/staged-files.sha256"
    diff "$BUILD/staged-files.manifest" <(cd "$STAGE"; find . -xdev -printf '%y %m %u:%g %s %p -> %l\n' | sort)
    diff <(printf '%s\n' "${paths[@]}" | sort) <(find "$STAGE" -type f -printf '%P\n' | sort)
    [[ -z $(find "$STAGE" -type l -print -quit) ]] || sable_die 'unexpected staged symlink'
    sable_verify_no_special_files "$STAGE"
    sable_verify_stage_hashes "$STAGE" "$BUILD/staged-files.sha256"
    local vm=$REPO/docs/testing/packages/package-recipes-vm-2026-10-13
    grep -q SABLE_PACKAGE_VM_PASS "$vm/serial.log" || sable_die 'committed VM pass missing'
    grep -F "  $BUILD/staged-files.sha256" "$vm/provenance.txt" | sha256sum -c -
    (cd /; sha256sum -c "$ACL/staged-files.sha256")
    env -u LD_LIBRARY_PATH ldd "$STAGE/usr/bin/rsync" | grep -q 'libacl.so.1 => /' || sable_die 'installed ACL unresolved'
}
verify_active() {
    (cd "$ROOT"; sha256sum -c "$ACT/active-files.sha256")
    local rel mode
    for rel in "${paths[@]}"; do
        [[ -f $ROOT/$rel && ! -L $ROOT/$rel ]] || sable_die "active type changed: $rel"
        mode=$(stat -c %a "$ACT/payload/$rel")
        [[ $(stat -c '%a %u:%g' "$ROOT/$rel") == "$mode 0:0" ]] || sable_die "active metadata changed: $rel"
    done
    local version_output
    version_output=$(env -u LD_LIBRARY_PATH "$ROOT/usr/bin/rsync" --version)
    printf '%s\n' "$version_output"
    [[ $version_output == 'rsync  version 3.5.1 '* ]] || sable_die 'active version mismatch'
}
backup_originals() {
    [[ ! -e $ACT ]] || sable_die 'prior transaction preserved; inspect before another activation'
    mkdir -m 0700 "$ACT"
    chmod g-s "$ACT"
    mkdir "$ACT/backup" "$ACT/payload"
    cp -a "$STAGE/." "$ACT/payload/"
    cp "$BUILD/staged-files.sha256" "$ACT/active-files.sha256"
    original_hashes > "$ACT/original-files.sha256"
    local rel
    for rel in "${paths[@]}"; do
        mkdir -p "$ACT/backup/$(dirname "$rel")"
        cp -a "$ROOT/$rel" "$ACT/backup/$rel"
        getfacl -pn "$ROOT/$rel" >> "$ACT/original-acls.txt"
        stat -c '%a %u:%g %s %y %n' "$ROOT/$rel" >> "$ACT/original-metadata.txt"
    done
    getfattr --dump --match=- --absolute-names "${paths[@]/#/$ROOT/}" > "$ACT/original-xattrs.txt"
    (cd "$ACT/backup"; sha256sum -c "$ACT/original-files.sha256")
    (cd "$ACT/payload"; sha256sum -c "$ACT/active-files.sha256")
    {
        date --iso-8601=seconds
        git -C "$REPO" rev-parse HEAD
        sha256sum "${BASH_SOURCE[0]}" "$BUILD/staged-files.sha256"
        printf 'TARGET_ROOT=%s\n' "$ROOT"
    } > "$ACT/provenance.txt"
    printf 'pending\n' > "$ACT/state"
}
replace_files() {
    local rel destination temporary
    : > "$ACT/replaced-paths.txt"
    for rel in "${paths[@]}"; do
        destination=$ROOT/$rel
        temporary=$(mktemp "${destination}.sable-rsync-XXXXXXXX")
        printf '%s\n' "$temporary" >> "$ACT/temporary-paths.txt"
        install -o root -g root -m "$(stat -c %a "$ACT/payload/$rel")" "$ACT/payload/$rel" "$temporary"
        setfacl -b "$temporary"
        chmod "$(stat -c %a "$ACT/payload/$rel")" "$temporary"
        printf '%s\n' "$rel" >> "$ACT/replaced-paths.txt"
        mv -fT "$temporary" "$destination"
    done
}
rollback() {
    [[ -f $ACT/original-files.sha256 ]] || sable_die 'backup record absent'
    (cd "$ACT/backup"; sha256sum -c "$ACT/original-files.sha256")
    local rel destination temporary
    # A partly applied transaction can contain original or new bytes, but no edits.
    for rel in "${paths[@]}"; do
        [[ -f $ROOT/$rel && ! -L $ROOT/$rel ]] || sable_die "rollback type changed: $rel"
        if ! cmp -s "$ROOT/$rel" "$ACT/backup/$rel" && ! cmp -s "$ROOT/$rel" "$ACT/payload/$rel"; then
            sable_die "rollback content changed: $rel"
        fi
    done
    for rel in "${paths[@]}"; do
        destination=$ROOT/$rel
        temporary=$(mktemp "${destination}.sable-restore-XXXXXXXX")
        printf '%s\n' "$temporary" >> "$ACT/temporary-paths.txt"
        cp -a "$ACT/backup/$rel" "$temporary"
        mv -fT "$temporary" "$destination"
    done
    setfacl --restore="$ACT/original-acls.txt" --physical
    verify_originals
    : > "$ACT/restored-acls.txt"
    : > "$ACT/restored-metadata.txt"
    for rel in "${paths[@]}"; do
        getfacl -pn "$ROOT/$rel" >> "$ACT/restored-acls.txt"
        stat -c '%a %u:%g %s %y %n' "$ROOT/$rel" >> "$ACT/restored-metadata.txt"
    done
    getfattr --dump --match=- --absolute-names "${paths[@]/#/$ROOT/}" > "$ACT/restored-xattrs.txt"
    cmp "$ACT/original-acls.txt" "$ACT/restored-acls.txt"
    cmp "$ACT/original-metadata.txt" "$ACT/restored-metadata.txt"
    cmp "$ACT/original-xattrs.txt" "$ACT/restored-xattrs.txt"
    printf 'rolled-back\n' > "$ACT/state"
    echo 'PASS: original rsync files and ACL metadata restored; recovery records retained'
}
if [[ $MODE == --preflight ]]; then
    verify_inputs
    verify_originals
    echo 'PASS: exact VM-validated candidate; five original destinations match pinned hashes and metadata'
    exit 0
fi
[[ $(id -u) == 0 ]] || sable_die 'this mode requires sudo or a root shell'
if [[ $MODE == --validate ]]; then verify_active; exit 0; fi
if [[ $MODE == --rollback ]]; then rollback; exit 0; fi
if [[ $MODE == --exercise ]]; then
    verify_inputs
    verify_originals
    exercise=$(mktemp -d /srv/sablelinux/package-builds/rsync-transaction-exercise-XXXXXXXX)
    chmod 0700 "$exercise"
    chmod g-s "$exercise"
    ROOT=$exercise/root
    ACT=$exercise/transaction
    mkdir "$ROOT"
    for rel in "${paths[@]}"; do
        mkdir -p "$ROOT/$(dirname "$rel")"
        cp -a "/$rel" "$ROOT/$rel"
    done
    verify_originals
    backup_originals
    replace_files
    verify_active | tee "$ACT/active-validation.log"
    rollback | tee "$ACT/rollback-validation.log"
    echo "PASS: fixture replacement and rollback; installed host files untouched; evidence: $exercise"
    exit 0
fi
if [[ -f $ACT/state && $(cat "$ACT/state") == activated ]]; then
    verify_active
    echo 'PASS: already-active rsync verified; no reinstallation'
    exit 0
fi
verify_inputs
verify_originals
backup_originals
trap 'echo "Replacement failed; transaction preserved at $ACT; inspect before rollback" >&2' ERR
replace_files
verify_active | tee "$ACT/validation.log"
printf 'activated\n' > "$ACT/state"
trap - ERR
echo "PASS: rsync activated and verified; backup/recovery records: $ACT"
