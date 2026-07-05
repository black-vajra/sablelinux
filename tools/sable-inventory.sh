#!/usr/bin/env bash
set -u

OUT="${1:-sable-inventory-$(hostname)-$(date +%Y%m%d-%H%M%S).txt}"

{
echo "=== SABLE INVENTORY ==="
date
hostname
whoami
uname -a

echo
echo "=== OS RELEASE ==="
cat /etc/os-release 2>/dev/null || true

echo
echo "=== KERNEL CMDLINE ==="
cat /proc/cmdline 2>/dev/null || true

echo
echo "=== FILESYSTEMS ==="
lsblk -o NAME,SIZE,FSTYPE,LABEL,UUID,MOUNTPOINTS
df -hT

echo
echo "=== MEMORY / CPU ==="
free -h
nproc
lscpu | sed -n '1,35p'

echo
echo "=== PCI DISPLAY / NETWORK / STORAGE ==="
lspci -nn 2>/dev/null | grep -Ei 'vga|3d|display|network|wireless|ethernet|nvme|sata|usb' || true

echo
echo "=== USB DEVICES ==="
lsusb 2>/dev/null || true

echo
echo "=== BOOT FILES ==="
find /boot -maxdepth 2 -type f -printf '%TY-%Tm-%Td %TH:%TM %s %p\n' 2>/dev/null | sort

echo
echo "=== FIRMWARE HIGHLIGHTS ==="
find /lib/firmware /usr/lib/firmware -maxdepth 4 -type f 2>/dev/null \
  | grep -Ei 'iwlwifi|amdgpu|radeon|intel|mediatek|realtek|ath|btusb|sof|ucode' \
  | sort \
  | head -400

echo
echo "=== PAM / LIMITS ==="
for f in /etc/pam.d/system-auth /etc/pam.d/system-session /etc/security/limits.conf /etc/security/limits.d/99-filedesc.conf; do
  echo
  echo "--- $f ---"
  sed -n '1,180p' "$f" 2>/dev/null || echo "missing"
done
echo "ulimit -n: $(ulimit -n)"

echo
echo "=== WAYLAND / WAYBAR / PIPEWIRE STATE ==="
command -v sway 2>/dev/null || true
command -v waybar 2>/dev/null || true
waybar --version 2>/dev/null || true
pgrep -a sway 2>/dev/null || true
pgrep -a waybar 2>/dev/null || true
pgrep -a pipewire 2>/dev/null || true
wpctl status 2>/dev/null | sed -n '1,160p' || true

echo
echo "=== NETWORK STATE ==="
ip -br addr 2>/dev/null || true
ip route 2>/dev/null || true
resolvectl status 2>/dev/null | sed -n '1,160p' || true
cat /etc/resolv.conf 2>/dev/null || true

echo
echo "=== SABLE REPO IF PRESENT ==="
if [ -d "$HOME/sablelinux/.git" ]; then
  cd "$HOME/sablelinux" || true
  pwd
  git status --short --branch 2>/dev/null || true
  git log --oneline --decorate -n 8 2>/dev/null || true
fi

echo
echo "=== SABLE / LIVE / INSTALL PATHS ==="
for p in /mnt/liveiso /mnt/liveroot /mnt/liveroot-clean /mnt/liveroot-edit /mnt/liveroot-glk /mnt/liveroot-agno1 /mnt/sable-usb /mnt/usb-live /mnt/usb-root /mnt/usb-efi; do
  if [ -e "$p" ]; then
    echo
    echo "--- $p ---"
    stat -c '%y %F %n' "$p" 2>/dev/null || true
    du -sh "$p" 2>/dev/null || true
    find "$p" -maxdepth 3 -type f -printf '%TY-%Tm-%Td %TH:%TM %s %p\n' 2>/dev/null | sort | tail -80
  fi
done

echo
echo "=== RECENT BOOT ERRORS ==="
journalctl -b -p warning..alert --no-pager 2>/dev/null | tail -250 || true

} | tee "$OUT"

echo
echo "Inventory written to: $OUT"
