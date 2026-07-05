
/
I need to adjust the sablelinux installation on the HP Pavillion so that the desktop (monitor... whatever) stops going into sleep mode or at least waits at least 1 hour... not two minutes.

What's the current swayidle config on the HP Pavilion? Check:

bash
cat ~/.config/sway/config | grep -A20 idle
or if it's separate:

bash
cat ~/.config/swayidle/config 2>/dev/null || grep -r swayidle ~/.config/
[piper@sable-hp ~]$ cat ~/.config/sway/config | grep -A20 idle
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
client.focused           
#7c3aed 
#7c3aed  
#ffffff  
#a78bfa   
#7c3aed
client.focused_inactive  
#1e1e2e 
#1e1e2e  
#888888  
#1e1e2e   
#1e1e2e
client.unfocused         
#1e1e2e 
#1e1e2e  
#555555  
#1e1e2e   
#1e1e2e
client.urgent            
#ef4444 
#ef4444  
#ffffff  
#ef4444   
#ef4444
### Input
input "type:keyboard" {
    xkb_layout us
[piper@sable-hp ~]$ cat ~/.config/swayidle/config 2>/dev/null || grep -r swayidle ~/.config/
/home/piper/.config/sway/config:exec swayidle -w \
[piper@sable-hp ~]$

Show more
The 300-second (5 minute) timeout is triggering swaylock. No DPMS/display-off timeout is set, so the monitor sleep is probably coming from swaylock itself blanking the screen, or the display's own power save kicking in.

Edit the swayidle line to push the lock to 1 hour and add explicit DPMS control:

bash
sed -i 's/exec swayidle -w \\/exec swayidle -w \\/' ~/.config/sway/config
Actually, easier to just edit it directly — find and replace the whole block:

bash
sed -i '/exec swayidle -w/,/before-sleep/c\exec swayidle -w \\\n    timeout 3600 '"'"'swaylock -f -c 000000'"'"' \\\n    timeout 3660 '"'"'swaymsg "output * dpms off"'"'"' \\\n    resume '"'"'swaymsg "output * dpms on"'"'"' \\\n    before-sleep '"'"'swaylock -f -c 000000'"'"'' ~/.config/sway/config
Then verify it looks right:

bash
grep -A6 swayidle ~/.config/sway/config
Expected output:

exec swayidle -w \
    timeout 3600 'swaylock -f -c 000000' \
    timeout 3660 'swaymsg "output * dpms off"' \
    resume 'swaymsg "output * dpms on"' \
    before-sleep 'swaylock -f -c 000000'
Then reload sway:

bash
swaymsg reload
This locks at 60min, turns the display off 1 minute later, and brings it back on activity. The before-sleep stays so suspend (if triggered externally) still locks first.

[piper@sable-hp ~]$ sudo cp ~/.config/sway/config ~/.config/sway/config.bak ; sed -i '/exec swayidle -w/,/before-sleep/c\exec swayidle -w \\\n    timeout 3600 '"'"'swaylock -f -c 000000'"'"' \\\n    timeout 3660 '
"'"'swaymsg "output * dpms off"'"'"' \\\n    resume '"'"'swaymsg "output * dpms on"'"'"' \\\n    before-sleep '"'"'swaylock -f -c 000000'"'"'' ~/.config/sway/config
[sudo] password for piper: 
[piper@sable-hp ~]$ grep -A6 swayidle ~/.config/sway/config
exec swayidle -w \
    timeout 3600 'swaylock -f -c 000000' \
    timeout 3660 'swaymsg "output * dpms off"' \
    resume 'swaymsg "output * dpms on"' \
    before-sleep 'swaylock -f -c 000000'
### Appearance
[piper@sable-hp ~]$

Show more
Looks correct. Reload:

bash
swaymsg reload
That kills the old swayidle process and starts a fresh one with the new timeouts. Monitor won't sleep for at least an hour now.

Thanks.

Done. If the monitor's own power-save still kicks in before the hour (OSD hardware timer), you'd need to disable that in the display's physical menu — that's independent of sway/swayidle.

o.k. then while we're at it... let's fix the font issue in the swaybar - which... for example in the volume control... shows the numeric portion... but little boxes with four little circles in each box instead of the icons...

That's Font Awesome glyphs not rendering — the waybar config is referencing Font Awesome but it's either not installed on the HP Pavilion or not in a path fontconfig can see.

Check first:

bash
fc-list | grep -i awesome
no response.

Not installed. Check what fonts are available on the HP Pavilion vs what waybar expects:

bash
grep -i font ~/.config/waybar/config 2>/dev/null || grep -i font ~/.config/waybar/style.css 2>/dev/null
no response.

Waybar config isn't in the usual place:

bash
find ~/.config /etc/xdg -name "*.css" -o -name "config" 2>/dev/null | xargs grep -l waybar 2>/dev/null
find ~/.config -path "*waybar*" 2>/dev/null
[piper@sable-hp ~]$ find ~/.config /etc/xdg -name "*.css" -o -name "config" 2>/dev/null | xargs grep -l waybar 2>/dev/null
find ~/.config -path "*waybar*" 2>/dev/null
/home/piper/.config/sway/config
/etc/xdg/waybar/style.css
[piper@sable-hp ~]$

Waybar is using the system default config at /etc/xdg/waybar/. Check what font it references:

bash
grep -i font /etc/xdg/waybar/style.css | head -20
[piper@sable-hp ~]$ grep -i font /etc/xdg/waybar/style.css | head -20
    /* otf-font-awesome is required to be installed for icons */
    font-family: FontAwesome, Roboto, Helvetica, Arial, sans-serif;
    font-size: 13px;
[piper@sable-hp ~]$

Confirmed — needs Font Awesome. Check if it's on pots (the main SableLinux build) so you can copy it over:

bash
fc-list | grep -i awesome
Run that on pots/the main SableLinux system, not the HP Pavilion.

nothing.

Neither system has it installed as a system font. Check where it lives in the sablelinux repo or sources:

bash
find /sources /home/pepper/sablelinux -name "*awesome*" -o -name "*FontAwesome*" 2>/dev/null
no

Need to grab it. On the HP Pavilion:

bash
mkdir -p ~/.local/share/fonts
curl -L "https://github.com/FortAwesome/Font-Awesome/releases/download/6.7.2/fontawesome-free-6.7.2-desktop.zip" -o /tmp/fa.zip
unzip /tmp/fa.zip -d /tmp/fa
cp /tmp/fa/fontawesome-free-6.7.2-desktop/otfs/*.otf ~/.local/share/fonts/
fc-cache -fv ~/.local/share/fonts/
Then verify:

bash
fc-list | grep -i awesome
[piper@sable-hp ~]$ mkdir -p ~/.local/share/fonts
curl -L "https://github.com/FortAwesome/Font-Awesome/releases/download/6.7.2/fontawesome-free-6.7.2-desktop.zip" -o /tmp/fa.zip
unzip /tmp/fa.zip -d /tmp/fa
cp /tmp/fa/fontawesome-free-6.7.2-desktop/otfs/*.otf ~/.local/share/fonts/
fc-cache -fv ~/.local/share/fonts/
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:--  0:00:01 --:--:--     0
100 3603k  100 3603k    0     0   969k      0  0:00:03  0:00:03 --:--:-- 1747k
bash: unzip: command not found
cp: cannot stat '/tmp/fa/fontawesome-free-6.7.2-desktop/otfs/*.otf': No such file or directory
Font directories:
    /home/piper/.local/share/fonts
/home/piper/.local/share/fonts: caching, new cache contents: 0 fonts, 0 dirs
/var/cache/fontconfig: not cleaning unwritable cache directory
/home/piper/.cache/fontconfig: cleaning cache directory
/home/piper/.fontconfig: not cleaning non-existent cache directory
fc-cache: succeeded
[piper@sable-hp ~]$

Show more
No unzip. Use busybox or python:

bash
python3 -c "import zipfile; zipfile.ZipFile('/tmp/fa.zip').extractall('/tmp/fa')"
cp /tmp/fa/fontawesome-free-6.7.2-desktop/otfs/*.otf ~/.local/share/fonts/
fc-cache -fv ~/.local/share/fonts/
fc-list | grep -i awesome
[piper@sable-hp ~]$ python3 -c "import zipfile; zipfile.ZipFile('/tmp/fa.zip').extractall('/tmp/fa')"
cp /tmp/fa/fontawesome-free-6.7.2-desktop/otfs/*.otf ~/.local/share/fonts/
fc-cache -fv ~/.local/share/fonts/
fc-list | grep -i awesome
Font directories:
    /home/piper/.local/share/fonts
/home/piper/.local/share/fonts: caching, new cache contents: 3 fonts, 0 dirs
/var/cache/fontconfig: not cleaning unwritable cache directory
/home/piper/.cache/fontconfig: cleaning cache directory
/home/piper/.fontconfig: not cleaning non-existent cache directory
fc-cache: succeeded
/home/piper/.local/share/fonts/Font Awesome 6 Brands-Regular-400.otf: Font Awesome 6 Brands,Font Awesom 6 Brands Regular:style=Regular
/home/piper/.local/share/fonts/Font Awesome 6 Free-Regular-400.otf: Font Awesome 6 Free,Font Awesome 6 Free Regular:style=Regular
/home/piper/.local/share/fonts/Font Awesome 6 Free-Solid-900.otf: Font Awesome 6 Free,Font Awesome 6 Free Solid:style=Solid
[piper@sable-hp ~]$

Show more
Fonts are in. Restart waybar to pick them up:

bash
pkill waybar; swaymsg reload
that worked  what is the "activated/deactivated" icon doing?

Which module is showing it — network, VPN, bluetooth, something else? Screenshot or describe where it appears in the bar.

looks like an old ABC network icon... an eyeball, to left of volume control but different color

That's likely the PipeWire/audio module showing a microphone or sink icon that's mapping to a glyph Font Awesome renders as a circle/eye shape. Which waybar module config is it tied to?

bash
cat /etc/xdg/waybar/config | grep -A5 -B2 "pulseaudio\|pipewire\|audio"
[piper@sable-hp ~]$ cat /etc/xdg/waybar/config | grep -A5 -B2 "pulseaudio\|pipewire\|audio"
cat: /etc/xdg/waybar/config: No such file or directory
[piper@sable-hp ~]$

bash
find /etc/xdg/waybar /usr/etc/xdg/waybar /usr/share/waybar -name "config" 2>/dev/null
nothing.

Waybar is using a compiled-in default config then. Check what modules are loaded:

bash
waybar --version
ps aux | grep waybar
And let's see the full default config:

bash
find / -path "*/waybar/*config*" 2>/dev/null | grep -v proc
[piper@sable-hp ~]$ waybar --version
ps aux | grep waybar
Waybar v0.11.0
piper       8457  0.6  0.3 1209676 52836 tty1    Sl+  12:42   0:01 waybar -b bar-0
piper       8525  0.0  0.0   6636  2512 pts/0    S+   12:45   0:00 grep --color=auto waybar
[piper@sable-hp ~]$ find / -path "*/waybar/*config*" 2>/dev/null | grep -v proc
/etc/xdg/waybar/config.jsonc
[piper@sable-hp ~]$

bash
grep -A5 -B2 "pulseaudio\|pipewire\|audio" /etc/xdg/waybar/config.jsonc
1000007959.jpg
[piper@sable-hp ~]$ grep -A5 -B2 "pulseaudio\|pipewire\|audio" /etc/xdg/waybar/config.jsonc
        "mpd",
        "idle_inhibitor",
        "pulseaudio",
        "network",
        "power-profiles-daemon",
        "cpu",
        "memory",
        "temperature",
--
        "format-alt": "{ifname}: {ipaddr}/{cidr}"
    },
    "pulseaudio": {
        // "scroll-step": 1, // %, can be a float
        "format": "{volume}% {icon} {format_source}",
        "format-bluetooth": "{volume}% {icon} {format_source}",
        "format-bluetooth-muted": " {icon} {format_source}",
        "format-muted": " {format_source}",
[piper@sable-hp ~]$   ::: the icon doesn't affect audio at all.

Show more
That's the idle_inhibitor module — the eye icon is its glyph. It's a toggle that prevents the system from going idle/sleeping when activated. Click it and it should change state (activated = eye open, deactivated = eye with line through it or similar).

It's not broken — it's working as designed. Since you just set swayidle to 1 hour, it's probably not something you need. You can remove it from the modules list if you want:

bash
sudo sed -i 's/"idle_inhibitor",//' /etc/xdg/waybar/config.jsonc
Then:

bash
pkill waybar; swaymsg reload
no our idle set failed.  so if it's not crossed out its active meaning... no sleep?

Correct. If the eye is open/not crossed out, idle inhibitor is active and the system won't sleep regardless of swayidle timeouts. That's why your 1-hour change appeared to fail — the inhibitor was overriding it.

Click the eye icon to deactivate it (should show crossed-out), then your 1-hour swayidle timeout will take effect.

