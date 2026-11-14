#!/usr/bin/env bash
set -euo pipefail

if [[ $# != 4 ]]; then
    printf 'Usage: %s KERNEL INITRAMFS SQUASHFS OUTPUT_ISO\n' "${0##*/}" >&2
    exit 2
fi

repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
kernel=$(realpath -e -- "$1")
initramfs=$(realpath -e -- "$2")
squashfs=$(realpath -e -- "$3")
output=$(realpath -m -- "$4")

for input in "$kernel" "$initramfs" "$squashfs"; do
    [[ -f "$input" && -s "$input" ]] || {
        printf 'Missing or empty input: %s\n' "$input" >&2
        exit 1
    }
done

for path in "$output" "$output.sha256"; do
    [[ ! -e "$path" && ! -L "$path" ]] || {
        printf 'Output already exists: %s\n' "$path" >&2
        exit 1
    }
done

work=$(mktemp -d "$(dirname -- "$output")/.sable-installer.XXXXXXXX")
trap 'rm -rf -- "$work"' EXIT
tree="$work/tree"
mkdir -p -- "$tree/boot/grub" "$tree/live" "$tree/install"

install -m 0644 -- "$repo/configs/live/installer-grub.cfg" "$tree/boot/grub/grub.cfg"
grub-script-check "$tree/boot/grub/grub.cfg"
install -m 0644 -- "$kernel" "$tree/boot/vmlinuz"
install -m 0644 -- "$initramfs" "$tree/boot/initramfs-live.img"
cp --reflink=auto -- "$squashfs" "$tree/live/filesystem.squashfs"

for name in sable-install-plan sable-install-replace; do
    script="$repo/scripts/install-b/$name"
    bash -n "$script"
    install -m 0755 -- "$script" "$tree/install/$name"
done

(
    cd "$tree"
    sha256sum boot/vmlinuz live/filesystem.squashfs > install/payload.sha256
)

grub-mkrescue -o "$work/installer.iso" -V SABLEASUS -iso-level 3 "$tree"
digest=$(sha256sum -- "$work/installer.iso")
printf '%s  %s\n' "${digest%% *}" "$output" > "$work/installer.sha256"
mv -- "$work/installer.iso" "$output"
mv -- "$work/installer.sha256" "$output.sha256"
sha256sum -c -- "$output.sha256"
