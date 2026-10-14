#!/usr/bin/env bash
set -Eeuo pipefail
repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
rules="$repo/configs/live/rootfs-excludes.rsync"
fixture=$(mktemp -d /tmp/sable-exclusions-XXXXXXXX)
printf 'Fixture retained: %s\n' "$fixture"
trap 'printf "FAIL at line %s; fixture: %s\n" "$LINENO" "$fixture" >&2' ERR
src="$fixture/source"
dst="$fixture/destination"
mkdir -p "$src" "$dst"

absent=(
  opt/boinc/8.2.11/bin/boinc
  opt/boinc/8.2.11/lib/libboinc.so
  var/lib/boinc-client/gui_rpc_auth.cfg
  etc/boinc-client/config.properties
  etc/boinc/client.conf
  usr/local/bin/boincctl
  etc/systemd/system/boinc-client.service
  etc/systemd/system/boinc-client.service.d/override.conf
  usr/lib/systemd/system/boinc-client.service
  lib/systemd/system/boinc-client.service
  var/lib/qemu/disks/sable-install-target.qcow2
  var/lib/libvirt/images/guest.qcow2
  srv/example/guest.iso
  home/pepper/guest.vmdk
)
keep=(
  usr/bin/qemu-system-x86_64
  usr/bin/qemu-img
  usr/share/qemu/s390-ccw.img
  usr/lib/dracut/modules.d/90qemu/module-setup.sh
  usr/lib/grub/x86_64-efi/kernel.img
  opt/sablelinux/qemu/firmware/ovmf/OVMF_CODE_4M.fd
  opt/sablelinux/qemu/firmware/ovmf/OVMF_VARS_4M.template.fd
  usr/lib/libnotify.so
  usr/lib/libwx_baseu.so
)
for p in "${absent[@]}" "${keep[@]}"; do
    mkdir -p "$(dirname "$src/$p")"
    printf 'fixture payload: %s\n' "$p" >"$src/$p"
done
mkdir -p "$src/etc/systemd/system/multi-user.target.wants"
link=etc/systemd/system/multi-user.target.wants/boinc-client.service
ln -s ../boinc-client.service "$src/$link"
absent+=("$link")
chmod 755 "$src/usr/bin/qemu-system-x86_64" "$src/usr/bin/qemu-img"

# Control copy establishes that all unwanted fixture payloads exist.
rsync -a "$src/" "$fixture/control/"
for p in "${absent[@]}"; do
    [[ -e "$fixture/control/$p" || -L "$fixture/control/$p" ]]
done

rsync -a --exclude-from="$rules" "$src/" "$dst/"
for p in "${absent[@]}"; do
    if [[ -e "$dst/$p" || -L "$dst/$p" ]]; then
        printf 'Unexpected included payload: %s\n' "$p" >&2
        exit 1
    fi
done
for p in "${keep[@]}"; do
    cmp "$src/$p" "$dst/$p"
done
test -x "$dst/usr/bin/qemu-system-x86_64"
test -x "$dst/usr/bin/qemu-img"

rsync -ai --exclude-from="$rules" "$src/" "$dst/" >"$fixture/repeat.txt"
test ! -s "$fixture/repeat.txt"
diff -r --no-dereference "$src" "$fixture/control"
printf 'PASS: exclusions, retained tooling/firmware, repeat copy and source preservation\n'
