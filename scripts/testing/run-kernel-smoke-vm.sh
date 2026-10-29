#!/usr/bin/env bash
# SableLinux Tier 1: isolated kernel boot smoke test.
set -Eeuo pipefail
export LC_ALL=C

die() {
    printf 'ERROR: %s\n' "$*" >&2
    exit 1
}

[[ $# -eq 1 ]] || die "usage: $0 <candidate-id>"

candidate_id="$1"

[[ "$candidate_id" =~ ^[0-9]{8}T[0-9]{6}Z-[0-9a-f]{7}-linux-6[.]16[.]1-xattr-test1$ ]] ||
    die "invalid candidate identifier"

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
candidate="/srv/sablelinux/kernel-builds/$candidate_id"
release="6.16.1-sable-xattr-test1"
kernel="$candidate/artifacts/vmlinuz-$release"
busybox="/usr/bin/busybox"

[[ "$(hostname)" == "SableLinux" ]] ||
    die "canonical host required"

[[ "$(git -C "$repo" branch --show-current)" == development ]] ||
    die "development branch required"

[[ -r /dev/kvm && -w /dev/kvm ]] ||
    die "KVM access unavailable"

[[ -d "$candidate" && ! -L "$candidate" ]] ||
    die "candidate directory unavailable"

[[ "$(cat "$candidate/BUILD_STATE")" == built ]] ||
    die "candidate is not built"

[[ -s "$kernel" ]] ||
    die "kernel artifact unavailable"

for tool in qemu-system-x86_64 timeout cpio gzip sha256sum \
    readelf git mktemp; do
    command -v "$tool" >/dev/null ||
        die "missing tool: $tool"
done

[[ -x "$busybox" ]] || die "BusyBox unavailable"

if readelf -l "$busybox" | grep -q INTERP; then
    die "BusyBox must be statically linked"
fi

for applet in sh mount poweroff sync mkdir; do
    "$busybox" --list | grep -qx "$applet" ||
        die "BusyBox lacks required applet: $applet"
done

(
    cd "$candidate/artifacts"
    sha256sum -c "$candidate/metadata/kernel-artifacts.sha256" >/dev/null
) || die "kernel artifact checksum mismatch"

runroot="/srv/sablelinux/testing"
mkdir -p "$runroot"

run="$(mktemp -d "$runroot/kernel-smoke-XXXXXXXX")"
root="$run/root"

mkdir -p "$root/bin" "$root/dev" "$root/proc" "$root/sys"
cp "$busybox" "$root/bin/busybox"
ln -s busybox "$root/bin/sh"

cat > "$root/init" <<'GUEST'
#!/bin/sh
export PATH=/bin
mount -t devtmpfs devtmpfs /dev || exit 1
exec >/dev/console 2>&1

echo "SABLE_KERNEL_VM_BEGIN"
echo "Guest kernel: $(uname -r)"

if [ "$(uname -r)" != "6.16.1-sable-xattr-test1" ]; then
    echo "SABLE_KERNEL_VM_FAIL"
    poweroff -f
fi

echo "SABLE_KERNEL_VM_PASS"
sync
poweroff -f
GUEST

chmod 0755 "$root/init"
ln -s busybox "$root/bin/mount"
ln -s busybox "$root/bin/poweroff"
ln -s busybox "$root/bin/sync"
ln -s busybox "$root/bin/mkdir"
ln -s busybox "$root/bin/uname"

(
    cd "$root"
    find . -print0 |
        sort -z |
        cpio --null -o --format=newc --owner=0:0 2>"$run/cpio.log" |
        gzip -n > "$run/initramfs.gz"
)

{
    printf 'CANDIDATE_ID=%s\n' "$candidate_id"
    printf 'EXPECTED_KERNEL=%s\n' "$release"
    printf 'GIT_COMMIT=%s\n' "$(git -C "$repo" rev-parse HEAD)"
    printf 'HOST_KERNEL=%s\n' "$(uname -r)"
    printf 'CREATED_AT=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    qemu-system-x86_64 --version | head -n 1
    sha256sum "$kernel" "$busybox" "$run/initramfs.gz"
} > "$run/provenance.txt"

printf 'QEMU test directory: %s\n' "$run"

command=(
    qemu-system-x86_64
    -enable-kvm
    -cpu host
    -m 512
    -smp 2
    -display none
    -monitor none
    -serial stdio
    -nic none
    -no-reboot
    -kernel "$kernel"
    -initrd "$run/initramfs.gz"
    -append "console=ttyS0,115200 rdinit=/init panic=1 loglevel=4"
)

printf '%q ' "${command[@]}" > "$run/qemu-command.txt"
printf '\n' >> "$run/qemu-command.txt"

set +e
timeout --kill-after=5s 90s "${command[@]}" \
    </dev/null >"$run/serial.log" 2>&1
result=$?
set -e

printf 'QEMU_EXIT_STATUS=%s\n' "$result" >> "$run/provenance.txt"

tr -d '\r' < "$run/serial.log" > "$run/serial-normalized.log"

[[ "$result" -eq 0 ]] ||
    die "QEMU failed with exit status $result; logs: $run"

grep -qx "SABLE_KERNEL_VM_PASS" "$run/serial-normalized.log" ||
    die "guest success marker missing; logs: $run"

if grep -q "SABLE_KERNEL_VM_FAIL" "$run/serial-normalized.log"; then
    die "guest reported failure; logs: $run"
fi

printf '\nSABLE KERNEL SMOKE TEST PASS\n'
printf 'Kernel: %s\n' "$release"
printf 'Evidence: %s\n' "$run"
