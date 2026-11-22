#!/usr/bin/env bash
# SableLinux Tier 1: SquashFS xattr and OverlayFS runtime test.
set -Eeuo pipefail
export LC_ALL=C

die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
[[ $# -eq 1 ]] || die "usage: $0 <candidate-id>"

id="$1"

[[ "$id" =~ ^[0-9]{8}T[0-9]{6}Z-[0-9a-f]{7}-linux-6[.]16[.]1-(xattr-test1|asus-test1|portable-test1|wifi-recovery1|beta1-test1)$ ]] ||
    die "invalid candidate identifier"
candidate="/srv/sablelinux/kernel-builds/$id"
profile="${id##*-linux-6.16.1-}"
release="6.16.1-sable-$profile"
kernel="$candidate/artifacts/vmlinuz-$release"
# Generate a fresh SquashFS fixture for every regression run.
# No historical test artifact is used as a build input.

[[ "$(hostname)" == SableLinux ]] || die "canonical host required"
[[ "$(git -C "$repo" branch --show-current)" == development ]] ||
    die "development branch required"

# Verify candidate identity, artifacts, modules and metadata.
python3 "$repo/scripts/release/verify-kernel-candidate.py"     --candidate-id "$id" ||
    die "candidate verification failed"

recorded_release="$(
    sed -n 's/^KERNEL_RELEASE=//p'         "$candidate/metadata/compilation.env"
)"

[[ "$recorded_release" == "$release" ]] ||
    die "candidate kernel release mismatch"
[[ -r /dev/kvm && -w /dev/kvm ]] || die "KVM access unavailable"
[[ "$(cat "$candidate/BUILD_STATE")" == built ]] ||
    die "candidate not built"

for tool in qemu-system-x86_64 timeout cpio gzip sha256sum \
            readelf getfattr setfattr mksquashfs git mktemp; do
    command -v "$tool" >/dev/null || die "missing tool: $tool"
done

(
    cd "$candidate/artifacts"
    sha256sum -c "$candidate/metadata/kernel-artifacts.sha256" >/dev/null
) || die "kernel checksums failed"

[[ -x /usr/bin/busybox ]] || die "BusyBox unavailable"
if readelf -l /usr/bin/busybox | grep -q INTERP; then
    die "static BusyBox required"
fi

for applet in sh mount mkdir cat uname poweroff sync sleep; do
    /usr/bin/busybox --list | grep -qx "$applet" ||
        die "missing BusyBox applet: $applet"
done

run="$(mktemp -d /srv/sablelinux/testing/squashfs-overlay-vm-XXXXXXXX)"
root="$run/root"
fixture="$run/fixture"
image="$run/filesystem.squashfs"

mkdir -p "$fixture"

printf 'SableLinux SquashFS xattr regression\n' > "$fixture/test.txt"

setfattr -n user.sable_test \
    -v "sable-xattr-test1-pass" "$fixture/test.txt" ||
    die "cannot set fixture extended attribute"

[[ "$(getfattr --only-values -n user.sable_test "$fixture/test.txt" 2>/dev/null)" == \
    "sable-xattr-test1-pass" ]] ||
    die "fixture extended attribute verification failed"

mksquashfs "$fixture" "$image" \
    -noappend -xattrs -comp gzip -processors 2 \
    > "$run/mksquashfs.log" 2>&1 ||
    die "SquashFS generation failed; see $run/mksquashfs.log"

[[ -s "$image" ]] ||
    die "generated SquashFS image is empty"

(
    cd "$run"
    sha256sum filesystem.squashfs > filesystem.sha256
    sha256sum -c filesystem.sha256 >/dev/null
) || die "generated SquashFS checksum verification failed"

printf 'PASS: Fresh SquashFS fixture generated and verified\n'

mkdir -p "$root"/{bin,usr/bin,usr/lib,lib64,dev,proc,sys,lower,rw,merged}

cp /usr/bin/busybox "$root/bin/busybox"
cp -L /usr/bin/getfattr "$root/usr/bin/getfattr"

# Canonical Z890 dependencies, verified during Step 125.
for file in \
    /usr/lib/libattr.so.1 \
    /usr/lib/libc.so.6 \
    /lib64/ld-linux-x86-64.so.2
do
    [[ -r "$file" ]] || die "missing dependency: $file"
    cp -L "$file" "$root$file"
done

for applet in sh mount mkdir cat uname poweroff sync sleep; do
    ln -s busybox "$root/bin/$applet"
done

cat > "$root/init" <<'GUEST'
#!/bin/sh
export PATH=/bin:/usr/bin
mount -t devtmpfs devtmpfs /dev || exit 1
exec >/dev/console 2>&1

fail() {
    echo "SABLE_FS_VM_FAIL: $1"
    sync
    poweroff -f
}

echo "SABLE_FS_VM_BEGIN"

[ "$(uname -r)" = "__EXPECTED_KERNEL_RELEASE__" ] ||
    fail "unexpected guest kernel"

# Wait briefly for the VirtIO disk to appear.
tries=0
while [ ! -b /dev/vda ] && [ "$tries" -lt 20 ]; do
    sleep 1
    tries=$((tries + 1))
done

[ -b /dev/vda ] || fail "VirtIO SquashFS disk missing"

mount -t squashfs -o ro /dev/vda /lower ||
    fail "SquashFS mount failed"

echo "PASS: SquashFS mounted"

[ "$(cat /lower/test.txt)" = \
    "SableLinux SquashFS xattr regression" ] ||
    fail "SquashFS content mismatch"

echo "PASS: SquashFS content"

value="$(getfattr --only-values -n user.sable_test /lower/test.txt 2>/dev/null)" ||
    fail "SquashFS xattr unreadable"

[ "$value" = "sable-xattr-test1-pass" ] ||
    fail "SquashFS xattr mismatch"

echo "PASS: SquashFS extended attribute"

mount -t tmpfs tmpfs /rw ||
    fail "tmpfs mount failed"

mkdir -p /rw/upper /rw/work

mount -t overlay overlay \
    -o lowerdir=/lower,upperdir=/rw/upper,workdir=/rw/work \
    /merged ||
    fail "OverlayFS mount failed"

echo "PASS: OverlayFS mounted"

printf 'OverlayFS writable copy\n' > /merged/test.txt ||
    fail "OverlayFS write failed"

[ "$(cat /merged/test.txt)" = "OverlayFS writable copy" ] ||
    fail "OverlayFS content mismatch"

[ "$(cat /lower/test.txt)" = \
    "SableLinux SquashFS xattr regression" ] ||
    fail "read-only lower content changed"

echo "PASS: OverlayFS copy-up and lower-root preservation"
echo "SABLE_FS_VM_PASS"

sync
poweroff -f
GUEST

sed -i "s/__EXPECTED_KERNEL_RELEASE__/$release/" "$root/init"
chmod 0755 "$root/init"

(
    cd "$root"
    find . -print0 |
        sort -z |
        cpio --null -o --format=newc --owner=0:0 2>"$run/cpio.log" |
        gzip -n > "$run/initramfs.gz"
)

{
    printf 'CANDIDATE_ID=%s\n' "$id"
    printf 'KERNEL_RELEASE=%s\n' "$release"
    printf 'GIT_COMMIT=%s\n' "$(git -C "$repo" rev-parse HEAD)"
    printf 'CREATED_AT=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    printf 'HOST_KERNEL=%s\n' "$(uname -r)"
    qemu-system-x86_64 --version | head -n 1
    sha256sum "$kernel" "$image" "$run/initramfs.gz"
} > "$run/provenance.txt"

command=(
    qemu-system-x86_64
    -enable-kvm -cpu host -m 512 -smp 2
    -display none -monitor none -serial stdio
    -nic none -no-reboot
    -kernel "$kernel"
    -initrd "$run/initramfs.gz"
    -append "console=ttyS0,115200 rdinit=/init panic=1 loglevel=4"
    -drive "file=$image,format=raw,if=virtio,readonly=on"
)

printf '%q ' "${command[@]}" > "$run/qemu-command.txt"
printf '\n' >> "$run/qemu-command.txt"

printf 'QEMU evidence: %s\n' "$run"

set +e
timeout --kill-after=5s 90s "${command[@]}" \
    </dev/null > "$run/serial.log" 2>&1
result=$?
set -e

printf 'QEMU_EXIT_STATUS=%s\n' "$result" >> "$run/provenance.txt"

tr -d '\r' < "$run/serial.log" > "$run/serial-normalized.log"

printf '\n=== GUEST TEST RESULTS ===\n'
grep -E 'SABLE_FS_VM_|^PASS:' "$run/serial-normalized.log" || true

[[ "$result" -eq 0 ]] ||
    die "QEMU exit status $result; evidence: $run"

! grep -q 'SABLE_FS_VM_FAIL' "$run/serial-normalized.log" ||
    die "guest reported failure; evidence: $run"

grep -qx 'SABLE_FS_VM_PASS' "$run/serial-normalized.log" ||
    die "guest success marker missing; evidence: $run"

printf '\nSABLE FILESYSTEM VM PASS\n'
printf 'Evidence: %s\n' "$run"
