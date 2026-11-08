#!/usr/bin/env bash
# Build and verify the baseline libffi package in a separate stage.
set -euo pipefail
export LC_ALL=C
umask 022

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$script_dir/common.sh"
repo="$(git -C "$script_dir" rev-parse --show-toplevel)"
version=3.5.2
source_sha=f3a3082a23b37c293a4fcd1053147b371f2ff91fa7ea1b2a52e335676bac82dc
archive="/srv/sablelinux/sources/libffi-$version/libffi-$version.tar.gz"
flags='-O2 -march=x86-64 -mtune=generic'
configure_args=(--prefix=/usr --libdir=/usr/lib --disable-static)

[[ $# == 3 && $1 == --stage && $2 == --build-dir ]] ||
    sable_die "usage: $0 --stage --build-dir DIR"
[[ $(id -u) != 0 ]] || sable_die 'run as the unprivileged build user'
[[ $(hostname) == SableLinux ]] || sable_die 'canonical SableLinux host required'
grep -qx 'ID=sablelinux' /etc/os-release || sable_die 'SableLinux required'
[[ $(cat /sys/class/dmi/id/board_name) == *Z890* ]] ||
    sable_die 'canonical Z890 required'
sable_require_repo "$repo" development
sable_require_command gcc g++ make runtest tar sha256sum readelf realpath \
    find sort awk grep diff tee install nproc
sable_verify_sha256 "$archive" "$source_sha"

[[ ! -L $3 ]] || sable_die 'build directory must not be a symlink'
build="$(realpath -m -- "$3")"
[[ $build == /srv/sablelinux/package-builds/libffi/* ]] ||
    sable_die 'build directory must be below package-builds/libffi/'
stage="$build/stage"
library="$stage/usr/lib64/libffi.so.8.2.0"

inputs="$(
    printf 'PACKAGE=libffi\nVERSION=%s\nCFLAGS=%s\n' "$version" "$flags"
    printf 'CONFIGURE=%s\nPATH=%s\nUID_GID=%s:%s\n' \
        "${configure_args[*]}" "$PATH" "$(id -u)" "$(id -g)"
    sha256sum "$archive" "$script_dir/build-libffi.sh" "$script_dir/common.sh"
    for tool in gcc g++ as ld make runtest; do
        sha256sum "$(realpath -e "$(command -v "$tool")")"
    done
    sha256sum /usr/lib/libc.so.6
    gcc --version
    gcc -print-search-dirs
)"
input_sha="$(printf '%s\n' "$inputs" | sha256sum | awk '{print $1}')"

verify_stage() {
    [[ -f $library && ! -L $library ]] || sable_die 'staged library missing'
    [[ -L $stage/usr/lib64/libffi.so.8 &&
       $(readlink "$stage/usr/lib64/libffi.so.8") == libffi.so.8.2.0 ]] ||
        sable_die 'unexpected SONAME symlink'
    [[ -f $stage/usr/include/ffi.h && -f $stage/usr/include/ffitarget.h ]] ||
        sable_die 'staged headers missing'
    local dynamic
    dynamic="$(readelf -d "$library")"
    grep -Fq 'Library soname: [libffi.so.8]' <<< "$dynamic" ||
        sable_die 'unexpected library SONAME'
    if grep -Eq '\((RPATH|RUNPATH)\)' <<< "$dynamic"; then
        sable_die 'unexpected embedded library path'
    fi
    sable_verify_no_special_files "$stage"
    diff "$build/staged-files.manifest" <(
        cd "$stage"
        find . -xdev -printf '%y %m %u:%g %s %p -> %l\n' | sort
    )
    sable_verify_stage_hashes "$stage" "$build/staged-files.sha256"
}

if [[ -e $build ]]; then
    [[ -f $build/completed-input.sha256 ]] ||
        sable_die 'incomplete attempt preserved. Choose a new build directory.'
    [[ $(cat "$build/completed-input.sha256") == "$input_sha" ]] ||
        sable_die 'input identity changed. Choose a new build directory.'
    verify_stage
    printf 'PASS: matching completed libffi stage verified: %s\n' "$build"
    exit 0
fi

mkdir -p "$(dirname "$build")"
mkdir "$build"
chmod g-s "$build"
mkdir "$build/source" "$build/logs" "$stage"
printf '%s\n' "$inputs" > "$build/declared-inputs.txt"
{
    date --iso-8601=seconds
    hostname
    uname -r
    git -C "$repo" rev-parse HEAD
    git -C "$repo" status --short
    printf 'INPUT_SHA256=%s\n' "$input_sha"
} > "$build/provenance.txt"

tar -xzf "$archive" --strip-components=1 -C "$build/source"
build_env=(env -i "PATH=$PATH" "HOME=$HOME" LC_ALL=C TZ=UTC
    CONFIG_SITE=/dev/null CC=gcc CXX=g++ "CFLAGS=$flags" "CXXFLAGS=$flags")
(
    cd "$build/source"
    "${build_env[@]}" ./configure "${configure_args[@]}" 2>&1 |
        tee "$build/logs/configure.log"
    "${build_env[@]}" make -j"$(nproc)" 2>&1 | tee "$build/logs/build.log"
    "${build_env[@]}" make check 2>&1 | tee "$build/logs/check.log"
    grep -Eq '^# of expected passes[[:space:]]+[1-9][0-9]*' \
        "$build/logs/check.log" || sable_die 'test suite reported no passes'
    if grep -Eq '^# of (unexpected failures|unexpected successes|unresolved testcases)[[:space:]]+[1-9][0-9]*' \
        "$build/logs/check.log"; then
        sable_die 'test suite reported unexpected results'
    fi
    "${build_env[@]}" make DESTDIR="$stage" install 2>&1 |
        tee "$build/logs/stage.log"
)

sable_write_stage_manifests "$stage" \
    "$build/staged-files.manifest" "$build/staged-files.sha256"
verify_stage
printf '%s\n' "$input_sha" > "$build/completed-input.sha256"
printf 'PASS: libffi source verified, tested and staged: %s\n' "$build"
sha256sum "$library"
