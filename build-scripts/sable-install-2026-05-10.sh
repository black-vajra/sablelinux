#!/bin/bash
# =============================================================================
# sable-install — SableLinux Disk Installer
# Run from live session: sudo sable-install
# =============================================================================
set -euo pipefail

# Auto-detect squashfs location
SABLEDEV=$(findfs LABEL=SABLELINUX 2>/dev/null) || true
if [[ -n "$SABLEDEV" ]]; then
    mkdir -p /mnt/sable-usb
    mount -o ro "$SABLEDEV" /mnt/sable-usb 2>/dev/null || true
    SQUASHFS="/mnt/sable-usb/live/filesystem.squashfs"
else
    SQUASHFS="/mnt/scan/live/filesystem.squashfs"
fi

TARGET="/mnt/install-target"
BOLD='\033[1m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

die()    { echo -e "${RED}ERROR: $*${NC}" >&2; exit 1; }
info()   { echo -e "${CYAN}:: $*${NC}"; }
ok()     { echo -e "${GREEN}OK: $*${NC}"; }
warn()   { echo -e "${YELLOW}WARN: $*${NC}"; }
header() { echo -e "\n${BOLD}=== $* ===${NC}\n"; }

require_root() { [[ $EUID -eq 0 ]] || die "Must run as root: sudo sable-install"; }

cleanup() {
    info "Cleaning up mounts..."
    umount "$TARGET/dev/pts"                  2>/dev/null || true
    umount "$TARGET/dev"                      2>/dev/null || true
    umount "$TARGET/proc"                     2>/dev/null || true
    umount "$TARGET/sys/firmware/efi/efivars" 2>/dev/null || true
    umount "$TARGET/sys"                      2>/dev/null || true
    umount "$TARGET/run"                      2>/dev/null || true
    umount "$TARGET/boot/efi"                 2>/dev/null || true
    umount "$TARGET/boot"                     2>/dev/null || true
    umount "$TARGET"                          2>/dev/null || true
    umount /mnt/sable-usb                     2>/dev/null || true
}
trap cleanup EXIT

require_root

header "SableLinux Installer"
echo "This will install SableLinux to a disk of your choice."
echo "ALL DATA ON THE TARGET DISK WILL BE DESTROYED."
echo ""

[[ -f "$SQUASHFS" ]] || die "Squashfs not found at $SQUASHFS — are you running from the live USB?"
info "Squashfs: $SQUASHFS"

header "Available Disks"
lsblk -o NAME,SIZE,TYPE,FSTYPE,LABEL,MODEL | grep -v "^loop"
echo ""

while true; do
    read -rp "Enter target disk (e.g. sda, nvme0n1): " DISK
    DISK="${DISK#/dev/}"
    [[ -b "/dev/$DISK" ]] && break
    warn "/dev/$DISK not found, try again."
done

DISKDEV="/dev/$DISK"

if [[ "$DISK" == nvme* ]]; then
    P1="${DISKDEV}p1"; P2="${DISKDEV}p2"; P3="${DISKDEV}p3"
else
    P1="${DISKDEV}1";  P2="${DISKDEV}2";  P3="${DISKDEV}3"
fi

echo ""
warn "Target: $DISKDEV — this disk will be completely wiped."
lsblk "$DISKDEV"
echo ""
read -rp "Type YES to confirm: " CONFIRM
[[ "$CONFIRM" == "YES" ]] || die "Aborted."

header "Encryption"
read -rp "Enable LUKS encryption on root? [y/N]: " USE_LUKS
USE_LUKS="${USE_LUKS,,}"
LUKS_NAME="sable-root"

header "System Configuration"
read -rp "Hostname: " SYS_HOSTNAME
[[ -n "$SYS_HOSTNAME" ]] || die "Hostname cannot be empty."

echo ""
echo "Examples: America/New_York  America/Chicago  America/Los_Angeles  Europe/London  UTC"
read -rp "Timezone [America/New_York]: " SYS_TZ
SYS_TZ="${SYS_TZ:-America/New_York}"
[[ -f "/usr/share/zoneinfo/$SYS_TZ" ]] || die "Invalid timezone: $SYS_TZ"

echo ""
read -rp "New username: " NEW_USER
[[ -n "$NEW_USER" ]] || die "Username cannot be empty."
[[ "$NEW_USER" != "root" ]] || die "Cannot use root as username."

echo ""
read -rsp "Password for $NEW_USER: " USER_PASS; echo
read -rsp "Confirm password: " USER_PASS2; echo
[[ "$USER_PASS" == "$USER_PASS2" ]] || die "Passwords do not match."
[[ -n "$USER_PASS" ]] || die "Password cannot be empty."

echo ""
read -rsp "Root password: " ROOT_PASS; echo
read -rsp "Confirm root password: " ROOT_PASS2; echo
[[ "$ROOT_PASS" == "$ROOT_PASS2" ]] || die "Root passwords do not match."
[[ -n "$ROOT_PASS" ]] || die "Root password cannot be empty."

if [[ "$USE_LUKS" == "y" ]]; then
    echo ""
    read -rsp "LUKS passphrase: " LUKS_PASS; echo
    read -rsp "Confirm LUKS passphrase: " LUKS_PASS2; echo
    [[ "$LUKS_PASS" == "$LUKS_PASS2" ]] || die "LUKS passphrases do not match."
    [[ -n "$LUKS_PASS" ]] || die "LUKS passphrase cannot be empty."
fi

header "Installation Summary"
echo "  Disk:      $DISKDEV"
echo "  EFI:       $P1  (512M)"
echo "  Boot:      $P2  (2G)"
echo "  Root:      $P3  (remainder)"
echo "  LUKS:      ${USE_LUKS:-n}"
echo "  Hostname:  $SYS_HOSTNAME"
echo "  Timezone:  $SYS_TZ"
echo "  User:      $NEW_USER"
echo ""
read -rp "Proceed with installation? [y/N]: " GO
[[ "${GO,,}" == "y" ]] || die "Aborted."

header "Partitioning $DISKDEV"
wipefs -a "$DISKDEV" 2>/dev/null || true
sgdisk -Z "$DISKDEV"
sgdisk -n 1:0:+512M -t 1:ef00 -c 1:"EFI"  "$DISKDEV"
sgdisk -n 2:0:+2G   -t 2:8300 -c 2:"BOOT" "$DISKDEV"
sgdisk -n 3:0:0     -t 3:8300 -c 3:"ROOT" "$DISKDEV"
sgdisk -v "$DISKDEV"
blockdev --rereadpt "$DISKDEV" 2>/dev/null || true
sleep 2
ok "Partitioned $DISKDEV"

header "Formatting"
mkfs.vfat -F32 -n EFI "$P1"
ok "$P1 → EFI vfat"
mkfs.ext4 -L BOOT -F "$P2"
ok "$P2 → /boot ext4"

if [[ "$USE_LUKS" == "y" ]]; then
    echo -n "$LUKS_PASS" | cryptsetup luksFormat --type luks2 "$P3" -
    echo -n "$LUKS_PASS" | cryptsetup open "$P3" "$LUKS_NAME" -
    ROOT_DEVICE="/dev/mapper/$LUKS_NAME"
    mkfs.ext4 -L ROOT -F "$ROOT_DEVICE"
    ok "$P3 → LUKS → ext4"
else
    ROOT_DEVICE="$P3"
    mkfs.ext4 -L ROOT -F "$P3"
    ok "$P3 → root ext4"
fi

header "Mounting Target"
mkdir -p "$TARGET"
mount "$ROOT_DEVICE" "$TARGET"
mkdir -p "$TARGET/boot"
mount "$P2" "$TARGET/boot"
mkdir -p "$TARGET/boot/efi"
mount "$P1" "$TARGET/boot/efi"
ok "Target mounted at $TARGET"

header "Extracting System (10-20 minutes)"
unsquashfs -f -d "$TARGET" "$SQUASHFS"
ok "Squashfs extracted"

header "Configuring System"
echo "$SYS_HOSTNAME" > "$TARGET/etc/hostname"
cat > "$TARGET/etc/hosts" << HOSTS
127.0.0.1   localhost
127.0.1.1   $SYS_HOSTNAME
::1         localhost ip6-localhost ip6-loopback
HOSTS

ln -sf "/usr/share/zoneinfo/$SYS_TZ" "$TARGET/etc/localtime"

ROOT_UUID=$(blkid -s UUID -o value "$ROOT_DEVICE")
BOOT_UUID=$(blkid -s UUID -o value "$P2")
EFI_UUID=$(blkid -s UUID -o value "$P1")

cat > "$TARGET/etc/fstab" << FSTAB
UUID=$ROOT_UUID  /          ext4  defaults,noatime          0 1
UUID=$BOOT_UUID  /boot      ext4  defaults,noatime          0 2
UUID=$EFI_UUID   /boot/efi  vfat  umask=0077                0 2
tmpfs            /tmp       tmpfs defaults,nosuid,nodev      0 0
FSTAB
ok "fstab written"

if [[ "$USE_LUKS" == "y" ]]; then
    LUKS_UUID=$(blkid -s UUID -o value "$P3")
    echo "$LUKS_NAME UUID=$LUKS_UUID none luks" >> "$TARGET/etc/crypttab"
    ok "crypttab written"
fi

rm -f "$TARGET/etc/machine-id"
cat /proc/sys/kernel/random/uuid | tr -d '-' > "$TARGET/etc/machine-id"
rm -f "$TARGET/etc/ssh/ssh_host_"*

header "Chroot Bind Mounts"
for dir in dev dev/pts proc sys run; do
    mount --bind /$dir "$TARGET/$dir"
done
mount --bind /sys/firmware/efi/efivars "$TARGET/sys/firmware/efi/efivars" 2>/dev/null || true

header "Creating Users"
echo "root:$ROOT_PASS" | chroot "$TARGET" chpasswd
chroot "$TARGET" userdel -r sable       2>/dev/null || true
chroot "$TARGET" userdel -r "$NEW_USER" 2>/dev/null || true
sed -i '/^sable/d'       "$TARGET/etc/group"
sed -i '/^sable/d'       "$TARGET/etc/gshadow" 2>/dev/null || true
sed -i "/^$NEW_USER/d"  "$TARGET/etc/group"
sed -i "/^$NEW_USER/d"  "$TARGET/etc/gshadow" 2>/dev/null || true
chroot "$TARGET" useradd -m -G wheel,audio,video,input,render,kvm \
    -s /bin/bash "$NEW_USER"
echo "$NEW_USER:$USER_PASS" | chroot "$TARGET" chpasswd
grep -q "^%wheel" "$TARGET/etc/sudoers" 2>/dev/null || \
    echo "%wheel ALL=(ALL:ALL) ALL" >> "$TARGET/etc/sudoers"
ok "User $NEW_USER created"

USER_HOME="$TARGET/home/$NEW_USER"

mkdir -p "$USER_HOME/.config/sway"
[[ -d "$TARGET/home/sable/.config/sway" ]] && [[ "$NEW_USER" != "sable" ]] && \
    cp -r "$TARGET/home/sable/.config/sway/." "$USER_HOME/.config/sway/"

cat > "$USER_HOME/.bash_profile" << PROFILE
export XDG_RUNTIME_DIR=/run/user/\$(id -u)
export XDG_SESSION_TYPE=wayland
export XDG_SESSION_DESKTOP=sway
export MOZ_ENABLE_WAYLAND=1
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export PATH="\$HOME/.local/bin:/usr/local/bin:\$PATH"
[[ -f ~/.bashrc ]] && source ~/.bashrc
if [[ -z \$WAYLAND_DISPLAY ]] && [[ \$(tty) == /dev/tty1 ]]; then
    exec sway
fi
PROFILE

sed -i "s|/home/sable|/home/$NEW_USER|g"  "$USER_HOME/.config/sway/config" 2>/dev/null || true
sed -i "s|/home/pepper|/home/$NEW_USER|g" "$USER_HOME/.config/sway/config" 2>/dev/null || true

chroot "$TARGET" chown -R "$NEW_USER:$NEW_USER" "/home/$NEW_USER"
ok ".bash_profile and sway config written for $NEW_USER"

mkdir -p "$TARGET/etc/systemd/system/getty@tty1.service.d"
cat > "$TARGET/etc/systemd/system/getty@tty1.service.d/autologin.conf" << AUTOLOGIN
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $NEW_USER --noclear %I \$TERM
AUTOLOGIN
ok "tty1 autologin configured for $NEW_USER"

for svc in llama-server wg-quick@wg0; do
    rm -f "$TARGET/etc/systemd/system/multi-user.target.wants/$svc.service"
done
ok "Hardware-specific services disabled"

header "Building Initramfs"
TOOLS="/opt/initramfs-tools"
IWORK="/tmp/installer-initramfs"
rm -rf "$IWORK"
mkdir -p "$IWORK"/{bin,dev,proc,sys,lib,lib64,sysroot}

for bin in busybox switch_root findfs; do
    if [ -f "$TOOLS/bin/$bin" ]; then
        cp "$TOOLS/bin/$bin" "$IWORK/bin/"
    else
        SRC=$(which $bin 2>/dev/null) && cp "$SRC" "$IWORK/bin/" || true
    fi
done

cp "$TOOLS/lib/libc.so.6"               "$IWORK/lib/"   2>/dev/null || true
cp "$TOOLS/lib/libm.so.6"               "$IWORK/lib/"   2>/dev/null || true
cp "$TOOLS/lib64/ld-linux-x86-64.so.2"  "$IWORK/lib64/" 2>/dev/null || true

mkdir -p "$IWORK/lib/firmware/intel/iwlwifi" \
         "$IWORK/lib/firmware/intel-ucode" \
         "$IWORK/lib/firmware/rtw88" \
         "$IWORK/lib/firmware/mediatek"

cp /lib/firmware/iwlwifi-7265D-*.ucode      "$IWORK/lib/firmware/"              2>/dev/null || true
cp /lib/firmware/intel/iwlwifi/*.ucode      "$IWORK/lib/firmware/intel/iwlwifi/" 2>/dev/null || true
cp /lib/firmware/intel-ucode/*              "$IWORK/lib/firmware/intel-ucode/"   2>/dev/null || true
cp /lib/firmware/rtw88/rtw8821c_fw.bin      "$IWORK/lib/firmware/rtw88/"         2>/dev/null || true
cp /lib/firmware/mediatek/mt7925/*          "$IWORK/lib/firmware/mediatek/"      2>/dev/null || true
cp /lib/firmware/regulatory.db              "$IWORK/lib/firmware/"               2>/dev/null || true
cp /lib/firmware/regulatory.db.p7s          "$IWORK/lib/firmware/"               2>/dev/null || true

cat > "$IWORK/init" << INITEOF
#!/bin/busybox sh
/bin/busybox --install -s /bin

mount -t proc none /proc
mount -t sysfs none /sys
mount -t devtmpfs none /dev 2>/dev/null || true
mkdir -p /dev/pts
mount -t devpts none /dev/pts
mdev -s

echo "SableLinux starting..."
sleep 2

ROOTDEV=\$(findfs UUID=$ROOT_UUID 2>/dev/null)
if [ -z "\$ROOTDEV" ]; then
    echo "ERROR: cannot find root UUID=$ROOT_UUID"
    exec sh
fi

mount -o ro "\$ROOTDEV" /sysroot || exec sh

umount /dev/pts
umount /dev
umount /proc
umount /sys

exec switch_root /sysroot /sbin/init
INITEOF

chmod 755 "$IWORK/init"
cd "$IWORK"
find . | cpio -o -H newc | gzip -9 > "$TARGET/boot/initramfs-$(uname -r).img"
cd /
rm -rf "$IWORK"
ok "Initramfs built with firmware for UUID=$ROOT_UUID"

header "Copying Kernel"
KVER=$(uname -r)
if [[ -f "/mnt/sable-usb/boot/vmlinuz" ]]; then
    cp "/mnt/sable-usb/boot/vmlinuz" "$TARGET/boot/vmlinuz-$KVER"
elif [[ -f "/boot/vmlinuz-$KVER" ]]; then
    cp "/boot/vmlinuz-$KVER" "$TARGET/boot/vmlinuz-$KVER"
else
    die "Cannot locate kernel to install"
fi
ok "Kernel installed as vmlinuz-$KVER"

header "Installing Bootloader"
chroot "$TARGET" grub-install \
    --target=x86_64-efi \
    --efi-directory=/boot/efi \
    --bootloader-id=SableLinux \
    --recheck || warn "grub-install returned non-zero — continuing"

chroot "$TARGET" grub-mkconfig -o /boot/grub/grub.cfg
ok "GRUB config written"

mkdir -p "$TARGET/boot/efi/EFI/BOOT"
cp "$TARGET/boot/efi/EFI/SableLinux/grubx64.efi" \
   "$TARGET/boot/efi/EFI/BOOT/BOOTX64.EFI"
ok "EFI fallback path written (EFI/BOOT/BOOTX64.EFI)"

[[ "$USE_LUKS" == "y" ]] && \
    warn "LUKS: rebuild initramfs after first boot using make-initramfs.sh"

header "Installation Complete"
ok "SableLinux installed to $DISKDEV"
echo ""
echo "  Hostname: $SYS_HOSTNAME  |  User: $NEW_USER  |  TZ: $SYS_TZ"
echo ""
echo "Remove the USB and reboot."
echo ""
read -rp "Reboot now? [y/N]: " REBOOT
[[ "${REBOOT,,}" == "y" ]] && { cleanup; reboot; }
