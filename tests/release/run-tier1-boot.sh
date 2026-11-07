#!/usr/bin/env bash
# Direct kernel boot of a retained disposable integration build.
set -euo pipefail

die() {
    printf 'FAIL: %s\n' "$*" >&2
    exit 1
}

[ "$#" -eq 1 ] || die "usage: $0 /var/tmp/sable-m112-e2e-XXXXXXXX"
evidence="$1"
[[ "$evidence" =~ ^/var/tmp/sable-m112-e2e-[A-Za-z0-9]+$ ]] ||
    die "expected a disposable integration evidence directory"
[ -d "$evidence" ] && [ ! -L "$evidence" ] ||
    die "invalid evidence directory"

for tool in qemu-system-x86_64 mkfs.ext4 timeout sha256sum; do
    command -v "$tool" >/dev/null || die "missing tool: $tool"
done
(exec 3<>/dev/kvm) 2>/dev/null || die "KVM is inaccessible"

id="$(cat "$evidence/workspace/state/current-build-id")"
[[ "$id" =~ ^[A-Za-z0-9][A-Za-z0-9._+-]*$ ]] || die "invalid build ID"
build="$evidence/workspace/builds/$id"
[ "$(cat "$build/BUILD_STATE")" = initramfs-generated ] ||
    die "expected initramfs-generated build"
release="$(sed -n 's/^KERNEL_RELEASE=//p' "$build/metadata/build.env")"
[[ "$release" =~ ^[A-Za-z0-9][A-Za-z0-9._+-]*$ ]] ||
    die "invalid kernel release"

kernel="boot/vmlinuz-$release"
initramfs=initramfs/initramfs-live.img
squashfs=squashfs/filesystem.squashfs
manifest="$build/metadata/live-boot-inputs.sha256"

for input in "$kernel" "$initramfs" "$squashfs"; do
    expected="$(awk -v name="/srv/sablelinux/builds/$id/$input" '
        $2 == name { count++; digest = $1 }
        END { if (count != 1) exit 1; print digest }
    ' "$manifest")"
    [[ "$expected" =~ ^[0-9a-f]{64}$ ]] || die "invalid input hash"
    printf '%s  %s\n' "$expected" "$build/$input" | sha256sum -c -
done

run="$(mktemp -d "$evidence/tier1-XXXXXXXX")"
printf 'Tier 1 evidence: %s\n' "$run"
mkdir -p "$run/payload/live"
cp -- "$build/$squashfs" "$run/payload/live/filesystem.squashfs"
truncate -s 128M "$run/live.ext4"
mkfs.ext4 -q -F -L SABLELINUX -d "$run/payload" "$run/live.ext4"

status=0
timeout --kill-after=5s 60s qemu-system-x86_64 \
    -accel kvm -m 1024 -smp 2 -display none \
    -serial "file:$run/serial.log" -monitor none -nic none -no-reboot \
    -kernel "$build/$kernel" -initrd "$build/$initramfs" \
    -append 'console=tty0 console=ttyS0,115200 earlycon=uart8250,io,0x3f8,115200n8 sable.live.label=SABLELINUX' \
    -drive "file=$run/live.ext4,format=raw,if=virtio,readonly=on" \
    > "$run/qemu.log" 2>&1 || status=$?

printf '%s\n' "$status" > "$run/qemu-exit-status"
cat "$run/qemu.log"
[ -f "$run/serial.log" ] || die "serial log missing"
tr -d '\r' < "$run/serial.log" > "$run/serial.txt"
tail -n 20 "$run/serial.txt"
[ "$status" -eq 0 ] || die "QEMU exited with status $status"
grep -Fxq 'SABLE_TIER1_USERSPACE_PASS' "$run/serial.txt" ||
    die "userspace success marker missing"
if grep -Fxq 'SABLE_TIER1_USERSPACE_FAIL' "$run/serial.txt"; then
    die "userspace reported failure"
fi
echo "SABLE_TIER1_BOOT_PASS"
