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
  cvmfs/atlas.cern.ch/payload
  var/lib/cvmfs/shared/cache-object
  etc/cvmfs/default.local
  etc/auto.cvmfs
  etc/auto.master.d/cvmfs.autofs
  etc/bash_completion.d/cvmfs
  usr/bin/cvmfs2
  usr/bin/cvmfs_config
  usr/sbin/mount.cvmfs
  sbin/mount.cvmfs
  usr/libexec/cvmfs/auto.cvmfs
  usr/lib/libcvmfs_client.so.2.13.3
  usr/lib64/libcvmfs_client.so
  lib/libcvmfs_cache.so
  lib64/libcvmfs_crypto.so
  usr/include/libcvmfs.h
  usr/share/doc/cvmfs-2.13.3/README
  usr/lib/systemd/system/cvmfs-reload.service
  etc/systemd/system/cvmfs-reload.service.d/override.conf
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
  usr/sbin/automount
  usr/lib/systemd/system/autofs.service
  usr/lib/libfuse3.so
  usr/lib/libc.so.6
  usr/lib/libstdc++.so.6
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
# Model the installed executable-map symlink without following it.
ln -sfn /usr/libexec/cvmfs/auto.cvmfs "$src/etc/auto.cvmfs"
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
# Exercise the exact service-disable block from the generator, not a copy.
mkdir -p "$src/etc/systemd/system/multi-user.target.wants" \
    "$dst/etc/systemd/system/multi-user.target.wants"
for service in autofs.service sshd.service llama-server.service; do
    for root in "$src" "$dst"; do
        ln -s "/usr/lib/systemd/system/$service" \
            "$root/etc/systemd/system/multi-user.target.wants/$service"
    done
done
python3 - "$repo/scripts/live/generate-rootfs.sh" > "$fixture/disable-services.sh" <<'PYTEST'
from pathlib import Path
import sys
text = Path(sys.argv[1]).read_text()
start = 'while IFS= read -r service; do'
end = 'done < "$DISABLED_SERVICES"'
assert text.count(start) == text.count(end) == 1
print('set -euo pipefail')
print(text[text.index(start):text.index(end) + len(end)])
PYTEST
ROOTFS="$dst" DISABLED_SERVICES="$repo/configs/live/disabled-services.list" \
    bash "$fixture/disable-services.sh"
for service in autofs.service sshd.service llama-server.service; do
    link="etc/systemd/system/multi-user.target.wants/$service"
    test ! -e "$dst/$link"
    test ! -L "$dst/$link"
    test -L "$src/$link"
done
cmp "$src/usr/lib/systemd/system/autofs.service" \
    "$dst/usr/lib/systemd/system/autofs.service"
printf 'PASS: generated service links removed; fixture source links unchanged\n'
printf 'PASS: exclusions, retained tooling/firmware, repeat copy and source preservation\n'
