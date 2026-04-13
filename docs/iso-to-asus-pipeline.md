SableLinux ISO Pipeline — Full Preparation Outline for maya

Phase 0: Mesa iris Rebuild (pots, prerequisite — do first)
Why first: Without iris, maya gets llvmpipe. Sway on llvmpipe on a Core i5-6200U is unusable for a demo.
0.1  chroot into /mnt/sable
0.2  cd to Mesa 25.0.1 build dir (or re-extract source)
0.3  meson setup build --wipe \
       --prefix=/usr --libdir=lib \
       -Dgallium-drivers=radeonsi,iris,llvmpipe \
       -Dvulkan-drivers=amd,intel \
       [retain all other existing flags]
0.4  ninja -C build -j14
0.5  ninja -C build install
0.6  verify: ls /mnt/sable/usr/lib/dri/iris_dri.so
0.7  verify: ls /mnt/sable/usr/share/vulkan/icd.d/intel_icd.x86_64.json
0.8  commit + BUILDLOG.md update

Phase 1: Compat Kernel Build (pots, chroot into sable)
The current SableLinux kernel was built for pots (RDNA4, no i915). A separate sable-compat kernel is needed for the ISO. Build alongside the existing kernel — do not replace it on pots.
1.1 Kernel Config Deltas
Start from the existing SableLinux .config. Apply these changes:
GPU:
CONFIG_DRM_I915=m
CONFIG_DRM_I915_GVT=n          # skip KVMGT for ISO — reduces build time
CONFIG_DRM_AMDGPU=m             # already present, verify
CONFIG_DRM_NOUVEAU=m            # compat tier, optional but include
CONFIG_DRM_SIMPLEDRM=y          # framebuffer fallback for early boot
i915 firmware loading (GuC/HuC):
CONFIG_INTEL_MEI=m
CONFIG_INTEL_MEI_ME=m           # MEI needed for i915 HuC auth
WiFi (maya: Intel 7265, iwlmvm):
CONFIG_IWLWIFI=m
CONFIG_IWLWIFI_LEDS=y
CONFIG_IWLDVM=m                 # older 4000/5000 series
CONFIG_IWLMVM=m                 # 7260/7265/8260/9260/ax200/ax210
CONFIG_MAC80211=m
CONFIG_CFG80211=m
CONFIG_CFG80211_WEXT=y
Ethernet:
CONFIG_R8169=m                  # Realtek RTL8111/8168 — confirm present
Bluetooth:
CONFIG_BT=m
CONFIG_BT_HCIBTUSB=m
CONFIG_BT_HCIBTUSB_BCM=y
CONFIG_BT_HCIBTUSB_RTL=y
CONFIG_BT_INTEL=m               # btintel — Intel 0x0a2a
Input / HID:
CONFIG_HID=y
CONFIG_USB_HID=m
CONFIG_HID_MULTITOUCH=m         # Atmel maXTouch 03eb:8a78 (USB-HID on maya)
CONFIG_HID_GENERIC=m
CONFIG_KEYBOARD_ATKBD=y         # AT Translated Set 2 keyboard (built-in)
CONFIG_MOUSE_PS2=y              # psmouse
CONFIG_SERIO=y
CONFIG_SERIO_I8042=y
ASUS laptop platform:
CONFIG_ASUS_WMI=m
CONFIG_ASUS_NB_WMI=m
CONFIG_ACPI_WMI=m
SD card reader:
CONFIG_MMC=m
CONFIG_MMC_REALTEK_USB=m        # rtsx_usb
CONFIG_MMC_REALTEK_USB_SDMMC=m  # rtsx_usb_sdmmc
CONFIG_MEMSTICK=m
CONFIG_MEMSTICK_REALTEK_USB=m
Audio:
CONFIG_SND_HDA_INTEL=m
CONFIG_SND_HDA_CODEC_REALTEK=m  # ALC255
CONFIG_SND_HDA_CODEC_HDMI=m
CONFIG_SND_SOC=m                # needed for snd_soc_avs/SOF path
USB:
CONFIG_USB_XHCI_HCD=m           # Sunrise Point-LP xHCI [8086:9d2f]
CONFIG_USB_EHCI_HCD=m
CONFIG_USB=y
Power management (Skylake):
CONFIG_X86_INTEL_PSTATE=y
CONFIG_CPU_FREQ_GOV_POWERSAVE=y
CONFIG_CPU_FREQ_GOV_ONDEMAND=y
CONFIG_INTEL_RAPL=m
CONFIG_INTEL_POWERCLAMP=m
CONFIG_INTEL_IDLE=y
CONFIG_ACPI_PROCESSOR=y
CONFIG_ACPI_THERMAL=y
Storage for installer:
CONFIG_ATA=y
CONFIG_SATA_AHCI=m              # Intel SATA [8086:9d03]
CONFIG_ATA_PIIX=m               # legacy fallback
CONFIG_BLK_DEV_DM=m             # device-mapper (for LVM/LUKS in target)
CONFIG_DM_CRYPT=m               # LUKS support — existing Ubuntu partition uses it
CONFIG_EXT4_FS=y
CONFIG_VFAT_FS=m                # EFI partition
CONFIG_FAT_FS=m
CONFIG_NLS_UTF8=m
CONFIG_NLS_ISO8859_1=m
CONFIG_NLS_CODEPAGE_437=m
Live environment:
CONFIG_SQUASHFS=y               # must be y (built-in) so initramfs can mount it
CONFIG_SQUASHFS_LZ4=y
CONFIG_SQUASHFS_LZO=y
CONFIG_SQUASHFS_XZ=y
CONFIG_SQUASHFS_ZSTD=y
CONFIG_OVERLAY_FS=y             # overlayfs — must be y for live env
CONFIG_LOOP=y                   # loopback device — must be y
CONFIG_TMPFS=y
Crypto (retain existing — verify XTS):
CONFIG_CRYPTO_XTS=y             # already added — keep
PCIe AER note: CONFIG_PCIEAER=y keep it (diagnostic value), but add pci=noaer to the ISO boot cmdline to suppress the noise flood from the iwlwifi slot (00:1c.5) on maya. This is a firmware/hardware quirk on the Skylake Q503UA, not a driver bug.
1.2 Build procedure
bash# In sable chroot on pots
cd /usr/src/linux-6.16.1
cp .config .config.pots-backup    # preserve pots config
# Apply the delta above with make menuconfig or scripted sed
make menuconfig                    # verify all items above
make -j14
make modules_install INSTALL_MOD_PATH=/tmp/sable-compat-modules
make install INSTALL_PATH=/tmp/sable-compat-boot
# Output: vmlinuz-6.16.1-sable-compat, System.map, .config
# Modules tree in /tmp/sable-compat-modules/lib/modules/6.16.1-sable-compat/
1.3 Verification checklist
bash# Confirm modules exist:
ls /tmp/sable-compat-modules/lib/modules/6.16.1-sable-compat/kernel/drivers/gpu/drm/i915/
ls .../drivers/net/wireless/intel/iwlwifi/
ls .../drivers/hid/hid-multitouch.ko
ls .../drivers/mmc/host/rtsx_usb*.ko
ls .../fs/squashfs/squashfs.ko 2>/dev/null || echo "squashfs built-in (correct)"
# SQUASHFS=y means no .ko — confirm it's in the config as y not m
grep "CONFIG_SQUASHFS=" .config    # must be =y
grep "CONFIG_OVERLAY_FS=" .config  # must be =y

Phase 2: Firmware Bundle
2.1 Source linux-firmware
On the pots host (not chroot), clone or have linux-firmware available:
bash# On pots host
git clone https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git \
    /tmp/linux-firmware
# or use the copy already on the Ubuntu host system:
# ls /lib/firmware/  (Ubuntu 24.04 ships most of this)
2.2 Mandatory firmware for maya WiFi — highest priority
bash# iwlwifi-7265D is the exact model from hwscan: Intel Wireless 7265 [8086:095a]
# Firmware files needed (confirmed from Ubuntu's working load):
ls /lib/firmware/iwlwifi-7265D-*.ucode
# Expected: iwlwifi-7265D-29.ucode (latest API level for 7265)
# Also include:
# iwlwifi-7265-*.ucode (non-D variant, same hardware, fallback)
2.3 Full firmware manifest to bundle in ISO
iwlwifi-7265D-*.ucode            # maya WiFi — MANDATORY
iwlwifi-7265-*.ucode             # 7265 non-D variant fallback
iwlwifi-7260-*.ucode             # 7260 (Haswell era laptops)
iwlwifi-8260-*.ucode             # Skylake/Kaby Lake higher-end
iwlwifi-8265-*.ucode             # Kaby Lake common
iwlwifi-9260-*.ucode             # Whiskey Lake era
iwlwifi-QuZ-*.ucode              # ax200/ax201 Wi-Fi 6
iwlwifi-so-a0-gf-*.pnvm          # ax210 Wi-Fi 6E
i915/skl_*.bin                   # Skylake GuC/HuC (maya)
i915/bdw_*.bin                   # Broadwell
i915/kbl_*.bin                   # Kaby Lake
i915/bxt_*.bin                   # Broxton/Apollo Lake
intel-ucode/06-4e-03             # Skylake-U (maya's CPU model 78, stepping 3)
intel-ucode/06-4f-01             # Broadwell Xeon
intel-ucode/06-8e-*              # Kaby/Whiskey/Amber Lake-U
intel-ucode/06-9e-*              # Kaby/Coffee Lake
amdgpu/gfx1201_*.bin             # RDNA4 (pots) — for installed system
amdgpu/gfx1100_*.bin             # RDNA3 (RX 7900 etc.) — compat tier
rtl_nic/rtl8168*.fw              # Realtek GbE (may not be strictly needed for r8169)
regulatory.db                    # WiFi regulatory database — REQUIRED for cfg80211
regulatory.db.p7s
2.4 Bluetooth firmware
The Intel 7265 BT [8087:0a2a] uses btintel + a firmware file loaded from linux-firmware:
bashls /lib/firmware/intel/ibt-hw-37.8.bseq   # or similar ibt-* pattern
# The 7265 BT maps to ibt-hw-37.8* files
# Confirm on maya's running system:
dmesg | grep -i bluetooth | grep -i firmware
Bundle all intel/ibt-*.sfi, intel/ibt-*.ddc, intel/ibt-hw-*.bseq files.
2.5 Placement in ISO tree
/firmware/          <- all the above, flat or mirroring /lib/firmware/ layout
The initramfs live hook will copy these to /lib/firmware/ in the live overlay before module loading.

Phase 3: Live Root Filesystem (squashfs)
3.1 Pre-squash cleanup in sable chroot
bash# Remove from live snapshot (do NOT delete from running pots install):
rm -rf /usr/src/linux-*/    # kernel build trees — large
rm -rf /var/cache/           # build caches
rm -rf /tmp/*
rm -rf /root/.bash_history
# Remove pots-specific kernel modules (keep only compat kernel modules):
# /lib/modules/ should contain 6.16.1-sable-compat only for the ISO
# (copy compat modules into sable root before squashing)
3.2 Add live infrastructure to sable root
bash# Create liveuser account:
useradd -m -G wheel,audio,video,input,plugdev -s /bin/bash liveuser
passwd -d liveuser              # no password
# Auto-login on tty1 (systemd getty override):
mkdir -p /etc/systemd/system/getty@tty1.service.d/
cat > /etc/systemd/system/getty@tty1.service.d/autologin.conf << 'EOF'
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin liveuser --noclear %I $TERM
EOF
# Sway auto-start in liveuser's .bash_profile:
echo '[[ $(tty) == /dev/tty1 ]] && exec sway' >> /home/liveuser/.bash_profile
3.3 Install compat kernel into sable root
bash# From pots host:
cp /tmp/sable-compat-boot/vmlinuz-6.16.1-sable-compat /mnt/sable/boot/
rsync -a /tmp/sable-compat-modules/lib/modules/6.16.1-sable-compat/ \
    /mnt/sable/lib/modules/6.16.1-sable-compat/
3.4 Build the squashfs
bash# On pots host (not inside chroot):
mksquashfs /mnt/sable /tmp/sable-live.squashfs \
    -comp zstd \
    -Xcompression-level 19 \
    -b 1M \
    -noappend \
    -e /mnt/sable/proc \
    -e /mnt/sable/sys \
    -e /mnt/sable/dev \
    -e /mnt/sable/run \
    -e /mnt/sable/tmp \
    -e /mnt/sable/boot/efi \
    -e /mnt/sable/mnt
# Expected size: ~4-6GB depending on AI/security stack
# Verify:
unsquashfs -stat /tmp/sable-live.squashfs

Phase 4: Live initramfs (dracut)
Dracut is preferred — has dmsquash-live module which handles exactly this mount topology.
4.1 Verify/install dracut in sable root
bash# In sable chroot — check if dracut is built:
which dracut && dracut --version
# If not built: dracut is an LFS package, needs to be built
# Source: https://github.com/dracut-ng/dracut-ng/releases
# Build is straightforward (bash + cpio dependency)
4.2 dracut modules required
base
kernel-modules          # loads .ko files from the compat kernel
kernel-modules-extra
fs-lib
shutdown
udev-rules
bash
systemd               # or sysvinit depending on SableLinux init
rootfs-block          # for finding the root device
dmsquash-live         # THIS is the key module — mounts squashfs + overlayfs
dmsquash-live-ntfs    # skip unless needed
livenet               # skip unless doing network boot
plymouth              # optional but nice for live boot experience
4.3 dracut config for live ISO
bash# /etc/dracut.conf.d/sable-live.conf (inside sable chroot):
cat > /etc/dracut.conf.d/sable-live.conf << 'EOF'
add_dracutmodules+=" dmsquash-live "
omit_dracutmodules+=" iscsi nfs brltty "
compress="zstd"
early_microcode="yes"
hostonly="no"                    # generic initramfs — not host-specific
ro_mnt="yes"
EOF
4.4 Build the initramfs
bash# Inside sable chroot:
dracut --no-hostonly \
    --add "dmsquash-live" \
    --kver 6.16.1-sable-compat \
    /boot/initramfs-6.16.1-sable-compat-live.img
# Verify it's reasonable size (30-80MB):
ls -lh /boot/initramfs-6.16.1-sable-compat-live.img
4.5 Firmware injection into initramfs
The iwlwifi firmware must be available before the live root is mounted (WiFi needed for network in early userspace if ever needed, and certainly before overlayfs is up). Two options:
Option A (preferred): Include firmware in the squashfs and rely on the live overlay being up before NetworkManager/iwd starts. WiFi firmware is not needed in initramfs itself — it's needed when the live session starts. The initramfs only needs to mount the squashfs; it doesn't need WiFi.
Option B: Bundle firmware into initramfs directly via install_items+= in dracut config.
Go with Option A. The iwlwifi firmware lives in /lib/firmware/ inside the squashfs (which is the sable root). Confirm it's there before building the squashfs:
bash# In sable chroot before squashing:
mkdir -p /lib/firmware
# Copy firmware bundle:
cp /tmp/firmware-bundle/iwlwifi-7265D-*.ucode /lib/firmware/
cp /tmp/firmware-bundle/iwlwifi-7265*.ucode /lib/firmware/
cp -r /tmp/firmware-bundle/i915/ /lib/firmware/
cp -r /tmp/firmware-bundle/intel/ /lib/firmware/        # BT firmware
cp /tmp/firmware-bundle/intel-ucode/*.bin /lib/firmware/intel-ucode/
cp /tmp/firmware-bundle/regulatory.db* /lib/firmware/

Phase 5: ISO Tree Construction and GRUB Hybrid ISO
5.1 ISO directory structure
/tmp/sable-iso-tree/
├── boot/
│   ├── grub/
│   │   ├── grub.cfg
│   │   └── themes/sable/         (optional branding)
│   ├── vmlinuz-6.16.1-sable-compat
│   └── initramfs-6.16.1-sable-compat-live.img
├── EFI/
│   └── BOOT/
│       ├── BOOTX64.EFI           (GRUB EFI image)
│       └── grub.cfg              (minimal — chainloads boot/grub/grub.cfg)
├── live/
│   └── filesystem.squashfs       (the sable-live.squashfs)
└── sablelinux.md5                (optional integrity check)
5.2 GRUB configuration
bash# /tmp/sable-iso-tree/boot/grub/grub.cfg
cat > /tmp/sable-iso-tree/boot/grub/grub.cfg << 'EOF'
set default=0
set timeout=10

# Detect ISO root for loopback support
if [ -f /boot/grub/grub.cfg ]; then
    set isopath=""
else
    set isopath="/boot"
fi

menuentry "SableLinux Live" {
    linux   /boot/vmlinuz-6.16.1-sable-compat \
            boot=live \
            root=live:CDLABEL=SABLELINUX \
            rd.live.image \
            rd.live.overlay.overlayfs=1 \
            quiet splash \
            pci=noaer \
            loglevel=3
    initrd  /boot/initramfs-6.16.1-sable-compat-live.img
}

menuentry "SableLinux Installer" {
    linux   /boot/vmlinuz-6.16.1-sable-compat \
            boot=live \
            root=live:CDLABEL=SABLELINUX \
            rd.live.image \
            rd.live.overlay.overlayfs=1 \
            sable.install=1 \
            quiet splash \
            pci=noaer \
            loglevel=3
    initrd  /boot/initramfs-6.16.1-sable-compat-live.img
}

menuentry "SableLinux (debug — verbose boot)" {
    linux   /boot/vmlinuz-6.16.1-sable-compat \
            boot=live \
            root=live:CDLABEL=SABLELINUX \
            rd.live.image \
            rd.live.overlay.overlayfs=1 \
            pci=noaer
    initrd  /boot/initramfs-6.16.1-sable-compat-live.img
}
EOF
Key cmdline params:

boot=live — dracut dmsquash-live trigger word
root=live:CDLABEL=SABLELINUX — tells dracut to find the ISO by disk label
rd.live.image — dracut: look for live/filesystem.squashfs
rd.live.overlay.overlayfs=1 — use overlayfs (not device-mapper overlay)
pci=noaer — suppress the PCIe AER flood from WiFi slot on Q503UA

5.3 Build the hybrid ISO
bash# Requires: grub-mkrescue (grub2 host package), xorriso
grub-mkrescue \
    --output=/tmp/sablelinux-dev.iso \
    --modules="part_gpt part_msdos iso9660 fat ext2 normal ls cat echo linux \
               initrd search search_label loopback squash4 lvm minicmd" \
    --compress=no \
    /tmp/sable-iso-tree \
    -- \
    -volid "SABLELINUX" \
    -rational-rock \
    -joliet \
    -joliet-long \
    -iso-level 3

# Verify hybrid MBR+GPT+EFI:
file /tmp/sablelinux-dev.iso
# Should show: ISO 9660 CD-ROM filesystem data (bootable)
fdisk -l /tmp/sablelinux-dev.iso
# Should show both a GPT and MBR partition table + EFI partition
5.4 Write to USB for maya testing
bash# On pots host — replace sdX with the actual USB drive
dd if=/tmp/sablelinux-dev.iso of=/dev/sdX bs=4M status=progress oflag=sync

Phase 6: First Boot Validation on maya
This phase is testing, not building, but must happen before Phase 7 (Calamares).
6.1 maya BIOS setup
- Boot into UEFI firmware (F2 at POST)
- Disable Secure Boot (not signing the bootloader yet)
- Set boot order: USB first
- Confirm: UEFI boot mode (not legacy CSM)
6.2 Live boot checklist
[ ] GRUB menu appears (confirms ISO UEFI boot works)
[ ] Boot to Sway desktop as liveuser (no password prompt)
[ ] Display output via i915 / iris (check with glxinfo: renderer should say "Mesa Intel HD Graphics 520")
[ ] WiFi listed in iwd or NetworkManager (iwlwifi loaded, 7265D firmware found)
[ ] Connect to WiFi — confirms firmware + driver working end to end
[ ] Touchpad responds (Atmel hid_multitouch via USB)
[ ] Audio device present (aplay -l shows ALC255)
[ ] Fn keys work (asus_wmi)
[ ] Check for kernel errors: journalctl -b -p 3
[ ] Confirm pci=noaer suppressed the AER flood
6.3 Critical failure modes to diagnose
SymptomMost likely causeCheckBlack screen after GRUBi915 not loading, no KMSAdd nomodeset to cmdline; check dracut-initqueue for i915 errorssquashfs mount failsroot=live: label mismatch or squashfs not foundVerify ISO label == SABLELINUX; check dracut debug outputWiFi not visibleMissing iwlwifi-7265D-*.ucode`dmesgTouchpad deadhid_multitouch not loaded`lsmodSway won't startWayland/DRM issueCheck /tmp/sway-liveuser.log, iris vs. llvmpipe fallback

Phase 7: Calamares Installer
This is the largest new build effort — Qt is not yet in SableLinux. Options in order of effort:
7.1 Qt build decision
Qt5 (recommended for initial pass):

Calamares supports Qt5 through v3.3.x
Smaller build than Qt6
Existing SableLinux GTK3 stack is irrelevant — Calamares brings its own Qt widgets

Estimated build order in sable chroot:
7.1.1  Qt5 base (qtbase5) — approx 2h build on pots
         ./configure -prefix /usr -libdir /usr/lib \
             -sysconfdir /etc -no-openssl -openssl-linked \
             -system-freetype -system-libpng -system-zlib \
             -skip webengine -skip webkit -nomake examples -nomake tests
7.1.2  Qt5 SVG module (qtsvg) — needed for Calamares icons
7.1.3  Qt5 XML module (qtxml) — needed
7.1.4  Qt5 Network module (qtnetwork) — included in qtbase
7.2 Calamares dependencies (in addition to Qt5)
7.2.1  KPMcore — partition manager library (KDE, but no full KDE needed)
         - requires: kdelibs5-dev equivalent: only kwidgetsaddons, kpmcore
         - This is the hardest dependency. kpmcore requires ki18n, kconfig.
         - Plan: build minimal KDE Frameworks subset: extra-cmake-modules,
                 ki18n, kconfig, kwidgetsaddons, kpmcore
7.2.2  libatasmart — ATA device probing for disk detection
7.2.3  libpwquality — password quality checking
7.2.4  yaml-cpp — config file parsing (likely already built for other packages)
7.2.5  Python 3 + boost-python — Calamares modules are Python scriptable
7.3 Calamares build
bashgit clone https://github.com/calamares/calamares.git
cd calamares
git checkout v3.3.x  # latest stable Qt5-compatible branch
cmake -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/usr \
      -DCMAKE_INSTALL_LIBDIR=lib \
      -DQt5_DIR=/usr/lib/cmake/Qt5 \
      -DSKIP_MODULES="webview tracking" \
      -DWITH_PYTHON=ON \
      -DWITH_PYBIND11=ON \
      -B build -G Ninja
ninja -C build -j14
ninja -C build install
7.4 Calamares module config for maya
Required modules (ordered by install sequence):
welcome       — license, language selection
locale        — locale/timezone
keyboard      — keyboard layout
partition     — partition editor (KPMcore backend)
              — must handle: sda1 EFI (reuse), sda2 /boot, sda3 / (wipe LUKS)
users         — create user + root password
summary       — review before write
install       — execute actions
bootloader    — install GRUB2 to sda1 EFI + /boot/efi
finished      — reboot prompt
Partition module config note for maya: The existing disk has LUKS on sda3. Calamares partition module needs to be told to wipe it (or offer guided partitioning that replaces it). For the initial maya target, a simple guided mode that erases the disk and creates a fresh EFI + /boot + / layout is sufficient.
7.5 Calamares branding
/etc/calamares/branding/sablelinux/
├── branding.desc
├── show.qml           (slideshow during install)
└── logo.png
7.6 Installer launch integration
In the live session, add a desktop launcher (Sway/wayland-compatible):
bash# /home/liveuser/.config/sway/config addition:
exec_once foot -- calamares   # or a proper .desktop file + file manager

Phase 8: Driver Acquisition System
8.1 Detection script (/usr/lib/sable/sable-firmware-detect)
bash#!/bin/bash
# Run at installer startup — before partitioning
# Outputs a list of missing firmware

FIRMWARE_MANIFEST=/usr/share/sable/firmware-manifest.json
NEEDED=()

# PCI IDs with known firmware requirements:
declare -A PCI_FIRMWARE_MAP=(
    ["8086:095a"]="iwlwifi-7265D-29.ucode"   # Intel 7265 (maya)
    ["8086:24fd"]="iwlwifi-8265-36.ucode"    # Intel 8265
    ["8086:2526"]="iwlwifi-9260-th-b0-jf-b0-46.ucode"
    ["8086:2725"]="iwl-debug-yoyo.bin"        # ax200
    ["8086:0082"]="iwlwifi-6000g2a-6.ucode"  # 6300
    # ... extend as needed
)

for id in "${!PCI_FIRMWARE_MAP[@]}"; do
    if lspci -n | grep -q "$id"; then
        fw="${PCI_FIRMWARE_MAP[$id]}"
        if [[ ! -f "/lib/firmware/$fw" ]]; then
            NEEDED+=("$fw")
        fi
    fi
done

printf '%s\n' "${NEEDED[@]}"
8.2 Download mechanism
bash# /usr/lib/sable/sable-firmware-fetch
#!/bin/bash
FIRMWARE_MIRROR="https://firmware.sablelinux.dev"
# fallback: https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/plain/

for fw in "$@"; do
    curl -fsSL "${FIRMWARE_MIRROR}/${fw}" -o "/lib/firmware/${fw}" \
        && echo "Fetched: $fw" \
        || echo "WARN: Could not fetch $fw"
done
udevadm trigger --subsystem-match=firmware
8.3 Calamares integration
Wire sable-firmware-detect as a pre-install hook in Calamares shellprocess module. Present results in the welcome screen. If missing firmware is detected and network is available, offer a one-click "Download missing firmware" action before proceeding.

Summary: Ordered Task List
#TaskLocationBlockingEst. effort0Mesa iris rebuildpots/chrootPhase 6 display30min1Kernel compat .config + buildpots/chrootEverything45min build2Firmware bundle assemblypots hostPhase 3,515min3sable root prep (liveuser, compat kernel, firmware)pots/chrootPhase 330min4squashfs buildpots hostPhase 520-60min (I/O bound)5dracut initramfs buildpots/chrootPhase 510min6ISO tree assembly + grub-mkrescuepots hostPhase 620min7First boot validation on mayamayaPhase 7+1-2h iteration8Qt5 buildpots/chrootPhase 72-3h9KDE Frameworks subset (kpmcore deps)pots/chrootPhase 72-3h10Calamares build + configpots/chrootPhase 71h11Installer integration + brandingpots/chrootPhase 71h12Driver acquisition scripts + mirrorsablelinux.devPhase 82h13Full install test on mayamayaship1h
Critical path: 0 → 1 → 2 → 3 → 4 → 5 → 6 → 7 (validate live) → 8 → 9 → 10 → 11 → 13
Start with step 0 today.
