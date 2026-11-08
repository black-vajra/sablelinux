#!/usr/bin/env bash
# Disposable synthetic installed-root test; not installer acceptance.
set -euo pipefail
umask 022

die() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }

[ "$#" -eq 1 ] || die "usage: $0 /var/tmp/sable-m112-e2e-XXXXXXXX"
evidence="$1"
[[ "$evidence" =~ ^/var/tmp/sable-m112-e2e-[A-Za-z0-9]+$ ]] ||
    die "expected disposable integration evidence directory"
[ -d "$evidence" ] && [ ! -L "$evidence" ] ||
    die "invalid evidence directory"

for tool in qemu-img qemu-system-x86_64 unsquashfs mkfs.ext4 \
            timeout sha256sum awk truncate file; do
    command -v "$tool" >/dev/null || die "missing tool: $tool"
done
(exec 3<>/dev/kvm) 2>/dev/null || die "KVM inaccessible"

id="$(cat "$evidence/workspace/state/current-build-id")"
[[ "$id" =~ ^[A-Za-z0-9][A-Za-z0-9._+-]*$ ]] || die "invalid build ID"
build="$evidence/workspace/builds/$id"
[ "$(cat "$build/BUILD_STATE")" = initramfs-generated ] ||
    die "expected initramfs-generated build"

release="$(sed -n 's/^KERNEL_RELEASE=//p' "$build/metadata/build.env")"
[[ "$release" =~ ^[A-Za-z0-9][A-Za-z0-9._+-]*$ ]] ||
    die "invalid kernel release"
kernel="boot/vmlinuz-$release"
squashfs=squashfs/filesystem.squashfs
manifest="$build/metadata/live-boot-inputs.sha256"

for input in "$kernel" "$squashfs"; do
    expected="$(awk -v name="/srv/sablelinux/builds/$id/$input" '
        $2 == name { count++; digest = $1 }
        END { if (count != 1) exit 1; print digest }
    ' "$manifest")"
    [[ "$expected" =~ ^[0-9a-f]{64}$ ]] || die "invalid input hash"
    printf '%s  %s\n' "$expected" "$build/$input" | sha256sum -c -
done

run="$(mktemp -d "$evidence/installed-root-XXXXXXXX")"
printf 'Installed-root evidence: %s\n' "$run"

{
    printf 'TEST_SCOPE=synthetic-direct-installed-root\n'
    printf 'BUILD_ID=%s\nKERNEL_RELEASE=%s\n' "$id" "$release"
    printf 'METADATA_PRESERVATION_ACCEPTANCE=not-tested\n'
    git rev-parse HEAD
    sha256sum "$0" "$build/$kernel" "$build/$squashfs"
    qemu-img --version
    mkfs.ext4 -V 2>&1
} > "$run/provenance.txt"

# Unprivileged extraction for a boot-mechanics fixture only.
# This does not qualify installed ownership, capabilities or xattrs.
unsquashfs -d "$run/root" "$build/$squashfs" \
    > "$run/extraction.log" 2>&1 || {
        cat "$run/extraction.log"
        die "fixture extraction failed"
    }

root="$run/root"
[ -f "$root/usr/bin/busybox" ] &&
[ ! -L "$root/usr/bin/busybox" ] || die "fixture BusyBox missing"
file "$root/usr/bin/busybox" | grep -q 'statically linked' ||
    die "fixture BusyBox must be static"
[ -f "$root/usr/lib/systemd/systemd" ] &&
[ ! -L "$root/usr/lib/systemd/systemd" ] || die "unexpected fixture init"
[ "$(readlink "$root/sbin")" = usr/sbin ] || die "unexpected sbin layout"
[ "$(readlink "$root/usr/sbin/init")" = ../lib/systemd/systemd ] ||
    die "unexpected init link"

for dir in dev proc sys; do
    [ ! -L "$root/$dir" ] || die "symlinked fixture mountpoint: $dir"
    mkdir -p "$root/$dir"
done

cp "$root/usr/lib/systemd/systemd" "$run/original-live-probe"

cat > "$root/usr/lib/systemd/systemd" <<'INIT'
#!/bin/busybox sh
BB=/bin/busybox

fail() {
    echo SABLE_INSTALLED_ROOT_FAIL
    "$BB" sync
    exec "$BB" poweroff -f
}

# Direct kernel boot may already have mounted devtmpfs.
"$BB" mount -t proc proc /proc || fail
if "$BB" awk '
    $2 == "/dev" { found = 1 }
    END { exit !found }
' /proc/mounts; then
    "$BB" awk '
        $2 == "/dev" && $3 == "devtmpfs" { found = 1 }
        END { exit !found }
    ' /proc/mounts || fail
else
    "$BB" mount -t devtmpfs devtmpfs /dev || fail
fi
exec >/dev/console 2>&1
"$BB" mount -t sysfs sysfs /sys || fail

"$BB" awk '
    $2 == "/" && $3 == "ext4" {
        n = split($4, options, ",")
        for (i = 1; i <= n; i++)
            if (options[i] == "rw") found = 1
    }
    END { exit !found }
' /proc/mounts || fail

phase=
for arg in $("$BB" cat /proc/cmdline); do
    case "$arg" in
        sable.test.phase=*) phase="${arg#sable.test.phase=}" ;;
    esac
done

case "$phase" in
    write)
        [ ! -e /.sable-persistence-probe ] || fail
        printf '%s\n' 'sable-installed-root-persistence-v1' \
            > /.sable-persistence-probe || fail
        "$BB" sync || fail
        echo SABLE_INSTALLED_ROOT_WRITE_PASS
        ;;
    verify)
        [ -f /.sable-persistence-probe ] || fail
        [ "$("$BB" cat /.sable-persistence-probe)" = \
            sable-installed-root-persistence-v1 ] || fail
        echo SABLE_INSTALLED_ROOT_PERSISTENCE_PASS
        ;;
    *) fail ;;
esac

"$BB" sync || fail
"$BB" mount -o remount,ro / || fail
echo SABLE_INSTALLED_ROOT_SHUTDOWN_READY
exec "$BB" poweroff -f
INIT

chmod 0755 "$root/usr/lib/systemd/systemd"
sha256sum "$root/usr/lib/systemd/systemd" > "$run/probe.sha256"

# Whole-disk ext4 is deliberate here. GPT/EFI is the next test layer.
truncate -s 512M "$run/root.ext4"
mkfs.ext4 -q -F -L SABLETESTROOT -d "$root" "$run/root.ext4"
qemu-img convert -f raw -O qcow2 "$run/root.ext4" "$run/target.qcow2"
sha256sum "$run/target.qcow2" > "$run/target-before.sha256"

for phase in write verify; do
    status=0
    timeout --kill-after=5s 90s qemu-system-x86_64 \
        -machine q35 -accel kvm -m 1024 -smp 2 \
        -display none -monitor none -nic none -no-reboot \
        -serial "file:$run/$phase.serial.log" \
        -kernel "$build/$kernel" \
        -append "console=ttyS0,115200 root=/dev/vda rootfstype=ext4 rootwait rw init=/sbin/init sable.test.phase=$phase" \
        -drive "file=$run/target.qcow2,format=qcow2,if=virtio" \
        > "$run/$phase.qemu.log" 2>&1 || status=$?

    printf '%s\n' "$status" > "$run/$phase.exit-status"
    cat "$run/$phase.qemu.log"
    [ -f "$run/$phase.serial.log" ] || die "serial log missing"
    tr -d '\r' < "$run/$phase.serial.log" > "$run/$phase.serial.txt"
    tail -n 25 "$run/$phase.serial.txt"
    [ "$status" -eq 0 ] || die "$phase QEMU status: $status"

    if grep -Fxq SABLE_INSTALLED_ROOT_FAIL "$run/$phase.serial.txt"; then
        die "$phase guest reported failure"
    fi
    case "$phase" in
        write) marker=SABLE_INSTALLED_ROOT_WRITE_PASS ;;
        verify) marker=SABLE_INSTALLED_ROOT_PERSISTENCE_PASS ;;
    esac
    grep -Fxq "$marker" "$run/$phase.serial.txt" ||
        die "$phase success marker missing"
    grep -Fxq SABLE_INSTALLED_ROOT_SHUTDOWN_READY "$run/$phase.serial.txt" ||
        die "$phase clean root remount marker missing"
done

qemu-img check -f qcow2 "$run/target.qcow2" \
    > "$run/qcow2-check.log" 2>&1
cat "$run/qcow2-check.log"
sha256sum "$run/target.qcow2" > "$run/target-after.sha256"

echo SABLE_INSTALLED_ROOT_DIRECT_BOOT_PASS
