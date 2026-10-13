#!/usr/bin/env bash
# Canonical staged rsync build: no downloads, host activation or deletion.
set -euo pipefail
export LC_ALL=C
umask 022
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/common.sh"
REPO=$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)
VERSION=3.5.1
EXPECTED_SHA256=c55f9c9dc10fb8bec397b399a0fdded53cc9a2d8e30891bb0d63724d25c37bef
TRIDGE=9FEF112DCE19A0DC7E882CB81BB24997A8535F6F
ZEN=8EDF88F4731A1E8B45D67FBE6909546B2C52EC2D
SOURCE_REVIEW= BUILD_ROOT= ACL_BUILD= MODE=
usage() {
    echo "Usage: bash $0 --stage --source-review DIR --acl-build DIR --build-dir DIR"
}
while (($#)); do
    case $1 in
        --stage) MODE=stage; shift ;;
        --source-review|--acl-build|--build-dir)
            (($# >= 2)) || sable_die "missing value for $1"
            case $1 in
                --source-review) SOURCE_REVIEW=$2 ;;
                --acl-build) ACL_BUILD=$2 ;;
                --build-dir) BUILD_ROOT=$2 ;;
            esac
            shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) sable_die "unknown argument: $1" ;;
    esac
done
[[ $MODE == stage && -n $SOURCE_REVIEW && -n $ACL_BUILD && -n $BUILD_ROOT ]] || { usage; exit 1; }
[[ $(id -u) != 0 ]] || sable_die 'run as the canonical unprivileged build user'
[[ $(hostname) == SableLinux ]] || sable_die 'canonical SableLinux host required'
grep -qx 'ID=sablelinux' /etc/os-release || sable_die 'SableLinux required'
[[ $(cat /sys/class/dmi/id/board_name) == *Z890* ]] || sable_die 'canonical Z890 required'
sable_require_repo "$REPO" development
sable_require_command gcc g++ make install tar sha256sum find sort readelf pkg-config \
    gpg perl python3 diff cmp realpath readlink awk grep tee cp touch chmod mkdir nproc xargs ldd
SOURCE_REVIEW=$(realpath -e "$SOURCE_REVIEW")
ACL_BUILD=$(realpath -e "$ACL_BUILD")
BUILD_ROOT=$(realpath -m "$BUILD_ROOT")
[[ $SOURCE_REVIEW == /srv/sablelinux/sources/* ]] || sable_die 'source review outside canonical sources'
[[ $ACL_BUILD == /srv/sablelinux/package-builds/acl/* ]] || sable_die 'canonical ACL recipe build required'
[[ $BUILD_ROOT == /srv/sablelinux/package-builds/rsync/* ]] || sable_die 'build directory must be below package-builds/rsync/'
[[ -f $ACL_BUILD/completed-input.sha256 ]] || sable_die 'ACL recipe build incomplete'
ACL_STAGE=$ACL_BUILD/stage
sable_verify_no_special_files "$ACL_STAGE"
diff "$ACL_BUILD/staged-files.manifest" <(
    cd "$ACL_STAGE"
    find . -xdev -printf '%y %m %u:%g %s %p -> %l\n' | sort
)
sable_verify_stage_hashes "$ACL_STAGE" "$ACL_BUILD/staged-files.sha256"
ARCHIVE=$SOURCE_REVIEW/rsync-$VERSION.tar.gz
SIGNATURE=$ARCHIVE.asc
KEYRING=$SOURCE_REVIEW/gnupg
sable_verify_sha256 "$ARCHIVE" "$EXPECTED_SHA256"
[[ -d $KEYRING && -f $SIGNATURE ]] || sable_die 'reviewed signature/keyring missing'
DEBUG_PREFIX=/usr/src/sablelinux/rsync-$VERSION
BUILD_CFLAGS=${CFLAGS:--g -O2}
BUILD_CXXFLAGS=${CXXFLAGS:--g -O2}
INPUTS=$(
    printf 'PACKAGE=rsync\nVERSION=%s\nCONFIGURE=--prefix=/usr --disable-idn\nDEBUG_PREFIX=%s\nBUILD_CFLAGS=%s\nBUILD_CXXFLAGS=%s\nACL_BUILD=%s\n' \
        "$VERSION" "$DEBUG_PREFIX" "$BUILD_CFLAGS" "$BUILD_CXXFLAGS" "$ACL_BUILD"
    sha256sum "$ARCHIVE" "$SIGNATURE" "${BASH_SOURCE[0]}" "$SCRIPT_DIR/common.sh" \
        "$ACL_BUILD/staged-files.sha256" "$ACL_BUILD/staged-files.manifest" "$ACL_BUILD/completed-input.sha256"
    for tool in gcc g++ make perl python3 install; do
        sha256sum "$(readlink -f "$(command -v "$tool")")"
    done
    for name in libc.so.6 libpopt.so.0 liblz4.so.1 libzstd.so.1 libxxhash.so.0 libcrypto.so.3; do
        [[ -f /usr/lib/$name ]] || sable_die "canonical dependency missing: $name"
        sha256sum "/usr/lib/$name"
    done
    for module in popt liblz4 libzstd libxxhash openssl; do
        printf 'PKG_CONFIG_MODULE=%s\n' "$module"
        pkg-config --modversion "$module"
    done
    gcc --version
    gcc -print-search-dirs
    printf 'CPPFLAGS=%s\nLDFLAGS=%s\nLD_LIBRARY_PATH=%s\nPKG_CONFIG_PATH=%s\nPKG_CONFIG_LIBDIR=%s\nCONFIG_SITE=%s\nMAKEFLAGS=%s\nUSER=%s:%s\n' \
        "${CPPFLAGS-}" "${LDFLAGS-}" "${LD_LIBRARY_PATH-}" "${PKG_CONFIG_PATH-}" \
        "${PKG_CONFIG_LIBDIR-}" "${CONFIG_SITE-}" "${MAKEFLAGS-}" "$(id -u)" "$(id -g)"
)
INPUT_SHA=$(printf '%s\n' "$INPUTS" | sha256sum | awk '{print $1}')
STAGE=$BUILD_ROOT/stage
verify_stage() {
    for path in usr/bin/rsync usr/bin/rsync-ssl usr/share/man/man1/rsync.1 \
        usr/share/man/man1/rsync-ssl.1 usr/share/man/man5/rsyncd.conf.5; do
        [[ -f $STAGE/$path ]] || sable_die "missing payload: $path"
    done
    sable_verify_no_special_files "$STAGE"
    diff "$BUILD_ROOT/staged-files.manifest" <(
        cd "$STAGE"
        find . -xdev -printf '%y %m %u:%g %s %p -> %l\n' | sort
    )
    sable_verify_stage_hashes "$STAGE" "$BUILD_ROOT/staged-files.sha256"
}
if [[ -e $BUILD_ROOT ]]; then
    [[ -f $BUILD_ROOT/completed-input.sha256 ]] || sable_die 'incomplete attempt preserved; choose a new directory'
    [[ $(cat "$BUILD_ROOT/completed-input.sha256") == "$INPUT_SHA" ]] || sable_die 'input identity changed; choose a new directory'
    verify_stage
    echo "PASS: matching completed rsync build verified; no build-tree changes: $BUILD_ROOT"
    exit 0
fi
mkdir -p "$(dirname "$BUILD_ROOT")"
mkdir "$BUILD_ROOT"
chmod g-s "$BUILD_ROOT"
mkdir "$BUILD_ROOT/source" "$BUILD_ROOT/logs" "$STAGE"
trap 'printf "Retained rsync attempt: %s\n" "$BUILD_ROOT"' EXIT
printf '%s\n' "$INPUTS" > "$BUILD_ROOT/declared-inputs.txt"
{
    date --iso-8601=seconds
    hostname
    uname -r
    git -C "$REPO" rev-parse HEAD
    git -C "$REPO" status --short
    printf 'SOURCE_REVIEW=%s\nACL_BUILD=%s\nBUILD_ROOT=%s\nINPUT_SHA256=%s\n' \
        "$SOURCE_REVIEW" "$ACL_BUILD" "$BUILD_ROOT" "$INPUT_SHA"
} > "$BUILD_ROOT/build-environment.txt"
gpg --homedir "$KEYRING" --status-fd 1 --verify "$SIGNATURE" "$ARCHIVE" \
    2>&1 | tee "$BUILD_ROOT/logs/source-verification.log"
for signer in "$TRIDGE" "$ZEN"; do
    grep -q "^\[GNUPG:\] VALIDSIG $signer " "$BUILD_ROOT/logs/source-verification.log" ||
        sable_die "expected signer not validated: $signer"
done
tar -xzf "$ARCHIVE" --strip-components=1 -C "$BUILD_ROOT/source"
find "$BUILD_ROOT/source" -type d -exec chmod g-s {} +
(
    export CPPFLAGS="-I$ACL_STAGE/usr/include${CPPFLAGS:+ $CPPFLAGS}"
    export LDFLAGS="-L$ACL_STAGE/usr/lib${LDFLAGS:+ $LDFLAGS}"
    export LD_LIBRARY_PATH="$ACL_STAGE/usr/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
    export PKG_CONFIG_PATH="$ACL_STAGE/usr/lib/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
    export PATH="$ACL_STAGE/usr/bin:$PATH"
    export CFLAGS="$BUILD_CFLAGS -fdebug-prefix-map=$BUILD_ROOT/source=$DEBUG_PREFIX"
    export CXXFLAGS="$BUILD_CXXFLAGS -fdebug-prefix-map=$BUILD_ROOT/source=$DEBUG_PREFIX"
    cd "$BUILD_ROOT/source"
    ./configure --prefix=/usr --disable-idn 2>&1 | tee "$BUILD_ROOT/logs/configure.log"
    make -j"${JOBS:-$(nproc)}" 2>&1 | tee "$BUILD_ROOT/logs/build.log"
    ./rsync --version | tee "$BUILD_ROOT/logs/capabilities.txt"
    grep -q 'rsync  version 3.5.1 ' "$BUILD_ROOT/logs/capabilities.txt" || sable_die 'version mismatch'
    if grep -Eq 'no ACLs|no IPv6|no xattrs' "$BUILD_ROOT/logs/capabilities.txt"; then
        sable_die 'required capability missing'
    fi
    make check 2>&1 | tee "$BUILD_ROOT/logs/check.log"
    make DESTDIR="$STAGE" install 2>&1 | tee "$BUILD_ROOT/logs/stage.log"
)
sable_write_stage_manifests "$STAGE" "$BUILD_ROOT/staged-files.manifest" "$BUILD_ROOT/staged-files.sha256"
verify_stage
readelf -d "$STAGE/usr/bin/rsync" > "$BUILD_ROOT/logs/rsync-elf.txt"
! grep -Eq '\((RPATH|RUNPATH)\)' "$BUILD_ROOT/logs/rsync-elf.txt" || sable_die 'unexpected embedded library path'
env LD_LIBRARY_PATH="$ACL_STAGE/usr/lib" ldd "$STAGE/usr/bin/rsync" > "$BUILD_ROOT/logs/rsync-ldd.txt"
! grep -q 'not found' "$BUILD_ROOT/logs/rsync-ldd.txt" || sable_die 'unresolved library'
grep -Fq "libacl.so.1 => $ACL_STAGE/usr/lib/libacl.so.1 " "$BUILD_ROOT/logs/rsync-ldd.txt" ||
    sable_die 'staged ACL library was not selected'
printf '%s\n' "$INPUT_SHA" > "$BUILD_ROOT/completed-input.sha256"
echo "PASS: rsync source verified, built, tested and staged: $BUILD_ROOT"
echo 'Host activation, exact-artifact VM validation and release reproducibility remain pending.'
