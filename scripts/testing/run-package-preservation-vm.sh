#!/usr/bin/env bash
# Build inputs must come from the running canonical Z890 installation.
set -euo pipefail
export LC_ALL=C

die() { printf 'STOP: %s\n' "$*" >&2; exit 1; }
repo=$(git -C "$(dirname "$0")" rev-parse --show-toplevel)
acl=/srv/sablelinux/package-builds/acl-2.4.0-f8orRpQp
rsync_build=/srv/sablelinux/package-builds/rsync-3.5.1-YbMJUAGF
kernel=/boot/vmlinuz-6.16.1-sable-gpu-test2
config=/boot/config-6.16.1-sable-gpu-test2

[[ $(hostname) == SableLinux ]] || die 'canonical SableLinux host required'
[[ $(uname -r) == 6.16.1-sable-gpu-test2 ]] || die 'unexpected running kernel'
[[ $(git -C "$repo" branch --show-current) == development ]] || die 'development branch required'
for tool in qemu-system-x86_64 timeout mkfs.ext4 truncate cpio gzip busybox \
    ldd readelf sha256sum find sort stat cmp getfattr setfattr; do
    command -v "$tool" >/dev/null || die "missing tool: $tool"
done
[[ -r /dev/kvm && -w /dev/kvm ]] || die 'KVM access unavailable'
[[ -r $kernel && -r $config ]] || die 'kernel inputs unavailable'
cmp "$config" "$repo/docs/release-validation/gpu-test2-2026-10-08/kernel.config" ||
    die 'boot kernel config differs from documented GPU Test 2 config'
for option in BLK_DEV_INITRD RD_GZIP DEVTMPFS VIRTIO_BLK VIRTIO VIRTIO_PCI \
    SERIAL_8250 SERIAL_8250_CONSOLE EXT4_FS EXT4_FS_POSIX_ACL; do
    grep -qx "CONFIG_${option}=y" "$config" || die "required built-in option: $option"
done
[[ $(readelf -l /usr/bin/busybox) != *INTERP* ]] || die 'static BusyBox required'
for applet in sh mount mkdir cat grep sync poweroff ln touch; do
    /usr/bin/busybox --list | grep -qx "$applet" || die "BusyBox lacks $applet"
done
for package in "$acl" "$rsync_build"; do
    [[ -f $package/staged-files.sha256 ]] || die "missing package manifest: $package"
    (cd "$package/stage"; sha256sum -c "$package/staged-files.sha256")
done

run=$(mktemp -d /srv/sablelinux/package-builds/package-preservation-vm-XXXXXXXX)
chmod g-s "$run"
root=$run/initramfs-root
mkdir -p "$root"/{bin,usr/bin,usr/lib,lib64,dev,proc,sys,mnt}
trap 'printf "Retained VM run: %s\n" "$run"' EXIT
cp /usr/bin/busybox "$root/bin/busybox"
for applet in $(/usr/bin/busybox --list); do
    [[ $applet == busybox ]] && continue
    ln -s busybox "$root/bin/$applet"
done

# Copy trusted canonical ELF binaries and their actual resolved dependencies.
# The staged libacl is placed at its future installed guest path.
copy_elf() {
    local source=$1 destination=$2 dependency target
    mkdir -p "$root$(dirname "$destination")"
    cp -L "$source" "$root$destination"
    if readelf -d "$source" | grep -Eq '\((RPATH|RUNPATH)\)'; then
        die "unexpected embedded library path: $source"
    fi
    env LD_LIBRARY_PATH="$acl/stage/usr/lib" ldd "$source" > "$run/ldd-$(basename "$destination").txt"
    if grep -q 'not found' "$run/ldd-$(basename "$destination").txt"; then
        die "unresolved dependency: $source"
    fi
    while IFS= read -r dependency; do
        target=$dependency
        if [[ $dependency == "$acl/stage/usr/lib/"* ]]; then
            target=/usr/lib/$(basename "$dependency")
        fi
        mkdir -p "$root$(dirname "$target")"
        cp -L "$dependency" "$root$target"
        printf '%s -> %s\n' "$dependency" "$target" >> "$run/dependencies.txt"
    done < <(awk '$2 == "=>" && $3 ~ /^\// {print $3} $1 ~ /^\// {print $1}' \
        "$run/ldd-$(basename "$destination").txt")
}
copy_elf "$rsync_build/stage/usr/bin/rsync" /usr/bin/rsync
copy_elf "$acl/stage/usr/bin/setfacl" /usr/bin/setfacl
copy_elf "$acl/stage/usr/bin/getfacl" /usr/bin/getfacl
for tool in chmod chown stat cmp readlink getfattr setfattr; do
    copy_elf "$(command -v "$tool")" "/usr/bin/$tool"
done

cat > "$root/init" <<'GUEST'
#!/bin/sh
set -eu
export PATH=/usr/bin:/bin LC_ALL=C
mount -t devtmpfs devtmpfs /dev
exec >/dev/console 2>&1
finish() { sync; poweroff -f; }
trap 'echo SABLE_PACKAGE_VM_FAIL; finish' EXIT
mount -t proc proc /proc
mount -t sysfs sysfs /sys
echo 'SABLE_PACKAGE_VM_START'
cat /proc/sys/kernel/osrelease
rsync --version
mount -t ext4 /dev/vda /mnt
mkdir /mnt/source /mnt/destination
printf 'canonical package preservation\n' > /mnt/source/file
chmod 640 /mnt/source/file
chown 12345:23456 /mnt/source/file
ln /mnt/source/file /mnt/source/hardlink
ln -s file /mnt/source/symlink
setfacl -m u:34567:r-- /mnt/source/file
setfattr -n user.sable-test -v preserved /mnt/source/file
mkdir /mnt/source/default
setfacl -m d:u:34567:r-- /mnt/source/default
touch /mnt/source/default/child
touch /mnt/source/setuid /mnt/source/setgid
chown 12345:23456 /mnt/source/setuid /mnt/source/setgid
chmod 4750 /mnt/source/setuid
chmod 2750 /mnt/source/setgid
rsync -aHAX --numeric-ids /mnt/source/ /mnt/destination/
cmp /mnt/source/file /mnt/destination/file
test "$(stat -c '%u:%g:%a:%Y' /mnt/source/file)" = \
     "$(stat -c '%u:%g:%a:%Y' /mnt/destination/file)"
test "$(stat -c %i /mnt/destination/file)" = \
     "$(stat -c %i /mnt/destination/hardlink)"
test "$(readlink /mnt/destination/symlink)" = file
for name in file default default/child; do
    getfacl -cpn "/mnt/source/$name" > /mnt/source.acl
    getfacl -cpn "/mnt/destination/$name" > /mnt/destination.acl
    cmp /mnt/source.acl /mnt/destination.acl
done
getfattr --only-values -n user.sable-test /mnt/source/file > /mnt/source.xattr
getfattr --only-values -n user.sable-test /mnt/destination/file > /mnt/destination.xattr
cmp /mnt/source.xattr /mnt/destination.xattr
test "$(stat -c '%u:%g:%a' /mnt/destination/setuid)" = '12345:23456:4750'
test "$(stat -c '%u:%g:%a' /mnt/destination/setgid)" = '12345:23456:2750'
getfacl -pn /mnt/destination/file > /mnt/saved.acl
setfacl -b /mnt/destination/file
setfacl --restore=/mnt/saved.acl --physical
getfacl -pn /mnt/destination/file > /mnt/restored.acl
cmp /mnt/saved.acl /mnt/restored.acl
rsync -aHAX --numeric-ids --checksum --itemize-changes \
    /mnt/source/ /mnt/destination/ > /mnt/repeat-copy.txt
test ! -s /mnt/repeat-copy.txt || { cat /mnt/repeat-copy.txt; exit 1; }
echo 'PASS: foreign numeric ownership, setuid/setgid, links, ACLs, default ACLs, xattrs and repeat copy'
echo 'SABLE_PACKAGE_VM_PASS'
trap - EXIT
finish
GUEST
chmod 755 "$root/init"
cp "$kernel" "$run/kernel"
cp "$config" "$run/kernel.config"
{
    date --iso-8601=seconds
    hostname
    uname -r
    git -C "$repo" rev-parse HEAD
    git -C "$repo" status --short
    qemu-system-x86_64 --version
    sha256sum "$kernel" "$config" /usr/bin/busybox \
        "$acl/staged-files.sha256" "$rsync_build/staged-files.sha256" "$0"
} > "$run/provenance.txt"
(cd "$root"; find . -type f -print0 | sort -z | xargs -0 sha256sum) > "$run/initramfs-files.sha256"
(
    cd "$root"
    find . -print0 | sort -z | cpio --null -o --format=newc --owner=0:0 | gzip -n
) > "$run/initramfs.gz"
truncate -s 256M "$run/test-disk.raw"
mkfs.ext4 -F "$run/test-disk.raw" > "$run/mkfs.log" 2>&1
sha256sum "$run/kernel" "$run/initramfs.gz" "$run/test-disk.raw" > "$run/preboot.sha256"
command=(qemu-system-x86_64 -enable-kvm -cpu host -m 512 -smp 2 -display none -monitor none
    -serial stdio -nic none -no-reboot -kernel "$run/kernel"
    -initrd "$run/initramfs.gz" -append 'console=ttyS0,115200 earlycon=uart8250,io,0x3f8,115200 earlyprintk=serial,ttyS0,115200 rdinit=/init panic=1 loglevel=8 ignore_loglevel initcall_debug'
    -drive "file=$run/test-disk.raw,format=raw,if=virtio")
printf '%q ' "${command[@]}" > "$run/qemu-command.txt"
printf '\n' >> "$run/qemu-command.txt"
set +e
timeout --kill-after=5s 90s "${command[@]}" </dev/null 2>&1 | tee "$run/serial.log"
result=${PIPESTATUS[0]}
set -e
sha256sum "$run/test-disk.raw" > "$run/postboot-disk.sha256"
[[ $result == 0 ]] || die "QEMU exited with status $result"
tr -d '\r' < "$run/serial.log" > "$run/serial-normalized.log"
grep -qx 'SABLE_PACKAGE_VM_PASS' "$run/serial-normalized.log" || die 'guest pass marker absent'
if grep -q 'SABLE_PACKAGE_VM_FAIL' "$run/serial.log"; then die 'guest reported failure'; fi
echo 'PASS: disposable package-preservation VM; no ISO gate claimed'
