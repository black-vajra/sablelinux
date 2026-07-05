#!/usr/bin/env bash
set -u

USB="${1:-}"

if [ -z "$USB" ]; then
  echo "Usage: $0 /dev/sdX"
  exit 2
fi

if [ ! -b "$USB" ]; then
  echo "ERROR: $USB is not a block device."
  exit 2
fi

BASE="$(basename "$USB")"

if [ ! -r "/sys/block/$BASE/removable" ]; then
  echo "ERROR: cannot verify removability for $USB."
  exit 2
fi

if [ "$(cat "/sys/block/$BASE/removable")" != "1" ]; then
  echo "ERROR: $USB is not removable. Refusing to inspect as USB."
  exit 2
fi

cd ~/sablelinux || exit 2

mkdir -p docs/media

STAMP="$(date +%Y%m%d-%H%M%S)"
SERIAL="$(lsblk -ndo SERIAL "$USB" | tr -cd '[:alnum:]_-')"
MODEL="$(lsblk -ndo MODEL "$USB" | tr ' ' '_' | tr -cd '[:alnum:]_-')"

[ -n "$SERIAL" ] || SERIAL="unknown-serial"
[ -n "$MODEL" ] || MODEL="unknown-model"

OUT="docs/media/usb-prewipe-inventory-${MODEL}-${SERIAL}-${STAMP}.md"
MNT="/mnt/inspect-usb-readonly"

sudo mkdir -p "$MNT"

# Unmount only mountpoints under our inspection directory.
findmnt -rn -o TARGET | grep "^$MNT/" | sort -r | while read -r target; do
  sudo umount "$target" 2>/dev/null || true
done

sudo rm -rf "$MNT"
sudo mkdir -p "$MNT"

{
echo "# USB Pre-Wipe Read-Only Inventory — $MODEL — $SERIAL — $STAMP"
echo
date

echo
echo "## Device identity"
lsblk -o NAME,RM,SIZE,FSTYPE,LABEL,UUID,MODEL,SERIAL,MOUNTPOINTS "$USB"

echo
echo "## by-id links"
ls -l /dev/disk/by-id/usb-* 2>/dev/null | grep "$BASE" || true

echo
echo "## blkid"
sudo blkid "${USB}"* 2>/dev/null || true

echo
echo "## partition table"
sudo sfdisk --dump "$USB" 2>/dev/null || true

echo
echo "## Partition read-only inspection"

while read -r part; do
  [ "$part" = "$USB" ] && continue
  [ -b "$part" ] || continue

  pbase="$(basename "$part")"
  fs="$(lsblk -ndo FSTYPE "$part")"
  label="$(lsblk -ndo LABEL "$part")"

  echo
  echo "### $part"
  echo "fstype=$fs label=$label"

  sudo mkdir -p "$MNT/$pbase"

  case "$fs" in
    ext2|ext3|ext4)
      sudo mount -o ro,noload "$part" "$MNT/$pbase" 2>/dev/null || {
        echo "mount failed"
        continue
      }
      ;;
    vfat|fat|exfat|iso9660)
      sudo mount -o ro "$part" "$MNT/$pbase" 2>/dev/null || {
        echo "mount failed"
        continue
      }
      ;;
    *)
      echo "unsupported or empty filesystem for read-only mount"
      continue
      ;;
  esac

  echo
  echo "#### mount"
  findmnt "$MNT/$pbase" || true

  echo
  echo "#### top level"
  sudo find "$MNT/$pbase" -maxdepth 2 -printf '%TY-%Tm-%Td %TH:%TM %s %p\n' 2>/dev/null | sort | head -300

  echo
  echo "#### boot/config/live candidates"
  sudo find "$MNT/$pbase" -type f \( \
    -iname 'BOOTX64.EFI' -o \
    -iname 'grub.cfg' -o \
    -iname '*.cfg' -o \
    -iname 'vmlinuz*' -o \
    -iname 'initramfs*' -o \
    -iname 'initrd*' -o \
    -iname '*.squashfs' -o \
    -iname '*.iso' -o \
    -iname 'sable-install' -o \
    -iname 'sable-detect' \
  \) -printf '%TY-%Tm-%Td %TH:%TM %s %p\n' 2>/dev/null | sort

  echo
  echo "#### hashes of obvious boot/live files"
  sudo find "$MNT/$pbase" -type f \( \
    -iname 'BOOTX64.EFI' -o \
    -iname 'grub.cfg' -o \
    -iname 'vmlinuz*' -o \
    -iname 'initramfs*' -o \
    -iname 'initrd*' -o \
    -iname '*.squashfs' \
  \) -print0 2>/dev/null | sudo xargs -0 sha256sum 2>/dev/null || true

  echo
  echo "#### EFI/GRUB strings if BOOTX64.EFI exists"
  efi="$(sudo find "$MNT/$pbase" -type f -iname 'BOOTX64.EFI' 2>/dev/null | head -1)"
  if [ -n "$efi" ]; then
    sudo strings "$efi" 2>/dev/null | grep -Ei 'grub|cfg|prefix|boot|linux|initramfs|squash|live|sable' | head -200
  fi

  echo
  echo "#### squashfs summary if present"
  sq="$(sudo find "$MNT/$pbase" -type f -iname '*.squashfs' 2>/dev/null | head -1)"
  if [ -n "$sq" ] && command -v unsquashfs >/dev/null 2>&1; then
    unsquashfs -s "$sq" 2>/dev/null || true
    echo
    unsquashfs -ll "$sq" 2>/dev/null | grep -Ei 'etc/os-release|sable-install|sable-detect|waybar|sway|system-auth|system-session|99-filedesc|vmlinuz|initramfs' | head -300 || true
  fi

  sudo umount "$MNT/$pbase"
done < <(lsblk -nrpo NAME "$USB")

} | tee "$OUT"

echo
echo "=== INVENTORY WRITTEN ==="
ls -lah "$OUT"

echo
echo "=== GIT STATUS ==="
git status --short
