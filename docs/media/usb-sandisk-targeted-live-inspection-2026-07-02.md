# USB SanDisk Initramfs + SquashFS Targeted Inspection — 2026-07-02

Thu Jul  2 11:51:46 AM EDT 2026

## Initramfs top-level
drwxr-xr-x 100 /tmp/sable-initramfs-inspect/lib
drwxr-xr-x 120 /tmp/sable-initramfs-inspect/mnt
drwxr-xr-x 200 /tmp/sable-initramfs-inspect
drwxr-xr-x 240 /tmp/sable-initramfs-inspect/lib/firmware
drwxr-xr-x 40 /tmp/sable-initramfs-inspect/dev
drwxr-xr-x 40 /tmp/sable-initramfs-inspect/mnt/overlay
drwxr-xr-x 40 /tmp/sable-initramfs-inspect/mnt/rootfs
drwxr-xr-x 40 /tmp/sable-initramfs-inspect/mnt/scan
drwxr-xr-x 40 /tmp/sable-initramfs-inspect/mnt/squashfs
drwxr-xr-x 40 /tmp/sable-initramfs-inspect/proc
drwxr-xr-x 40 /tmp/sable-initramfs-inspect/sys
drwxr-xr-x 60 /tmp/sable-initramfs-inspect/lib64
drwxr-xr-x 60 /tmp/sable-initramfs-inspect/lib/firmware/mediatek
drwxr-xr-x 80 /tmp/sable-initramfs-inspect/bin
lrwxrwxrwx 22 /tmp/sable-initramfs-inspect/lib/firmware/iwlwifi-7265D-22.ucode
lrwxrwxrwx 22 /tmp/sable-initramfs-inspect/lib/firmware/iwlwifi-7265D-23.ucode
lrwxrwxrwx 22 /tmp/sable-initramfs-inspect/lib/firmware/iwlwifi-7265D-24.ucode
lrwxrwxrwx 22 /tmp/sable-initramfs-inspect/lib/firmware/iwlwifi-7265D-25.ucode
lrwxrwxrwx 22 /tmp/sable-initramfs-inspect/lib/firmware/iwlwifi-7265D-26.ucode
lrwxrwxrwx 22 /tmp/sable-initramfs-inspect/lib/firmware/iwlwifi-7265D-27.ucode
lrwxrwxrwx 22 /tmp/sable-initramfs-inspect/lib/firmware/iwlwifi-7265D-28.ucode
-rw-r--r-- 1036668 /tmp/sable-initramfs-inspect/lib/firmware/iwlwifi-7265D-29.ucode
-rw-r--r-- 139472 /tmp/sable-initramfs-inspect/lib/firmware/rtw8821c_fw.bin
-rw-r--r-- 952616 /tmp/sable-initramfs-inspect/lib/libm.so.6
-rwxr-xr-x 1231 /tmp/sable-initramfs-inspect/init
-rwxr-xr-x 2124608 /tmp/sable-initramfs-inspect/bin/busybox
-rwxr-xr-x 2124608 /tmp/sable-initramfs-inspect/bin/switch_root
-rwxr-xr-x 2125328 /tmp/sable-initramfs-inspect/lib/libc.so.6
-rwxr-xr-x 236616 /tmp/sable-initramfs-inspect/lib64/ld-linux-x86-64.so.2

## Initramfs likely init scripts
-rwxr-xr-x 1231 /tmp/sable-initramfs-inspect/init

--- /tmp/sable-initramfs-inspect/init ---
#!/bin/busybox sh
/bin/busybox --install -s /bin

mount -t proc none /proc
mount -t sysfs none /sys
mount -t devtmpfs none /dev 2>/dev/null || true
mkdir -p /dev/pts
mount -t devpts none /dev/pts
mdev -s

echo "SableLinux Live Boot..."
sleep 3

mkdir -p /mnt/scan
ROOTDEV=""
for i in 1 2 3 4 5; do
    ROOTDEV=$(findfs LABEL=SABLELINUX 2>/dev/null)
    [ -n "$ROOTDEV" ] && break
    echo "Waiting for device... attempt $i"
    sleep 2
done

if [ -z "$ROOTDEV" ]; then
    echo "ERROR: cannot find SABLELINUX partition"
    exec sh
fi

echo "Found $ROOTDEV"
mount -t ext4 -o ro "$ROOTDEV" /mnt/scan || exec sh

mkdir -p /mnt/squashfs
mount -t squashfs -o loop /mnt/scan/live/filesystem.squashfs /mnt/squashfs || exec sh

mkdir -p /mnt/overlay /mnt/rootfs
mount -t tmpfs tmpfs /mnt/overlay
mkdir -p /mnt/overlay/upper /mnt/overlay/work
mount -t overlay overlay \
    -o lowerdir=/mnt/squashfs,upperdir=/mnt/overlay/upper,workdir=/mnt/overlay/work \
    /mnt/rootfs || exec sh

mkdir -p /mnt/rootfs/proc /mnt/rootfs/sys /mnt/rootfs/dev /mnt/rootfs/dev/pts
mount --move /proc /mnt/rootfs/proc
mount --move /sys /mnt/rootfs/sys
mount --move /dev /mnt/rootfs/dev

echo "Pivoting to live root..."
exec switch_root /mnt/rootfs /sbin/init

## Initramfs references to live media
/tmp/sable-initramfs-inspect/init:4:mount -t proc none /proc
/tmp/sable-initramfs-inspect/init:5:mount -t sysfs none /sys
/tmp/sable-initramfs-inspect/init:6:mount -t devtmpfs none /dev 2>/dev/null || true
/tmp/sable-initramfs-inspect/init:8:mount -t devpts none /dev/pts
/tmp/sable-initramfs-inspect/init:17:    ROOTDEV=$(findfs LABEL=SABLELINUX 2>/dev/null)
/tmp/sable-initramfs-inspect/init:24:    echo "ERROR: cannot find SABLELINUX partition"
/tmp/sable-initramfs-inspect/init:29:mount -t ext4 -o ro "$ROOTDEV" /mnt/scan || exec sh
/tmp/sable-initramfs-inspect/init:31:mkdir -p /mnt/squashfs
/tmp/sable-initramfs-inspect/init:32:mount -t squashfs -o loop /mnt/scan/live/filesystem.squashfs /mnt/squashfs || exec sh
/tmp/sable-initramfs-inspect/init:34:mkdir -p /mnt/overlay /mnt/rootfs
/tmp/sable-initramfs-inspect/init:35:mount -t tmpfs tmpfs /mnt/overlay
/tmp/sable-initramfs-inspect/init:36:mkdir -p /mnt/overlay/upper /mnt/overlay/work
/tmp/sable-initramfs-inspect/init:37:mount -t overlay overlay \
/tmp/sable-initramfs-inspect/init:38:    -o lowerdir=/mnt/squashfs,upperdir=/mnt/overlay/upper,workdir=/mnt/overlay/work \
/tmp/sable-initramfs-inspect/init:42:mount --move /proc /mnt/rootfs/proc
/tmp/sable-initramfs-inspect/init:43:mount --move /sys /mnt/rootfs/sys
/tmp/sable-initramfs-inspect/init:44:mount --move /dev /mnt/rootfs/dev
/tmp/sable-initramfs-inspect/init:46:echo "Pivoting to live root..."

## Squashfs OS release
NAME="SableLinux"
PRETTY_NAME="Sable Linux 1.0"
ID=sablelinux
VERSION="1.0"
VERSION_ID="1.0"
HOME_URL="https://sablelinux.dev"
BUG_REPORT_URL="https://github.com/black-vajra/sablelinux/issues"
ANSI_COLOR="1;30"
NAME="SableLinux"
PRETTY_NAME="Sable Linux 1.0"
ID=sablelinux
VERSION="1.0"
VERSION_ID="1.0"
HOME_URL="https://sablelinux.dev"
BUG_REPORT_URL="https://github.com/black-vajra/sablelinux/issues"
ANSI_COLOR="1;30"

## Squashfs PAM/limits contents

--- etc/pam.d/system-auth ---
auth      required    pam_unix.so nullok
account   required    pam_unix.so
password  required    pam_unix.so shadow sha512
session   required    pam_unix.so
session   required    pam_limits.so

--- etc/pam.d/system-session ---
session    required    pam_limits.so
# Begin /etc/pam.d/system-session
session required pam_env.so readenv=1
session required pam_unix.so
# End /etc/pam.d/system-session
# Begin Systemd addition
session required pam_loginuid.so
session optional pam_systemd.so
# End Systemd addition

--- etc/security/limits.conf ---
missing

--- etc/security/limits.d/99-filedesc.conf ---
*               soft    nofile          65536
*               hard    nofile          65536

## Squashfs Sway config
### SableLinux Sway Configuration

### Variables
set $mod Mod4
set $left h
set $down j
set $up k
set $right l
set $term foot
set $menu fuzzel

### Environment
xwayland enable

### Output
output * bg /home/sable/.config/sway/wallpapers/sable-wallpaper.png fill

### Autostart
exec mako
exec /home/sable/.config/sway/audio-init.sh
#exec swayidle -w \
#    timeout 300 'swaylock -f -c 000000' \
#    before-sleep 'swaylock -f -c 000000'

### Appearance
gaps inner 6
gaps outer 4
default_border pixel 2
default_floating_border pixel 2
smart_gaps on
smart_borders on

# Border colors          border   bg       text     indicator child_border
client.focused           #7c3aed #7c3aed  #ffffff  #a78bfa   #7c3aed
client.focused_inactive  #1e1e2e #1e1e2e  #888888  #1e1e2e   #1e1e2e
client.unfocused         #1e1e2e #1e1e2e  #555555  #1e1e2e   #1e1e2e
client.urgent            #ef4444 #ef4444  #ffffff  #ef4444   #ef4444

### Input
input "type:keyboard" {
    xkb_layout us
    repeat_delay 300
    repeat_rate 50
}
input "type:touchpad" {
    tap enabled
    natural_scroll enabled
    dwt enabled
}

### Named Workspaces
set $ws1  "1:term"
set $ws2  "2:web"
set $ws3  "3:recon"
set $ws4  "4:exploit"
set $ws5  "5:analysis"
set $ws6  "6:ai"
set $ws7  "7:files"
set $ws8  "8:comms"
set $ws9  "9:media"
set $ws10 "10:misc"

### Key Bindings — Basics
bindsym $mod+Return exec $term
bindsym $mod+Shift+q kill
bindsym $mod+d exec $menu
bindsym $mod+Shift+c reload
bindsym $mod+Shift+e exec swaynag -t warning \
    -m 'Exit sway?' \
    -B 'Yes' 'swaymsg exit'
floating_modifier $mod normal
bindsym $mod+F8  exec pactl set-sink-volume @DEFAULT_SINK@ +5%
bindsym $mod+F7  exec pactl set-sink-volume @DEFAULT_SINK@ -5%

### Key Bindings — Focus
bindsym $mod+$left  focus left
bindsym $mod+$down  focus down
bindsym $mod+$up    focus up
bindsym $mod+$right focus right
bindsym $mod+Left   focus left
bindsym $mod+Down   focus down
bindsym $mod+Up     focus up
bindsym $mod+Right  focus right

### Key Bindings — Move
bindsym $mod+Shift+$left  move left
bindsym $mod+Shift+$down  move down
bindsym $mod+Shift+$up    move up
bindsym $mod+Shift+$right move right
bindsym $mod+Shift+Left   move left
bindsym $mod+Shift+Down   move down
bindsym $mod+Shift+Up     move up
bindsym $mod+Shift+Right  move right

### Key Bindings — Workspaces
bindsym $mod+1 workspace $ws1
bindsym $mod+2 workspace $ws2
bindsym $mod+3 workspace $ws3
bindsym $mod+4 workspace $ws4
bindsym $mod+5 workspace $ws5
bindsym $mod+6 workspace $ws6
bindsym $mod+7 workspace $ws7
bindsym $mod+8 workspace $ws8
bindsym $mod+9 workspace $ws9
bindsym $mod+0 workspace $ws10

bindsym $mod+Shift+1 move container to workspace $ws1
bindsym $mod+Shift+2 move container to workspace $ws2
bindsym $mod+Shift+3 move container to workspace $ws3
bindsym $mod+Shift+4 move container to workspace $ws4
bindsym $mod+Shift+5 move container to workspace $ws5
bindsym $mod+Shift+6 move container to workspace $ws6
bindsym $mod+Shift+7 move container to workspace $ws7
bindsym $mod+Shift+8 move container to workspace $ws8
bindsym $mod+Shift+9 move container to workspace $ws9
bindsym $mod+Shift+0 move container to workspace $ws10

### Key Bindings — Layout
bindsym $mod+b splith
bindsym $mod+v splitv
bindsym $mod+s layout stacking
bindsym $mod+w layout tabbed
bindsym $mod+e layout toggle split
bindsym $mod+f fullscreen
bindsym $mod+Shift+space floating toggle
bindsym $mod+space focus mode_toggle
bindsym $mod+a focus parent

### Key Bindings — Scratchpad
bindsym $mod+Shift+minus move scratchpad
bindsym $mod+minus scratchpad show

### Key Bindings — Resize Mode
mode "resize" {
    bindsym $left  resize shrink width  10px
    bindsym $down  resize grow   height 10px
    bindsym $up    resize shrink height 10px
    bindsym $right resize grow   width  10px
    bindsym Left   resize shrink width  10px
    bindsym Down   resize grow   height 10px
    bindsym Up     resize shrink height 10px
    bindsym Right  resize grow   width  10px
    bindsym Return mode "default"
    bindsym Escape mode "default"
}
bindsym $mod+r mode "resize"

### Key Bindings — Screenshots
bindsym Print      exec grim /home/sable/screenshots/$(date +%Y%m%d_%H%M%S).png
bindsym $mod+Print exec grim -g "$(slurp)" /home/sable/screenshots/$(date +%Y%m%d_%H%M%S).png
bindsym $mod+Shift+Print exec grim -g "$(slurp)" - | wl-copy

#bindsym $mod+Shift+x exec swaylock -f -c 000000

### Key Bindings — Audio
bindsym --locked XF86AudioMute        exec pactl set-sink-mute @DEFAULT_SINK@ toggle
bindsym --locked XF86AudioLowerVolume exec pactl set-sink-volume @DEFAULT_SINK@ -5%
bindsym --locked XF86AudioRaiseVolume exec pactl set-sink-volume @DEFAULT_SINK@ +5%
bindsym --locked XF86AudioMicMute     exec pactl set-source-mute @DEFAULT_SOURCE@ toggle

### Floating Window Rules
for_window [app_id="org.gnome.Calculator"] floating enable
for_window [app_id="nm-connection-editor"] floating enable
for_window [title="(?i)^(confirm|dialog|error|warning|preferences)"] floating enable

### Status Bar
bar {
    swaybar_command waybar
}

include /etc/sway/config.d/*

## Squashfs Waybar files
drwxr-xr-x root/root                52 2026-03-10 15:12 squashfs-root/etc/xdg/waybar
-rw-r--r-- root/root              1263 2026-06-18 17:50 squashfs-root/etc/xdg/waybar/config.jsonc
-rw-r--r-- root/root              5319 2024-09-13 03:51 squashfs-root/etc/xdg/waybar/style.css
drwxr-xr-x sable/sable               3 2026-06-18 16:29 squashfs-root/home/sable/.config/waybar
-rwxr-xr-x root/root           3954112 2026-03-10 15:12 squashfs-root/usr/bin/waybar

## Squashfs installer search, narrow
-rw-r--r-- pepper/pepper            29 2026-03-08 21:11 squashfs-root/opt/metasploit-framework/external/source/exploits/CVE-2020-9850/payload/sbx/root/.gitignore
-rw-r--r-- pepper/pepper           180 2026-03-08 21:11 squashfs-root/opt/metasploit-framework/external/source/exploits/CVE-2020-9850/payload/sbx/root/Makefile
drwxr-xr-x pepper/pepper            31 2026-03-08 21:11 squashfs-root/opt/metasploit-framework/external/source/exploits/CVE-2020-9850/payload/sbx/root/app
drwxr-xr-x pepper/pepper            61 2026-03-08 21:11 squashfs-root/opt/metasploit-framework/external/source/exploits/CVE-2020-9850/payload/sbx/root/app/Contents
-rw-r--r-- pepper/pepper          1484 2026-03-08 21:11 squashfs-root/opt/metasploit-framework/external/source/exploits/CVE-2020-9850/payload/sbx/root/app/Contents/Info.plist
drwxr-xr-x pepper/pepper            30 2026-03-08 21:11 squashfs-root/opt/metasploit-framework/external/source/exploits/CVE-2020-9850/payload/sbx/root/app/Contents/MacOS
-rwxr-xr-x pepper/pepper         12804 2026-03-08 21:11 squashfs-root/opt/metasploit-framework/external/source/exploits/CVE-2020-9850/payload/sbx/root/app/Contents/MacOS/popcalc
-rw-r--r-- pepper/pepper             8 2026-03-08 21:11 squashfs-root/opt/metasploit-framework/external/source/exploits/CVE-2020-9850/payload/sbx/root/app/Contents/PkgInfo
-rw-r--r-- pepper/pepper           812 2026-03-08 21:11 squashfs-root/opt/metasploit-framework/external/source/exploits/CVE-2020-9850/payload/sbx/root/main.c
-rw-r--r-- pepper/pepper          5584 2026-03-08 21:11 squashfs-root/opt/metasploit-framework/external/source/vncdll/winvnc/libjpeg/install-sh
-rwxr-xr-x pepper/pepper          2512 2026-03-08 21:19 squashfs-root/opt/metasploit-framework/vendor/bundle/ruby/3.3.0/gems/ffi-1.16.3/ext/ffi_c/libffi/.ci/install.sh
-rwxr-xr-x pepper/pepper         15358 2026-03-08 21:19 squashfs-root/opt/metasploit-framework/vendor/bundle/ruby/3.3.0/gems/ffi-1.16.3/ext/ffi_c/libffi/install-sh
drwxr-xr-x pepper/pepper            48 2026-03-08 21:19 squashfs-root/opt/metasploit-framework/vendor/bundle/ruby/3.3.0/gems/yard-0.9.37/templates/default/root/dot
-rw-r--r-- pepper/pepper            91 2026-03-08 21:19 squashfs-root/opt/metasploit-framework/vendor/bundle/ruby/3.3.0/gems/yard-0.9.37/templates/default/root/dot/child.erb
-rw-r--r-- pepper/pepper            97 2026-03-08 21:19 squashfs-root/opt/metasploit-framework/vendor/bundle/ruby/3.3.0/gems/yard-0.9.37/templates/default/root/dot/setup.rb
drwxr-xr-x pepper/pepper            31 2026-03-08 21:19 squashfs-root/opt/metasploit-framework/vendor/bundle/ruby/3.3.0/gems/yard-0.9.37/templates/default/root/html
-rw-r--r-- pepper/pepper            63 2026-03-08 21:19 squashfs-root/opt/metasploit-framework/vendor/bundle/ruby/3.3.0/gems/yard-0.9.37/templates/default/root/html/setup.rb
-rwxr-xr-x root/root             13997 2026-03-08 21:24 squashfs-root/usr/lib/postgresql/pgxs/config/install-sh
-rwxr-xr-x root/root             15358 2026-02-21 11:26 squashfs-root/usr/lib/python3.13/config-3.13-x86_64-linux-gnu/install-sh
-rw-r--r-- root/root                 4 2026-03-10 12:37 squashfs-root/usr/lib/python3.13/site-packages/Flask_RESTful-0.3.10.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-08 18:53 squashfs-root/usr/lib/python3.13/site-packages/PySocks-1.7.1.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-09 20:44 squashfs-root/usr/lib/python3.13/site-packages/ROPGadget-7.6.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-10 12:41 squashfs-root/usr/lib/python3.13/site-packages/aiodns-4.0.0.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-10 12:41 squashfs-root/usr/lib/python3.13/site-packages/aiofiles-25.1.0.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-10 12:41 squashfs-root/usr/lib/python3.13/site-packages/aiohappyeyeballs-2.6.1.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-10 12:41 squashfs-root/usr/lib/python3.13/site-packages/aiohttp-3.13.3.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-10 12:41 squashfs-root/usr/lib/python3.13/site-packages/aiohttp_socks-0.11.0.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-10 12:41 squashfs-root/usr/lib/python3.13/site-packages/aiomultiprocess-0.9.1.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-10 12:41 squashfs-root/usr/lib/python3.13/site-packages/aiosignal-1.4.0.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-10 12:41 squashfs-root/usr/lib/python3.13/site-packages/aiosqlite-0.22.1.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-10 12:37 squashfs-root/usr/lib/python3.13/site-packages/aniso8601-10.0.1.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-10 12:41 squashfs-root/usr/lib/python3.13/site-packages/annotated_doc-0.0.4.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-10 12:41 squashfs-root/usr/lib/python3.13/site-packages/annotated_types-0.7.0.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-10 12:41 squashfs-root/usr/lib/python3.13/site-packages/anyio-4.12.1.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-10 12:41 squashfs-root/usr/lib/python3.13/site-packages/argcomplete-3.6.3.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-09 20:44 squashfs-root/usr/lib/python3.13/site-packages/asttokens-3.0.1.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-10 12:37 squashfs-root/usr/lib/python3.13/site-packages/attrs-25.4.0.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-10 12:41 squashfs-root/usr/lib/python3.13/site-packages/backoff-2.2.1.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-09 22:54 squashfs-root/usr/lib/python3.13/site-packages/backports_zstd-1.3.0.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-08 18:53 squashfs-root/usr/lib/python3.13/site-packages/bcrypt-5.0.0.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-10 12:41 squashfs-root/usr/lib/python3.13/site-packages/beautifulsoup4-4.14.3.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-10 12:37 squashfs-root/usr/lib/python3.13/site-packages/blinker-1.9.0.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-09 22:54 squashfs-root/usr/lib/python3.13/site-packages/boto3-1.41.5.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-09 22:54 squashfs-root/usr/lib/python3.13/site-packages/botocore-1.41.6.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-09 22:54 squashfs-root/usr/lib/python3.13/site-packages/build-1.4.0.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-08 18:53 squashfs-root/usr/lib/python3.13/site-packages/capstone-6.0.0a7.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-09 20:44 squashfs-root/usr/lib/python3.13/site-packages/capstone6pwndbg-6.0.0a6.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-10 12:41 squashfs-root/usr/lib/python3.13/site-packages/censys-2.2.19.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-08 18:53 squashfs-root/usr/lib/python3.13/site-packages/certifi-2026.2.25.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-08 18:53 squashfs-root/usr/lib/python3.13/site-packages/cffi-2.0.0.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-09 22:54 squashfs-root/usr/lib/python3.13/site-packages/cfgv-3.5.0.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-08 18:53 squashfs-root/usr/lib/python3.13/site-packages/charset_normalizer-3.4.5.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-10 12:37 squashfs-root/usr/lib/python3.13/site-packages/click-8.3.1.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-10 12:41 squashfs-root/usr/lib/python3.13/site-packages/click_plugins-1.1.1.2.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-10 12:36 squashfs-root/usr/lib/python3.13/site-packages/colorama-0.4.6.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-08 18:53 squashfs-root/usr/lib/python3.13/site-packages/colored_traceback-0.4.2.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-09 22:48 squashfs-root/usr/lib/python3.13/site-packages/cppheaderparser-2.7.4.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-10 12:37 squashfs-root/usr/lib/python3.13/site-packages/croniter-6.0.0.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-08 18:53 squashfs-root/usr/lib/python3.13/site-packages/cryptography-46.0.5.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-09 20:44 squashfs-root/usr/lib/python3.13/site-packages/decomp2dbg-3.14.1.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-09 20:44 squashfs-root/usr/lib/python3.13/site-packages/decorator-5.2.1.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-10 12:41 squashfs-root/usr/lib/python3.13/site-packages/deprecated-1.3.1.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-10 12:37 squashfs-root/usr/lib/python3.13/site-packages/dicttoxml-1.7.16.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-09 22:54 squashfs-root/usr/lib/python3.13/site-packages/distlib-0.4.0.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-10 12:37 squashfs-root/usr/lib/python3.13/site-packages/dnspython-2.8.0.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-10 12:36 squashfs-root/usr/lib/python3.13/site-packages/et_xmlfile-2.0.0.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-09 20:44 squashfs-root/usr/lib/python3.13/site-packages/executing-2.2.1.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-10 12:41 squashfs-root/usr/lib/python3.13/site-packages/fastapi-0.135.1.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-09 20:44 squashfs-root/usr/lib/python3.13/site-packages/filelock-3.25.1.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-10 12:37 squashfs-root/usr/lib/python3.13/site-packages/flasgger-0.9.7.1.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-10 12:37 squashfs-root/usr/lib/python3.13/site-packages/flask-3.1.3.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-02-21 11:30 squashfs-root/usr/lib/python3.13/site-packages/flit_core-3.12.0.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-10 12:41 squashfs-root/usr/lib/python3.13/site-packages/frozenlist-1.8.0.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-10 12:41 squashfs-root/usr/lib/python3.13/site-packages/greenlet-3.3.2.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-10 12:41 squashfs-root/usr/lib/python3.13/site-packages/h11-0.16.0.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-10 12:37 squashfs-root/usr/lib/python3.13/site-packages/html5lib-1.1.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-10 12:41 squashfs-root/usr/lib/python3.13/site-packages/httpcore-1.0.9.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-10 12:41 squashfs-root/usr/lib/python3.13/site-packages/httpx-0.28.1.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-09 22:54 squashfs-root/usr/lib/python3.13/site-packages/identify-2.6.17.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-08 18:53 squashfs-root/usr/lib/python3.13/site-packages/idna-3.11.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-09 22:54 squashfs-root/usr/lib/python3.13/site-packages/iniconfig-2.3.0.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-08 18:53 squashfs-root/usr/lib/python3.13/site-packages/intervaltree-3.2.1.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-08 18:53 squashfs-root/usr/lib/python3.13/site-packages/invoke-2.2.1.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-09 20:44 squashfs-root/usr/lib/python3.13/site-packages/ipython-8.38.0.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-10 12:37 squashfs-root/usr/lib/python3.13/site-packages/itsdangerous-2.2.0.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-09 20:44 squashfs-root/usr/lib/python3.13/site-packages/jedi-0.19.2.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-02-21 12:12 squashfs-root/usr/lib/python3.13/site-packages/jinja2-3.1.6.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-09 22:54 squashfs-root/usr/lib/python3.13/site-packages/jmespath-1.1.0.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-09 22:54 squashfs-root/usr/lib/python3.13/site-packages/joblib-1.5.3.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-09 20:44 squashfs-root/usr/lib/python3.13/site-packages/jpype1-1.5.2.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-10 12:37 squashfs-root/usr/lib/python3.13/site-packages/jsonschema-4.26.0.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-10 12:37 squashfs-root/usr/lib/python3.13/site-packages/jsonschema_specifications-2025.9.1.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-09 20:44 squashfs-root/usr/lib/python3.13/site-packages/libbs-3.3.0.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-10 12:41 squashfs-root/usr/lib/python3.13/site-packages/limits-5.8.0.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-09 22:54 squashfs-root/usr/lib/python3.13/site-packages/lit-18.1.8.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-10 12:37 squashfs-root/usr/lib/python3.13/site-packages/lxml-6.0.2.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-08 18:53 squashfs-root/usr/lib/python3.13/site-packages/mako-1.3.10.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-09 20:44 squashfs-root/usr/lib/python3.13/site-packages/markdown_it_py-4.0.0.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-02-21 12:12 squashfs-root/usr/lib/python3.13/site-packages/markupsafe-3.0.2.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-09 20:44 squashfs-root/usr/lib/python3.13/site-packages/matplotlib_inline-0.2.1.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-09 20:44 squashfs-root/usr/lib/python3.13/site-packages/mdurl-0.1.2.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-10 12:37 squashfs-root/usr/lib/python3.13/site-packages/mechanize-0.4.10.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-09 22:48 squashfs-root/usr/lib/python3.13/site-packages/meson-1.7.0.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-10 12:37 squashfs-root/usr/lib/python3.13/site-packages/mistune-3.2.0.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-09 22:54 squashfs-root/usr/lib/python3.13/site-packages/msgpack-1.1.2.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-10 12:41 squashfs-root/usr/lib/python3.13/site-packages/multidict-6.7.1.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-10 12:41 squashfs-root/usr/lib/python3.13/site-packages/netaddr-1.3.0.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-09 20:44 squashfs-root/usr/lib/python3.13/site-packages/networkx-3.6.1.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-09 20:44 squashfs-root/usr/lib/python3.13/site-packages/niche_elf-0.3.6.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-09 22:54 squashfs-root/usr/lib/python3.13/site-packages/nodeenv-1.10.0.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-10 12:36 squashfs-root/usr/lib/python3.13/site-packages/numpy-2.4.3.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-10 12:36 squashfs-root/usr/lib/python3.13/site-packages/openpyxl-3.1.5.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-02-21 11:30 squashfs-root/usr/lib/python3.13/site-packages/packaging-25.0.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-10 12:36 squashfs-root/usr/lib/python3.13/site-packages/pandas-2.3.3.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-08 18:53 squashfs-root/usr/lib/python3.13/site-packages/paramiko-4.0.0.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-09 20:44 squashfs-root/usr/lib/python3.13/site-packages/parso-0.8.6.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-09 20:44 squashfs-root/usr/lib/python3.13/site-packages/pexpect-4.9.0.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-08 18:53 squashfs-root/usr/lib/python3.13/site-packages/pip-26.0.1.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-10 13:05 squashfs-root/usr/lib/python3.13/site-packages/pipx-1.8.0.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-09 20:44 squashfs-root/usr/lib/python3.13/site-packages/platformdirs-4.9.4.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-10 12:41 squashfs-root/usr/lib/python3.13/site-packages/playwright-1.58.0.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-09 22:54 squashfs-root/usr/lib/python3.13/site-packages/pluggy-1.6.0.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-08 18:53 squashfs-root/usr/lib/python3.13/site-packages/plumbum-1.10.0.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-09 20:44 squashfs-root/usr/lib/python3.13/site-packages/ply-3.11.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-09 22:54 squashfs-root/usr/lib/python3.13/site-packages/pre_commit-4.5.1.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-09 20:44 squashfs-root/usr/lib/python3.13/site-packages/prompt_toolkit-3.0.52.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-10 12:41 squashfs-root/usr/lib/python3.13/site-packages/propcache-0.4.1.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-08 18:53 squashfs-root/usr/lib/python3.13/site-packages/psutil-7.2.2.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-09 20:44 squashfs-root/usr/lib/python3.13/site-packages/pt-1.0.0.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-09 20:44 squashfs-root/usr/lib/python3.13/site-packages/ptyprocess-0.7.0.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-09 20:44 squashfs-root/usr/lib/python3.13/site-packages/pure_eval-0.2.3.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-09 20:44 squashfs-root/usr/lib/python3.13/site-packages/pwndbg-2026.2.18.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-09 20:44 squashfs-root/usr/lib/python3.13/site-packages/pwntools-4.14.1.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-10 12:41 squashfs-root/usr/lib/python3.13/site-packages/pycares-5.0.1.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-08 18:53 squashfs-root/usr/lib/python3.13/site-packages/pycparser-3.0.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-10 12:41 squashfs-root/usr/lib/python3.13/site-packages/pydantic-2.12.5.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-10 12:41 squashfs-root/usr/lib/python3.13/site-packages/pydantic_core-2.41.5.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-10 12:41 squashfs-root/usr/lib/python3.13/site-packages/pyee-13.0.1.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-08 18:53 squashfs-root/usr/lib/python3.13/site-packages/pyelftools-0.32.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-09 20:44 squashfs-root/usr/lib/python3.13/site-packages/pyghidra-3.0.2.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-08 18:53 squashfs-root/usr/lib/python3.13/site-packages/pygments-2.19.2.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-08 18:53 squashfs-root/usr/lib/python3.13/site-packages/pynacl-1.6.2.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-09 22:54 squashfs-root/usr/lib/python3.13/site-packages/pyproject_hooks-1.2.0.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-08 18:53 squashfs-root/usr/lib/python3.13/site-packages/pyserial-3.5.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-09 22:54 squashfs-root/usr/lib/python3.13/site-packages/pytest-8.4.2.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-09 22:54 squashfs-root/usr/lib/python3.13/site-packages/pytest_cmake-0.13.0.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-08 18:53 squashfs-root/usr/lib/python3.13/site-packages/python_dateutil-2.9.0.post0.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-09 22:54 squashfs-root/usr/lib/python3.13/site-packages/python_discovery-1.1.2.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-09 22:54 squashfs-root/usr/lib/python3.13/site-packages/python_magic-0.4.27.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-10 12:41 squashfs-root/usr/lib/python3.13/site-packages/python_socks-2.8.1.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-10 12:36 squashfs-root/usr/lib/python3.13/site-packages/pytz-2026.1.post1.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-10 12:41 squashfs-root/usr/lib/python3.13/site-packages/pyyaml-6.0.3.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-09 22:54 squashfs-root/usr/lib/python3.13/site-packages/pyzstd-0.19.1.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-10 12:37 squashfs-root/usr/lib/python3.13/site-packages/redis-7.3.0.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-10 12:37 squashfs-root/usr/lib/python3.13/site-packages/referencing-0.37.0.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-08 18:53 squashfs-root/usr/lib/python3.13/site-packages/requests-2.32.5.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-10 12:41 squashfs-root/usr/lib/python3.13/site-packages/requests_file-3.0.1.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-10 12:36 squashfs-root/usr/lib/python3.13/site-packages/requests_futures-1.0.2.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-10 12:41 squashfs-root/usr/lib/python3.13/site-packages/retrying-1.4.2.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-09 20:44 squashfs-root/usr/lib/python3.13/site-packages/rich-14.3.3.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-10 12:37 squashfs-root/usr/lib/python3.13/site-packages/rpds_py-0.30.0.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-08 18:53 squashfs-root/usr/lib/python3.13/site-packages/rpyc-6.0.2.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-10 12:37 squashfs-root/usr/lib/python3.13/site-packages/rq-2.7.0.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-09 22:54 squashfs-root/usr/lib/python3.13/site-packages/s3transfer-0.15.0.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-02-21 11:30 squashfs-root/usr/lib/python3.13/site-packages/setuptools/_vendor/autocommand-2.2.2.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-02-21 11:30 squashfs-root/usr/lib/python3.13/site-packages/setuptools/_vendor/backports.tarfile-1.2.0.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-02-21 11:30 squashfs-root/usr/lib/python3.13/site-packages/setuptools/_vendor/importlib_metadata-8.0.0.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-02-21 11:30 squashfs-root/usr/lib/python3.13/site-packages/setuptools/_vendor/inflect-7.3.1.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-02-21 11:30 squashfs-root/usr/lib/python3.13/site-packages/setuptools/_vendor/jaraco.collections-5.1.0.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-02-21 11:30 squashfs-root/usr/lib/python3.13/site-packages/setuptools/_vendor/jaraco.context-5.3.0.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-02-21 11:30 squashfs-root/usr/lib/python3.13/site-packages/setuptools/_vendor/jaraco.functools-4.0.1.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-02-21 11:30 squashfs-root/usr/lib/python3.13/site-packages/setuptools/_vendor/jaraco.text-3.12.1.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-02-21 11:30 squashfs-root/usr/lib/python3.13/site-packages/setuptools/_vendor/more_itertools-10.3.0.dist-info/INSTALLER
-rw-r--r-- root/root                 2 2026-02-21 11:30 squashfs-root/usr/lib/python3.13/site-packages/setuptools/_vendor/packaging-24.2.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-02-21 11:30 squashfs-root/usr/lib/python3.13/site-packages/setuptools/_vendor/platformdirs-4.2.2.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-02-21 11:30 squashfs-root/usr/lib/python3.13/site-packages/setuptools/_vendor/tomli-2.0.1.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-02-21 11:30 squashfs-root/usr/lib/python3.13/site-packages/setuptools/_vendor/typeguard-4.3.0.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-02-21 11:30 squashfs-root/usr/lib/python3.13/site-packages/setuptools/_vendor/typing_extensions-4.12.2.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-02-21 11:30 squashfs-root/usr/lib/python3.13/site-packages/setuptools/_vendor/wheel-0.45.1.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-02-21 11:30 squashfs-root/usr/lib/python3.13/site-packages/setuptools/_vendor/zipp-3.19.2.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-02-21 11:30 squashfs-root/usr/lib/python3.13/site-packages/setuptools-80.9.0.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-10 12:36 squashfs-root/usr/lib/python3.13/site-packages/sherlock_project-0.16.0.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-10 12:41 squashfs-root/usr/lib/python3.13/site-packages/shodan-1.31.0.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-08 18:53 squashfs-root/usr/lib/python3.13/site-packages/six-1.17.0.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-10 12:41 squashfs-root/usr/lib/python3.13/site-packages/slowapi-0.1.9.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-08 18:53 squashfs-root/usr/lib/python3.13/site-packages/sortedcontainers-2.4.0.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-10 12:41 squashfs-root/usr/lib/python3.13/site-packages/soupsieve-2.8.3.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-09 20:44 squashfs-root/usr/lib/python3.13/site-packages/stack_data-0.6.3.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-10 12:41 squashfs-root/usr/lib/python3.13/site-packages/starlette-0.52.1.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-10 12:36 squashfs-root/usr/lib/python3.13/site-packages/stem-1.8.2.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-09 20:44 squashfs-root/usr/lib/python3.13/site-packages/tabulate-0.9.0.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-10 12:41 squashfs-root/usr/lib/python3.13/site-packages/tldextract-5.3.1.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-09 20:44 squashfs-root/usr/lib/python3.13/site-packages/toml-0.10.2.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-09 20:44 squashfs-root/usr/lib/python3.13/site-packages/tqdm-4.67.3.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-09 20:44 squashfs-root/usr/lib/python3.13/site-packages/traitlets-5.14.3.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-09 20:44 squashfs-root/usr/lib/python3.13/site-packages/typing_extensions-4.15.0.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-10 12:41 squashfs-root/usr/lib/python3.13/site-packages/typing_inspection-0.4.2.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-10 12:36 squashfs-root/usr/lib/python3.13/site-packages/tzdata-2025.3.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-10 12:41 squashfs-root/usr/lib/python3.13/site-packages/ujson-5.11.0.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-10 12:37 squashfs-root/usr/lib/python3.13/site-packages/unicodecsv-0.14.1.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-09 20:44 squashfs-root/usr/lib/python3.13/site-packages/unicorn-2.1.4.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-08 18:53 squashfs-root/usr/lib/python3.13/site-packages/unix_ar-0.2.1.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-08 18:53 squashfs-root/usr/lib/python3.13/site-packages/urllib3-2.6.3.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-10 13:05 squashfs-root/usr/lib/python3.13/site-packages/userpath-1.9.2.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-08 19:12 squashfs-root/usr/lib/python3.13/site-packages/uv-0.10.9.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-10 12:41 squashfs-root/usr/lib/python3.13/site-packages/uvicorn-0.41.0.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-10 12:41 squashfs-root/usr/lib/python3.13/site-packages/uvloop-0.22.1.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-09 22:54 squashfs-root/usr/lib/python3.13/site-packages/virtualenv-21.2.0.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-09 20:44 squashfs-root/usr/lib/python3.13/site-packages/wcwidth-0.6.0.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-10 12:37 squashfs-root/usr/lib/python3.13/site-packages/webencodings-0.5.1.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-10 12:37 squashfs-root/usr/lib/python3.13/site-packages/werkzeug-3.1.6.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-02-21 11:30 squashfs-root/usr/lib/python3.13/site-packages/wheel-0.46.1.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-10 12:41 squashfs-root/usr/lib/python3.13/site-packages/wrapt-2.1.2.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-10 12:37 squashfs-root/usr/lib/python3.13/site-packages/xlsxwriter-3.2.9.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-10 12:41 squashfs-root/usr/lib/python3.13/site-packages/yarl-1.23.0.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-09 20:44 squashfs-root/usr/lib/python3.13/site-packages/ziglang-0.14.1.dist-info/INSTALLER
-rw-r--r-- root/root                 4 2026-03-08 18:53 squashfs-root/usr/lib/python3.13/site-packages/zstandard-0.25.0.dist-info/INSTALLER
drwxr-xr-x root/root                89 2026-03-08 20:36 squashfs-root/usr/lib/ruby/3.3.0/bundler/installer
drwxr-xr-x root/root                63 2026-03-08 20:36 squashfs-root/usr/lib/ruby/3.3.0/bundler/plugin/installer
drwxr-xr-x root/root              1295 2026-04-08 16:49 squashfs-root/usr/lib/ruby/gems/3.3.0/doc/rubygems-4.0.10/ri/Gem/Installer
-rwxr-xr-x pepper/pepper          2512 2026-03-08 21:17 squashfs-root/usr/lib/ruby/gems/3.3.0/gems/ffi-1.16.3/ext/ffi_c/libffi/.ci/install.sh
-rwxr-xr-x pepper/pepper         15358 2026-03-08 21:17 squashfs-root/usr/lib/ruby/gems/3.3.0/gems/ffi-1.16.3/ext/ffi_c/libffi/install-sh
drwxr-xr-x root/root                89 2026-04-08 16:49 squashfs-root/usr/lib/ruby/gems/3.3.0/gems/rubygems-update-4.0.10/bundler/lib/bundler/installer
drwxr-xr-x root/root                63 2026-04-08 16:49 squashfs-root/usr/lib/ruby/gems/3.3.0/gems/rubygems-update-4.0.10/bundler/lib/bundler/plugin/installer
drwxr-xr-x pepper/pepper            48 2026-03-08 21:17 squashfs-root/usr/lib/ruby/gems/3.3.0/gems/yard-0.9.37/templates/default/root/dot
-rw-r--r-- pepper/pepper            91 2026-03-08 21:17 squashfs-root/usr/lib/ruby/gems/3.3.0/gems/yard-0.9.37/templates/default/root/dot/child.erb
-rw-r--r-- pepper/pepper            97 2026-03-08 21:17 squashfs-root/usr/lib/ruby/gems/3.3.0/gems/yard-0.9.37/templates/default/root/dot/setup.rb
drwxr-xr-x pepper/pepper            31 2026-03-08 21:17 squashfs-root/usr/lib/ruby/gems/3.3.0/gems/yard-0.9.37/templates/default/root/html
-rw-r--r-- pepper/pepper            63 2026-03-08 21:17 squashfs-root/usr/lib/ruby/gems/3.3.0/gems/yard-0.9.37/templates/default/root/html/setup.rb
drwxr-xr-x root/root                89 2026-04-08 16:49 squashfs-root/usr/lib/ruby/site_ruby/3.3.0/bundler/installer
drwxr-xr-x root/root                63 2026-04-08 16:49 squashfs-root/usr/lib/ruby/site_ruby/3.3.0/bundler/plugin/installer
-rwxr-xr-x root/root              1664 2026-04-08 17:42 squashfs-root/usr/local/bin/afl-addseeds
-rwxr-xr-x root/root            298920 2026-04-08 17:42 squashfs-root/usr/local/bin/afl-analyze
lrwxrwxrwx root/root                 6 2026-04-08 17:42 squashfs-root/usr/local/bin/afl-c++ -> afl-cc
-rwxr-xr-x root/root            236040 2026-04-08 17:42 squashfs-root/usr/local/bin/afl-cc
lrwxrwxrwx root/root                 6 2026-04-08 17:42 squashfs-root/usr/local/bin/afl-clang -> afl-cc
lrwxrwxrwx root/root                 6 2026-04-08 17:42 squashfs-root/usr/local/bin/afl-clang++ -> afl-cc
lrwxrwxrwx root/root                 6 2026-04-08 17:42 squashfs-root/usr/local/bin/afl-clang-fast -> afl-cc
lrwxrwxrwx root/root                 9 2026-04-08 17:42 squashfs-root/usr/local/bin/afl-clang-fast++ -> ./afl-c++
-rwxr-xr-x root/root             30585 2026-04-08 17:42 squashfs-root/usr/local/bin/afl-cmin
-rwxr-xr-x root/root             22435 2026-04-08 17:42 squashfs-root/usr/local/bin/afl-cmin.awk
-rwxr-xr-x root/root             15808 2026-04-08 17:42 squashfs-root/usr/local/bin/afl-cmin.bash
-rwxr-xr-x root/root             30585 2026-04-08 17:42 squashfs-root/usr/local/bin/afl-cmin.py
-rwxr-xr-x root/root           1838496 2026-04-08 17:42 squashfs-root/usr/local/bin/afl-fuzz
lrwxrwxrwx root/root                 6 2026-04-08 17:42 squashfs-root/usr/local/bin/afl-g++ -> afl-cc
lrwxrwxrwx root/root                 7 2026-04-08 17:42 squashfs-root/usr/local/bin/afl-g++-fast -> afl-c++
lrwxrwxrwx root/root                 6 2026-04-08 17:42 squashfs-root/usr/local/bin/afl-gcc -> afl-cc
lrwxrwxrwx root/root                 6 2026-04-08 17:42 squashfs-root/usr/local/bin/afl-gcc-fast -> afl-cc
-rwxr-xr-x root/root             47912 2026-04-08 17:42 squashfs-root/usr/local/bin/afl-gotcpu
-rwxr-xr-x root/root              4889 2026-04-08 17:42 squashfs-root/usr/local/bin/afl-persistent-config
-rwxr-xr-x root/root             13412 2026-04-08 17:42 squashfs-root/usr/local/bin/afl-plot
-rwxr-xr-x root/root            464424 2026-04-08 17:42 squashfs-root/usr/local/bin/afl-showmap
-rwxr-xr-x root/root              6067 2026-04-08 17:42 squashfs-root/usr/local/bin/afl-system-config
-rwxr-xr-x root/root            399640 2026-04-08 17:42 squashfs-root/usr/local/bin/afl-tmin
-rwxr-xr-x root/root             11608 2026-04-08 17:42 squashfs-root/usr/local/bin/afl-whatsup
-rwxr-xr-x root/root           4546872 2026-03-09 20:53 squashfs-root/usr/local/bin/binwalk
-rwxr-xr-x root/root             20382 2026-03-09 20:58 squashfs-root/usr/local/bin/clang-format-radare2
-rwxr-xr-x root/root               128 2026-04-08 18:15 squashfs-root/usr/local/bin/commix
-rwxr-xr-x root/root            651361 2026-04-24 10:32 squashfs-root/usr/local/bin/convert_hf_to_gguf.py
-rwxr-xr-x root/root               458 2026-04-08 17:37 squashfs-root/usr/local/bin/decompile
-rwxr-xr-x root/root              1727 2026-04-24 12:24 squashfs-root/usr/local/bin/ds
-rwxr-xr-x root/root            239456 2026-04-24 11:31 squashfs-root/usr/local/bin/export-graph-ops
lrwxrwxrwx root/root                20 2026-03-07 14:58 squashfs-root/usr/local/bin/firefox -> /opt/firefox/firefox
lrwxrwxrwx root/root                35 2026-03-09 21:06 squashfs-root/usr/local/bin/ghidra -> /opt/ghidra_12.0.4_PUBLIC/ghidraRun
lrwxrwxrwx root/root                49 2026-04-08 17:33 squashfs-root/usr/local/bin/ghidra-headless -> /opt/ghidra_12.0.4_PUBLIC/support/analyzeHeadless
-rwxr-xr-x root/root           6649016 2026-04-08 17:52 squashfs-root/usr/local/bin/hfuzz-cc
-rwxr-xr-x root/root           6628560 2026-04-08 17:52 squashfs-root/usr/local/bin/honggfuzz
lrwxrwxrwx root/root                20 2026-03-09 21:05 squashfs-root/usr/local/bin/java -> /opt/jdk-21/bin/java
lrwxrwxrwx root/root                21 2026-03-09 21:05 squashfs-root/usr/local/bin/javac -> /opt/jdk-21/bin/javac
-rwxr-xr-x root/root             44544 2026-04-24 11:31 squashfs-root/usr/local/bin/llama-batched
-rwxr-xr-x root/root             47992 2026-04-24 11:31 squashfs-root/usr/local/bin/llama-batched-bench
-rwxr-xr-x root/root            425816 2026-04-24 11:31 squashfs-root/usr/local/bin/llama-bench
-rwxr-xr-x root/root           1696368 2026-04-24 11:31 squashfs-root/usr/local/bin/llama-cli
-rwxr-xr-x root/root             98048 2026-04-24 11:31 squashfs-root/usr/local/bin/llama-completion
-rwxr-xr-x root/root             72920 2026-04-24 11:31 squashfs-root/usr/local/bin/llama-convert-llama2c-to-ggml
-rwxr-xr-x root/root             88408 2026-04-24 11:31 squashfs-root/usr/local/bin/llama-cvector-generator
-rwxr-xr-x root/root            247120 2026-04-24 11:31 squashfs-root/usr/local/bin/llama-debug
-rwxr-xr-x root/root            199712 2026-04-24 11:31 squashfs-root/usr/local/bin/llama-debug-template-parser
-rwxr-xr-x root/root             75688 2026-04-24 11:31 squashfs-root/usr/local/bin/llama-diffusion-cli
-rwxr-xr-x root/root             67464 2026-04-24 11:31 squashfs-root/usr/local/bin/llama-embedding
-rwxr-xr-x root/root             38992 2026-04-24 11:31 squashfs-root/usr/local/bin/llama-eval-callback
-rwxr-xr-x root/root             88464 2026-04-24 11:31 squashfs-root/usr/local/bin/llama-export-lora
-rwxr-xr-x root/root             39440 2026-04-24 11:31 squashfs-root/usr/local/bin/llama-finetune
-rwxr-xr-x root/root             38624 2026-04-24 11:31 squashfs-root/usr/local/bin/llama-fit-params
-rwxr-xr-x root/root             63224 2026-04-24 11:31 squashfs-root/usr/local/bin/llama-gen-docs
-rwxr-xr-x root/root             23458 2026-04-24 11:17 squashfs-root/usr/local/bin/llama-gguf
-rwxr-xr-x root/root            101202 2026-04-24 11:17 squashfs-root/usr/local/bin/llama-gguf-hash
-rwxr-xr-x root/root             51432 2026-04-24 11:31 squashfs-root/usr/local/bin/llama-gguf-split
-rwxr-xr-x root/root             39136 2026-04-24 11:31 squashfs-root/usr/local/bin/llama-idle
-rwxr-xr-x root/root            349984 2026-04-24 11:31 squashfs-root/usr/local/bin/llama-imatrix
-rwxr-xr-x root/root             53248 2026-04-24 11:31 squashfs-root/usr/local/bin/llama-lookahead
-rwxr-xr-x root/root             54784 2026-04-24 11:31 squashfs-root/usr/local/bin/llama-lookup
-rwxr-xr-x root/root             39520 2026-04-24 11:31 squashfs-root/usr/local/bin/llama-lookup-create
-rwxr-xr-x root/root             25272 2026-04-24 11:31 squashfs-root/usr/local/bin/llama-lookup-merge
-rwxr-xr-x root/root             44840 2026-04-24 11:31 squashfs-root/usr/local/bin/llama-lookup-stats
-rwxr-xr-x root/root             76904 2026-04-24 11:31 squashfs-root/usr/local/bin/llama-mtmd-cli
-rwxr-xr-x root/root             67760 2026-04-24 11:31 squashfs-root/usr/local/bin/llama-parallel
-rwxr-xr-x root/root             53360 2026-04-24 11:31 squashfs-root/usr/local/bin/llama-passkey
-rwxr-xr-x root/root            154664 2026-04-24 11:31 squashfs-root/usr/local/bin/llama-perplexity
-rwxr-xr-x root/root            100224 2026-04-24 11:31 squashfs-root/usr/local/bin/llama-quantize

## Kernel/initramfs/squashfs hashes
5eb229eb986e5c21804196db31f4f524a361d19ef50b7d3e78119cb24e647a55  /mnt/inspect-usb1/root/boot/vmlinuz
fa5de4943877224ea4916235dbfa4eb0a73ba166b56a51418404d4cc0f9d08c2  /mnt/inspect-usb1/root/boot/initramfs-live.img
903f57e8978c2e1f7036e970650ffd39cd943ca56a5ccef1a5b72029241e25b2  /mnt/inspect-usb1/root/live/filesystem.squashfs
