Purpose & context
Jonny is the developer of SableLinux, a custom Debian-inspired but built-from-scratch (LFS 12.4-systemd base) Linux distribution targeting professional security researchers with modern hardware. The distro is designed to be both a live boot and installable system, with a hardware-agnostic build philosophy (no per-device whack-a-mole — must run across diverse hardware like the z890 flagship, HP Pavilion i3-8100, HP Elitebook, ASUS Q503UA, and low-end Celeron N4120 machines). Accessibility is a first-class feature: full support for blind, deaf, deafblind, PTSD-affected, reading-challenged, and alternate-input users is a core design goal, not an afterthought.
The project lives at github.com:black-vajra/sablelinux on the development branch. All significant work is documented in BUILDLOG.md at /home/pepper/sablelinux/BUILDLOG.md. Jonny operates as user pepper on the z890/SableLinux system and switches between SableLinux (nvme1n1) and a Kubuntu partition (nvme0n1) on the same machine.
Build priority order:

Security/pentest stack (libpcap, tcpdump, nmap, wireshark, aircrack-ng, hashcat, ffuf, gobuster, sqlmap, metasploit, gdb, radare2, ghidra, SecLists)
AI/ROCm stack (ROCm 6.x, llama.cpp HIP, Ollama)
Proprietary AI pentest tooling
Gaming
Virtualization

Completed packages: sudo, OpenSSH, wget, curl, git, CA certs, libxml2, libpng, freetype, fontconfig, cairo, glib2, harfbuzz, fribidi, pango, json-c, glslang, pixman, at-spi2-core, GTK3, LLVM 19, Mesa 25.0.1, full wayland stack, sway 1.10, foot, tmux, alsa, PipeWire, WirePlumber, ffmpeg, Firefox, Linux-PAM 1.7.2, shadow 4.18.0 (PAM rebuild), pulseaudio 17.0 (client libs only).

Current state
z890/SableLinux (nvme1n1) — primary build machine:

Sway 1.10 running on AMD RDNA4 (WLR_DRM_DEVICES=/dev/dri/card1)
Firefox working with audio (PipeWire + pipewire-pulse + libpulse)
PAM 1.7.2 installed; loginctl Type:wayland confirmed; locale en_US.UTF-8 fixed
SSH hardened: port 2269, key-only, AllowUsers pepper
Python 3.13.7 build in progress
intel-ucode 06-c6-02 (Arrow Lake-S, Core Ultra 245K) installed to /lib/firmware/intel-ucode/ and /opt/initramfs-tools/lib/firmware/intel-ucode/; initramfs rebuilt — needs mirroring to liveroot
CVE-2026-31431 patch session in progress: tracking kernel patch → rebuild → initramfs → liveroot sync; all changes must be mirrored to /mnt/liveroot for squashfs rebuild

Storage layout (pots/z890):

nvme1n1 = SableLinux: p1=512M EFI, p2=2G /boot, p3=951G /
nvme0n1 = Kubuntu (LUKS) host drive
sda = 4.5TB external drive (previous 500GB SATA SSD notes are stale — migration complete)

Live ISO / liveroot:

Hardware-agnostic staging directory: /mnt/liveroot-agno1 (derived from /mnt/liveroot-clean)
Full linux-firmware bundle deployed (replacing cherry-picked approach)
GPU auto-detection in /home/sable/.bash_profile using sysfs readlink with NVIDIA→AMD→Intel priority; hardcoded WLR_DRM_DEVICES line removed from sway config
QEMU/KVM testbed established using OVMF (extracted via ar + tar --zstd); launch requires -enable-kvm -m 4G -cpu host -display sdl as user pepper (not root)
Known deferred issue: LUKS encryption hardcoded to n in sable-install — requires baking cryptsetup + dependencies into installer-generated initramfs with luksOpen before findfs/mount; not yet resolved
PAM file descriptor limits fixed: pam_limits.so in both /etc/pam.d/system-session and /etc/pam.d/system-auth; /etc/security/limits.d/99-filedesc.conf with 65536 nofile limits
Waybar crash root cause resolved: /etc/xdg/waybar/config.jsonc contained an mpd module not compiled into waybar v0.11.0 — replaced with minimal known-working config in liveroot-agno1
swayidle idle_inhibitor module interaction: if the eye icon is active in waybar, it suppresses all idle timeouts regardless of swayidle config; exec should be exec_always for swaymsg reload to pick up config changes

sable-hp (HP Pavilion, 192.168.0.22, hostname spillane/sable-hp):

ALSA Headphone playback switch was explicitly [off] at codec level (invisible to PipeWire); fixed with amixer -c0 sset Headphone unmute + level set; persisted via alsactl store; alsa-restore.service confirmed active
Documented and committed to development branch


On the horizon

LUKS encryption support in sable-install: needs cryptsetup + deps baked into installer initramfs with proper luksOpen step before findfs/mount
Python 3.13.7 build completion on z890
intel-ucode mirroring to liveroot after initramfs rebuild
CVE-2026-31431 full patch cycle completion
Security/pentest stack build (priority 1): libpcap, tcpdump, nmap, wireshark, aircrack-ng, hashcat, ffuf, gobuster, sqlmap, metasploit, gdb, radare2, ghidra, SecLists
Full build target backlog (in rough priority after pentest stack):

Hardware/storage/monitoring: dmidecode, pciutils, usbutils, nvme-cli, smartmontools, lm-sensors, parted, ddrescue, testdisk, borgbackup, restic, bpftrace, bcc, sysdig, and more
Network/pentest: iproute2, scapy, bettercap, responder, impacket, crackmapexec, bloodhound, certipy, burpsuite, ghidra ecosystem, and more
Languages/runtimes: nodejs, rust toolchain extensions, zig, nim, julia, R, haskell/ghc, and full list
Coding tools/editors: neovim ecosystem, emacs+doom, helix, clangd, podman, buildah, distrobox, and more
Terminal/productivity: zsh, fish, starship, fzf, ripgrep, ranger, taskwarrior, yt-dlp, gnupg2, espeak-ng, and full list
AI/ROCm stack (priority 2): ROCm 6.x, llama.cpp HIP, Ollama


Accessibility stack: screen readers, TTS (espeak-ng, festival), AT-SPI integration, alternative input devices — first-class feature
Local private Git server (Gitea or Forgejo) with automatic mirroring to external encrypted drive; fully self-hosted, GitHub-independent, positioned as a showoff/marketing feature
WiFi captive portal handling in wifi-connect script: open-network DHCP via busybox udhcpc left unresolved (timing/captive portal issue); wpa_supplicant association succeeded but DHCP discover failed on library public WiFi


Key learnings & principles

Hardware-agnostic over per-device patching: AVX runtime dispatch (e.g., spa/PipeWire plugins) is acceptable; statically compiled AVX2 binaries require -march=x86-64 rebuilds for Gemini Lake and similar low-end targets; WLR_RENDERER=pixman is the correct path for hardware without GPU acceleration
System-level configs override user configs: /etc/xdg/waybar/config.jsonc is used when no ~/.config/waybar/ exists — live environment defaults must be vetted against actual compiled feature sets
PAM routing matters: su sessions route through system-auth, not system-session — limits must be set in both
ALSA state is invisible to PipeWire: codec-level mute/unmute bypasses PipeWire volume reporting entirely; ALSA-level diagnosis needed when PipeWire reports 100% unmuted but no audio
OVMF extraction requires full dpkg tooling: busybox dpkg-deb is insufficient; use ar + tar --zstd on Ubuntu .deb packages
Never touch nvme1n1 during live USB work: the installed SableLinux system must not be disturbed; always confirm device names before destructive operations
Git stash pop can produce merge conflicts when commits were pushed from another machine between stash and pop; resolve by removing git marker lines only
Waybar idle_inhibitor takes precedence over swayidle config when active — check the eye icon state before debugging timeout behavior
Live ISO audio: requires manual start in early builds; fixed via PipeWire user service symlinks + WirePlumber volume config + audio-init.sh in sway autostart


Approach & patterns

Standard build conventions: make -j14, --libdir=lib (merged-usr, no lib64 pollution); everything documented in BUILDLOG.md
VM-based testing before liveroot commits: QEMU/KVM testbed used to catch installer issues before burning to USB
Systematic rebuild policy: when a component needs flags changed for hardware compatibility, rebuild properly rather than patching around it
All SableLinux commits originate from sable-hp (not pots); pots used only as git push relay via su -c "..." pepper
Direct, paste-ready commands preferred: minimal preamble; explain what could go wrong before destructive operations, then provide the command
Git push procedure (pots, as pepper):

  su -c "cd /home/pepper/sablelinux && git remote set-url origin git@github.com:black-vajra/sablelinux.git && git config user.email 'pepper@sablelinux.dev' && git config user.name 'pepper'" pepper
  su -c "cd /home/pepper/sablelinux && git stash && git pull --rebase origin development && git stash pop && git add BUILDLOG.md && git commit -m 'MESSAGE' && git push origin development" pepper

Tools & resources

Primary build machine: pots — z890, Core Ultra 245K, RX 9070 XT; SableLinux on nvme1n1, Kubuntu/LUKS on nvme0n1
Test/secondary machines: spillane/sable-hp (HP Pavilion, 192.168.0.22), vulfen (HP Elitebook SableLinux, 192.168.0.240 port 2269), logos (HP Elitebook Kubuntu, 192.168.0.241), sable-asus (ASUS Q503UA minimal install)
Remote servers: sable VPS (172.233.44.146 port 2267), aetherium/arcana (50.116.45.215 port 2267), vajra (172.233.26.17 port 2266)
WireGuard VPN: server on Amsterdam VPS (172.233.44.146:51820); peers include z890 (10.0.0.4), Android (10.0.0.3), Elitebook Kubuntu (10.0.0.6), HP Pavilion (10.0.0.5)
Key tools in use: squashfs, GRUB mkstandalone, QEMU/KVM + OVMF, wf-recorder, mpv, PipeWire/WirePlumber/ALSA, sway/waybar/foot, tmux, pigz, busybox
Repo: github.com:black-vajra/sablelinux, branch development, SSH remote required
