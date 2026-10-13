#!/usr/bin/env bash
# Canonical staged ACL build. No downloads, host installation or cleanup.
set -euo pipefail
export LC_ALL=C
umask 022
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/common.sh"
REPO=$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)
VERSION=2.4.0
EXPECTED_SHA256=e661131456d2708a01c614a0f400e11d7d1bfaeb6f3e74b75bb980b72f0161a3
SIGNER=259B3792B3D6D319212CC4DCD5BF9FEB0313653A
SOURCE_REVIEW=
BUILD_ROOT=
MODE=
usage() {
    echo "Usage: bash $0 --stage --source-review DIR --build-dir DIR"
    echo 'Completed matching builds are verified and reused; incomplete builds are preserved and rejected.'
}
while (($#)); do
    case $1 in
        --stage) MODE=stage; shift ;;
        --source-review|--build-dir)
            (($# >= 2)) || sable_die "missing value for $1"
            if [[ $1 == --source-review ]]; then SOURCE_REVIEW=$2; else BUILD_ROOT=$2; fi
            shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) sable_die "unknown argument: $1" ;;
    esac
done
[[ $MODE == stage && -n $SOURCE_REVIEW && -n $BUILD_ROOT ]] || { usage; exit 1; }
[[ $(id -u) != 0 ]] || sable_die 'run as the canonical unprivileged build user'
[[ $(hostname) == SableLinux ]] || sable_die 'canonical SableLinux host required'
grep -qx 'ID=sablelinux' /etc/os-release || sable_die 'SableLinux required'
[[ $(cat /sys/class/dmi/id/board_name) == *Z890* ]] || sable_die 'canonical Z890 required'
sable_require_repo "$REPO" development
sable_require_command gcc make install tar sha256sum find sort file readelf pkg-config \
    gpg perl diff cmp realpath readlink awk grep tee cp touch chmod mkdir nproc xargs
SOURCE_REVIEW=$(realpath -e "$SOURCE_REVIEW")
BUILD_ROOT=$(realpath -m "$BUILD_ROOT")
[[ $SOURCE_REVIEW == /srv/sablelinux/sources/* ]] || sable_die 'source review outside canonical sources'
[[ $BUILD_ROOT == /srv/sablelinux/package-builds/acl/* ]] || sable_die 'build directory must be below package-builds/acl/'
[[ $BUILD_ROOT != /srv/sablelinux/package-builds/acl/ ]] || sable_die 'package parent is not a build directory'
ARCHIVE=$SOURCE_REVIEW/acl-$VERSION.tar.xz
SIGNATURE=$ARCHIVE.sig
KEYRING=$SOURCE_REVIEW/gnupg
sable_verify_sha256 "$ARCHIVE" "$EXPECTED_SHA256"
[[ -d $KEYRING && -f $SIGNATURE ]] || sable_die 'reviewed signature/keyring missing'

# Include source, recipe, critical compiler/test tools and discovered attr inputs
# in the resume identity. This is not a complete frozen-host release manifest.
INPUTS=$(
    printf 'PACKAGE=acl\nVERSION=%s\nCONFIGURE=--prefix=/usr --libdir=/usr/lib --disable-static --docdir=/usr/share/doc/acl-%s\n' "$VERSION" "$VERSION"
    sha256sum "$ARCHIVE" "$SIGNATURE" "${BASH_SOURCE[0]}" "$SCRIPT_DIR/common.sh"
    for tool in gcc make perl cp install stat; do
        sha256sum "$(readlink -f "$(command -v "$tool")")"
    done
    for path in /usr/lib/libc.so.6 /usr/lib/libattr.so.1 /usr/include/attr/libattr.h \
        /usr/include/attr/error_context.h; do
        [[ ! -f $path ]] || sha256sum "$path"
    done
    gcc --version
    gcc -print-search-dirs
    printf 'CFLAGS=%s\nCXXFLAGS=%s\nCPPFLAGS=%s\nLDFLAGS=%s\nLD_LIBRARY_PATH=%s\nPKG_CONFIG_PATH=%s\nPKG_CONFIG_LIBDIR=%s\nCONFIG_SITE=%s\nMAKEFLAGS=%s\n' \
        "${CFLAGS-}" "${CXXFLAGS-}" "${CPPFLAGS-}" "${LDFLAGS-}" "${LD_LIBRARY_PATH-}" \
        "${PKG_CONFIG_PATH-}" "${PKG_CONFIG_LIBDIR-}" "${CONFIG_SITE-}" "${MAKEFLAGS-}"
    printf 'USER=%s:%s\n' "$(id -u)" "$(id -g)"
)
INPUT_SHA=$(printf '%s\n' "$INPUTS" | sha256sum | awk '{print $1}')
STAGE=$BUILD_ROOT/stage
verify_stage() {
    for path in usr/bin/getfacl usr/bin/setfacl usr/bin/chacl usr/include/sys/acl.h \
        usr/include/acl/libacl.h usr/lib/pkgconfig/libacl.pc; do
        [[ -f $STAGE/$path ]] || sable_die "missing payload: $path"
    done
    [[ -L $STAGE/usr/lib/libacl.so ]] || sable_die 'linker symlink missing'
    [[ ! -e $STAGE/usr/lib/libacl.a ]] || sable_die 'unexpected static library'
    sable_verify_no_special_files "$STAGE"
    diff "$BUILD_ROOT/staged-files.manifest" <(
        cd "$STAGE"
        find . -xdev -printf '%y %m %u:%g %s %p -> %l\n' | sort
    )
    sable_verify_stage_hashes "$STAGE" "$BUILD_ROOT/staged-files.sha256"
}
if [[ -e $BUILD_ROOT ]]; then
    [[ -f $BUILD_ROOT/completed-input.sha256 ]] || sable_die 'incomplete attempt preserved; choose a new build directory'
    [[ $(cat "$BUILD_ROOT/completed-input.sha256") == "$INPUT_SHA" ]] || sable_die 'input identity changed; choose a new build directory'
    verify_stage
    echo "PASS: matching completed ACL build verified; no build-tree changes: $BUILD_ROOT"
    exit 0
fi
mkdir -p "$(dirname "$BUILD_ROOT")"
mkdir "$BUILD_ROOT"
chmod g-s "$BUILD_ROOT"
mkdir "$BUILD_ROOT/source" "$BUILD_ROOT/logs" "$STAGE"
printf '%s\n' "$INPUTS" > "$BUILD_ROOT/declared-inputs.txt"
{
    date --iso-8601=seconds
    hostname
    uname -r
    git -C "$REPO" rev-parse HEAD
    git -C "$REPO" status --short
    printf 'SOURCE_REVIEW=%s\nBUILD_ROOT=%s\nINPUT_SHA256=%s\n' "$SOURCE_REVIEW" "$BUILD_ROOT" "$INPUT_SHA"
} > "$BUILD_ROOT/build-environment.txt"
trap 'printf "Retained ACL attempt: %s\n" "$BUILD_ROOT"' EXIT
gpg --homedir "$KEYRING" --status-fd 1 --verify "$SIGNATURE" "$ARCHIVE" \
    2>&1 | tee "$BUILD_ROOT/logs/source-verification.log"
grep -q "^\[GNUPG:\] VALIDSIG $SIGNER " "$BUILD_ROOT/logs/source-verification.log" ||
    sable_die 'expected archive signer not validated'
tar -xJf "$ARCHIVE" --strip-components=1 -C "$BUILD_ROOT/source"
# The already investigated correction prevents inherited setgid test failures.
find "$BUILD_ROOT/source" -type d -exec chmod g-s {} +
(
    cd "$BUILD_ROOT/source"
    ./configure --prefix=/usr --libdir=/usr/lib --disable-static \
        --docdir=/usr/share/doc/acl-$VERSION
) 2>&1 | tee "$BUILD_ROOT/logs/configure.log"
make -C "$BUILD_ROOT/source" -j"${JOBS:-$(nproc)}" 2>&1 | tee "$BUILD_ROOT/logs/build.log"
make -C "$BUILD_ROOT/source" check 2>&1 | tee "$BUILD_ROOT/logs/check.log"
make -C "$BUILD_ROOT/source" DESTDIR="$STAGE" install 2>&1 | tee "$BUILD_ROOT/logs/stage.log"
sable_write_stage_manifests "$STAGE" "$BUILD_ROOT/staged-files.manifest" "$BUILD_ROOT/staged-files.sha256"
verify_stage
for name in getfacl setfacl chacl; do
    readelf -d "$STAGE/usr/bin/$name" > "$BUILD_ROOT/logs/$name-elf.txt"
    ! grep -Eq '\((RPATH|RUNPATH)\)' "$BUILD_ROOT/logs/$name-elf.txt" || sable_die 'unexpected embedded library path'
done
mkdir "$BUILD_ROOT/runtime-fixture"
touch "$BUILD_ROOT/runtime-fixture/file"
env LD_LIBRARY_PATH="$STAGE/usr/lib" "$STAGE/usr/bin/setfacl" \
    -m u:12345:r-- "$BUILD_ROOT/runtime-fixture/file"
env LD_LIBRARY_PATH="$STAGE/usr/lib" "$STAGE/usr/bin/getfacl" -pn \
    "$BUILD_ROOT/runtime-fixture/file" > "$BUILD_ROOT/runtime-fixture/saved.acl"
env LD_LIBRARY_PATH="$STAGE/usr/lib" "$STAGE/usr/bin/setfacl" -b "$BUILD_ROOT/runtime-fixture/file"
env LD_LIBRARY_PATH="$STAGE/usr/lib" "$STAGE/usr/bin/setfacl" \
    --restore="$BUILD_ROOT/runtime-fixture/saved.acl" --physical
env LD_LIBRARY_PATH="$STAGE/usr/lib" "$STAGE/usr/bin/getfacl" -pn \
    "$BUILD_ROOT/runtime-fixture/file" > "$BUILD_ROOT/runtime-fixture/restored.acl"
cmp "$BUILD_ROOT/runtime-fixture/saved.acl" "$BUILD_ROOT/runtime-fixture/restored.acl"
printf '%s\n' "$INPUT_SHA" > "$BUILD_ROOT/completed-input.sha256"
echo "PASS: ACL source verified, built, tested and staged: $BUILD_ROOT"
echo 'Host activation and release reproducibility remain pending.'
