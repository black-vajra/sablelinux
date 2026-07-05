# EliteBook Targeted Boot / Waybar Capture — 2026-07-02

Thu Jul  2 12:07:26 EDT 2026

## Identity
vulfen
sable
Linux vulfen 6.16.1-sable-compat2 #13 SMP PREEMPT_DYNAMIC Mon Jun  1 22:17:27 EDT 2026 x86_64 GNU/Linux
NAME="SableLinux"
PRETTY_NAME="Sable Linux 1.0"
ID=sablelinux
VERSION="1.0"
VERSION_ID="1.0"
HOME_URL="https://sablelinux.dev"
BUG_REPORT_URL="https://github.com/black-vajra/sablelinux/issues"
ANSI_COLOR="1;30"

## Kernel command line
BOOT_IMAGE=/vmlinuz-6.16.1-sable-compat2 root=UUID=97b76a3c-825a-4012-aa83-90c7e58e5dc2 ro

## Boot files
2026-05-10 12:20 15610880 /boot/vmlinuz-6.16.1-lfs-12.4-systemd
2026-05-10 12:20 25944406 /boot/initrd.img-6.16.1-lfs-12.4-systemd
2026-05-24 23:04 14119936 /boot/vmlinuz-6.16.1-sable-compat
2026-05-24 23:04 29514696 /boot/initramfs-6.16.1-sable-compat.img
2026-05-31 00:04 15811584 /boot/vmlinuz-6.16.1-sable-compat2.bak-0601
2026-05-31 00:05 35852899 /boot/initramfs-6.16.1-sable-compat2.img.bak-0601
2026-05-31 00:54 6337 /boot/grub/grub.cfg
2026-05-31 00:55 1024 /boot/grub/grubenv
2026-06-01 22:33 15983616 /boot/vmlinuz-6.16.1-sable-compat2
2026-06-01 22:34 35887984 /boot/initramfs-6.16.1-sable-compat2.img

## Boot file hashes
a7a5a467034c4ace3d2ff00f584487654f3308df454a0fa5277c7c0a7a59d3f6  /boot/vmlinuz-6.16.1-lfs-12.4-systemd
5eb229eb986e5c21804196db31f4f524a361d19ef50b7d3e78119cb24e647a55  /boot/vmlinuz-6.16.1-sable-compat
a1582514ef786631e0e15f2f0fea0002fa6d458cf3e3c620bd66875d1d8a45ba  /boot/vmlinuz-6.16.1-sable-compat2
3cbbed3825cbd3f20345e9ae5a9d86cc927f4c4df1c952536650e2955e6eb447  /boot/vmlinuz-6.16.1-sable-compat2.bak-0601
dc04fa71ae818dbf9f7063b82d97374ccdf55ec73f8535151c8f1049caf38042  /boot/initramfs-6.16.1-sable-compat.img
ebb507af8a3fe95afbc83e422f1743cd508cc8f9fc206b19a9498af4a70c7d9a  /boot/initrd.img-6.16.1-lfs-12.4-systemd

## GRUB config
missing

## PAM / limits

--- /etc/pam.d/system-auth ---
auth      required    pam_unix.so nullok
account   required    pam_unix.so
password  required    pam_unix.so shadow sha512
session   required    pam_unix.so

--- /etc/pam.d/system-session ---
# Begin /etc/pam.d/system-session
session required pam_env.so readenv=1
session required pam_unix.so
# End /etc/pam.d/system-session
# Begin Systemd addition
session required pam_loginuid.so
session optional pam_systemd.so
# End Systemd addition

--- /etc/security/limits.conf ---
missing

--- /etc/security/limits.d/99-filedesc.conf ---
missing

ulimit -n: 1024

## Sway / Waybar process state
766 sway
801 swaybg -o * -i /home/sable/.config/sway/wallpapers/sable-wallpaper.png -m fill
815 swayidle -w timeout 300 swaylock -f -c 000000 before-sleep swaylock -f -c 000000
1131 swaylock -f -c 000000
1132 swaylock -f -c 000000
809 waybar -b bar-0
763 /usr/bin/pipewire
764 /usr/bin/pipewire-pulse
765 /usr/bin/wireplumber

## Waybar process limits

--- /proc/809/limits ---
Limit                     Soft Limit           Hard Limit           Units     
Max cpu time              unlimited            unlimited            seconds   
Max file size             unlimited            unlimited            bytes     
Max data size             unlimited            unlimited            bytes     
Max stack size            8388608              unlimited            bytes     
Max core file size        unlimited            unlimited            bytes     
Max resident set          unlimited            unlimited            bytes     
Max processes             60630                60630                processes 
Max open files            1024                 524288               files     
Max locked memory         8388608              8388608              bytes     
Max address space         unlimited            unlimited            bytes     
Max file locks            unlimited            unlimited            locks     
Max pending signals       60630                60630                signals   
Max msgqueue size         819200               819200               bytes     
Max nice priority         0                    0                    
Max realtime priority     0                    0                    
Max realtime timeout      unlimited            unlimited            us        

## Sway config
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
exec_always export WLR_DRM_DEVICES=/dev/dri/card1
xwayland enable

### Output
output * bg $HOME/.config/sway/wallpapers/sable-wallpaper.png fill

### Autostart
exec mako
exec swayidle -w \
    timeout 300 'swaylock -f -c 000000' \
    before-sleep 'swaylock -f -c 000000'

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

bindsym $mod+Shift+x exec swaylock -f -c 000000

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

## Waybar config files
2026-05-25 10:14 6554 /etc/xdg/waybar/config.jsonc
2026-05-25 10:18 5319 /etc/xdg/waybar/style.css

--- /home/sable/.config/waybar/config ---
missing

--- /home/sable/.config/waybar/config.jsonc ---
missing

--- /home/sable/.config/waybar/style.css ---
missing

--- /etc/xdg/waybar/config ---
missing

--- /etc/xdg/waybar/config.jsonc ---
// -*- mode: jsonc -*-
{
    // "layer": "top", // Waybar at top layer
    // "position": "bottom", // Waybar position (top|bottom|left|right)
    "height": 30, // Waybar height (to be removed for auto height)
    // "width": 1280, // Waybar width
    "spacing": 4, // Gaps between modules (4px)
    // Choose the order of the modules
    "modules-left": [
        "sway/workspaces",
        "sway/mode",
        "sway/scratchpad",
        "custom/media"
    ],
    "modules-center": [
        "sway/window"
    ],
    "modules-right": [
        "mpd",
        "idle_inhibitor",
        "pulseaudio",
        "network",
        "power-profiles-daemon",
        "cpu",
        "memory",
        "temperature",
        "backlight",
        "keyboard-state",
        "sway/language",
        "battery",
        "clock",
        "tray",
        "custom/power"
    ],
    // Modules configuration
    // "sway/workspaces": {
    //     "disable-scroll": true,
    //     "all-outputs": true,
    //     "warp-on-scroll": false,
    //     "format": "{name}: {icon}",
    //     "format-icons": {
    //         "1": "",
    //         "2": "",
    //         "3": "",
    //         "4": "",
    //         "5": "",
    //         "urgent": "",
    //         "focused": "",
    //         "default": ""
    //     }
    // },
    "keyboard-state": {
        "numlock": true,
        "capslock": true,
        "format": "{name} {icon}",
        "format-icons": {
            "locked": "",
            "unlocked": ""
        }
    },
    "sway/mode": {
        "format": "<span style=\"italic\">{}</span>"
    },
    "sway/scratchpad": {
        "format": "{icon} {count}",
        "show-empty": false,
        "format-icons": ["", ""],
        "tooltip": true,
        "tooltip-format": "{app}: {title}"
    },
    "mpd": {
        "format": "{stateIcon} {consumeIcon}{randomIcon}{repeatIcon}{singleIcon}{artist} - {album} - {title} ({elapsedTime:%M:%S}/{totalTime:%M:%S}) ⸨{songPosition}|{queueLength}⸩ {volume}% ",
        "format-disconnected": "Disconnected ",
        "format-stopped": "{consumeIcon}{randomIcon}{repeatIcon}{singleIcon}Stopped ",
        "unknown-tag": "N/A",
        "interval": 5,
        "consume-icons": {
            "on": " "
        },
        "random-icons": {
            "off": "<span color=\"#f53c3c\"></span> ",
            "on": " "
        },
        "repeat-icons": {
            "on": " "
        },
        "single-icons": {
            "on": "1 "
        },
        "state-icons": {
            "paused": "",
            "playing": ""
        },
        "tooltip-format": "MPD (connected)",
        "tooltip-format-disconnected": "MPD (disconnected)"
    },
    "idle_inhibitor": {
        "format": "{icon}",
        "format-icons": {
            "activated": "",
            "deactivated": ""
        }
    },
    "tray": {
        // "icon-size": 21,
        "spacing": 10
    },
    "clock": {
        // "timezone": "America/New_York",
        "tooltip-format": "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>",
        "format-alt": "{:%Y-%m-%d}"
    },
    "cpu": {
        "format": "{usage}% ",
        "tooltip": false
    },
    "memory": {
        "format": "{}% "
    },
    "temperature": {
        // "thermal-zone": 2,
        // "hwmon-path": "/sys/class/hwmon/hwmon2/temp1_input",
        "critical-threshold": 80,
        // "format-critical": "{temperatureC}°C {icon}",
        "format": "{temperatureC}°C {icon}",
        "format-icons": ["", "", ""]
    },
    "backlight": {
        "device": "amdgpu_bl0",
        "format": "{percent}% {icon}",
        "format-icons": ["", "", "", "", "", "", "", "", ""]
    },
    "battery": {
        "states": {
            // "good": 95,
            "warning": 30,
            "critical": 15
        },
        "format": "{capacity}% {icon}",
        "format-full": "{capacity}% {icon}",
        "format-charging": "{capacity}% ",
        "format-plugged": "{capacity}% ",
        "format-alt": "{time} {icon}",
        // "format-good": "", // An empty format will hide the module
        // "format-full": "",
        "format-icons": ["", "", "", "", ""]
    },
    "battery#bat2": {
        "bat": "BAT0"
    },
    "power-profiles-daemon": {
      "format": "{icon}",
      "tooltip-format": "Power profile: {profile}\nDriver: {driver}",
      "tooltip": true,
      "format-icons": {
        "default": "",
        "performance": "",
        "balanced": "",
        "power-saver": ""
      }
    },
    "network": {
        // "interface": "wlp2*", // (Optional) To force the use of this interface
        "format-wifi": "{essid} ({signalStrength}%) ",
        "format-ethernet": "{ipaddr}/{cidr} ",
        "tooltip-format": "{ifname} via {gwaddr} ",
        "format-linked": "{ifname} (No IP) ",
        "format-disconnected": "Disconnected ⚠",
        "format-alt": "{ifname}: {ipaddr}/{cidr}"
    },
    "pulseaudio": {
        // "scroll-step": 1, // %, can be a float
        "format": "{volume}% {icon} {format_source}",
        "format-bluetooth": "{volume}% {icon} {format_source}",
        "format-bluetooth-muted": " {icon} {format_source}",
        "format-muted": " {format_source}",
        "format-source": "{volume}% ",
        "format-source-muted": "",
        "format-icons": {
            "headphone": "",
            "hands-free": "",
            "headset": "",
            "phone": "",
            "portable": "",
            "car": "",
            "default": ["", "", ""]
        },
        "on-click": "pavucontrol"
    },
    "custom/media": {
        "format": "{icon} {}",
        "return-type": "json",
        "max-length": 40,
        "format-icons": {
            "spotify": "",
            "default": "🎜"
        },
        "escape": true,
        "exec": "$HOME/.config/waybar/mediaplayer.py 2> /dev/null" // Script in resources folder
        // "exec": "$HOME/.config/waybar/mediaplayer.py --player spotify 2> /dev/null" // Filter player based on name
    },
    "custom/power": {
        "format" : "⏻ ",
		"tooltip": false,
		"menu": "on-click",
		"menu-file": "$HOME/.config/waybar/power_menu.xml", // Menu file in resources folder
		"menu-actions": {
			"shutdown": "shutdown",
			"reboot": "reboot",
			"suspend": "systemctl suspend",
			"hibernate": "systemctl hibernate"
		}
    }
}

--- /etc/xdg/waybar/style.css ---
* {
    /* `otf-font-awesome` is required to be installed for icons */
    font-family: FontAwesome, Roboto, Helvetica, Arial, sans-serif;
    font-size: 13px;
}

window#waybar {
    background-color: rgba(43, 48, 59, 0.5);
    border-bottom: 3px solid rgba(100, 114, 125, 0.5);
    color: #ffffff;
    transition-property: background-color;
    transition-duration: .5s;
}

window#waybar.hidden {
    opacity: 0.2;
}

/*
window#waybar.empty {
    background-color: transparent;
}
window#waybar.solo {
    background-color: #FFFFFF;
}
*/

window#waybar.termite {
    background-color: #3F3F3F;
}

window#waybar.chromium {
    background-color: #000000;
    border: none;
}

button {
    /* Use box-shadow instead of border so the text isn't offset */
    box-shadow: inset 0 -3px transparent;
    /* Avoid rounded borders under each button name */
    border: none;
    border-radius: 0;
}

/* https://github.com/Alexays/Waybar/wiki/FAQ#the-workspace-buttons-have-a-strange-hover-effect */
button:hover {
    background: inherit;
    box-shadow: inset 0 -3px #ffffff;
}

/* you can set a style on hover for any module like this */
#pulseaudio:hover {
    background-color: #a37800;
}

#workspaces button {
    padding: 0 5px;
    background-color: transparent;
    color: #ffffff;
}

#workspaces button:hover {
    background: rgba(0, 0, 0, 0.2);
}

#workspaces button.focused {
    background-color: #64727D;
    box-shadow: inset 0 -3px #ffffff;
}

#workspaces button.urgent {
    background-color: #eb4d4b;
}

#mode {
    background-color: #64727D;
    box-shadow: inset 0 -3px #ffffff;
}

#clock,
#battery,
#cpu,
#memory,
#disk,
#temperature,
#backlight,
#network,
#pulseaudio,
#wireplumber,
#custom-media,
#tray,
#mode,
#idle_inhibitor,
#scratchpad,
#power-profiles-daemon,
#mpd {
    padding: 0 10px;
    color: #ffffff;
}

#window,
#workspaces {
    margin: 0 4px;
}

/* If workspaces is the leftmost module, omit left margin */
.modules-left > widget:first-child > #workspaces {
    margin-left: 0;
}

/* If workspaces is the rightmost module, omit right margin */
.modules-right > widget:last-child > #workspaces {
    margin-right: 0;
}

#clock {
    background-color: #64727D;
}

#battery {
    background-color: #ffffff;
    color: #000000;
}

#battery.charging, #battery.plugged {
    color: #ffffff;
    background-color: #26A65B;
}

@keyframes blink {
    to {
        background-color: #ffffff;
        color: #000000;
    }
}

/* Using steps() instead of linear as a timing function to limit cpu usage */
#battery.critical:not(.charging) {
    background-color: #f53c3c;
    color: #ffffff;
    animation-name: blink;
    animation-duration: 0.5s;
    animation-timing-function: steps(12);
    animation-iteration-count: infinite;
    animation-direction: alternate;
}

#power-profiles-daemon {
    padding-right: 15px;
}

#power-profiles-daemon.performance {
    background-color: #f53c3c;
    color: #ffffff;
}

#power-profiles-daemon.balanced {
    background-color: #2980b9;
    color: #ffffff;
}

#power-profiles-daemon.power-saver {
    background-color: #2ecc71;
    color: #000000;
}

label:focus {
    background-color: #000000;
}

#cpu {
    background-color: #2ecc71;
    color: #000000;
}

#memory {
    background-color: #9b59b6;
}

#disk {
    background-color: #964B00;
}

#backlight {
    background-color: #90b1b1;
}

#network {
    background-color: #2980b9;
}

#network.disconnected {
    background-color: #f53c3c;
}

#pulseaudio {
    background-color: #f1c40f;
    color: #000000;
}

#pulseaudio.muted {
    background-color: #90b1b1;
    color: #2a5c45;
}

#wireplumber {
    background-color: #fff0f5;
    color: #000000;
}

#wireplumber.muted {
    background-color: #f53c3c;
}

#custom-media {
    background-color: #66cc99;
    color: #2a5c45;
    min-width: 100px;
}


## User journal Waybar/Sway clues
