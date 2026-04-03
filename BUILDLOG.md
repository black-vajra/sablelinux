
## 2026-03-06 — BLFS Infrastructure + Display Stack Foundation

### Essential Infrastructure
- wget 1.21.4
- OpenSSH 10.0p1 (manual sshd.service, socket activation)
- libtasn1 4.19.0
- p11-kit 0.25.5
- make-ca 1.16.1 (543 Mozilla CA certs)
- libpsl 0.21.5
- curl 8.15.0
- git 2.48.1

### PAM Trinity
- Linux-PAM 1.7.2
- Shadow 4.18.0 (rebuilt with PAM support)
- systemd 257.8 (rebuilt with PAM/logind support)

### Display Stack Foundation
- libdrm 2.4.124
- util-macros 1.20.2
- xorgproto 2024.1
- libXau 1.0.12
- xcb-proto 1.17.0
- libxcb 1.17.0
- freetype 2.13.3 (built twice with/without harfbuzz)
- harfbuzz 10.2.0
- fontconfig 2.17.1
- 32 Xorg libraries batch (xtrans through libXpresent)

## 2026-03-06 — LLVM 19.1.7
- cmake 3.31.6
- LLVM 19.1.7 with AMDGPU+BPF targets, shared library build
- GCC 15.2 compatibility issues worked around (compiler-rt excluded)
- llvm-config confirmed working, all AMDGPU components present

## Mesa 25.0.1 + Wayland Stack
- libxml2 2.13.5
- glslang 16.2.0 (ENABLE_OPT=OFF, no SPIRV-Tools)
- wayland 1.23.1
- wayland-protocols 1.44
- mesa 25.0.1
  - Gallium: radeonsi, llvmpipe
  - Vulkan: amd (RADV), device-select + overlay layers
  - Platforms: x11, wayland
  - LLVM backend: 19.1.7
  - Video codecs: h264dec/enc, h265dec/enc, vc1dec
  - glvnd: disabled, OpenCL/rusticl: disabled
  - Intel iris/ANV excluded pending libclc build
  - Installed: /usr/lib/dri/{radeonsi,swrast,kms_swrast,libdril}_dri.so
  - Vulkan ICD: /usr/share/vulkan/icd.d/radeon_icd.x86_64.json
- Python deps added: mako, PyYAML, ply

## Session: PAM + Audio Fix (2026-03-08)

### Linux-PAM 1.7.2
- Built with meson, --libdir=lib, -Ddocs=disabled, -Dsecuredir=/usr/lib/security
- Created /etc/pam.d/{other,system-auth,system-account,system-password,system-session,login,passwd,su,sshd}
- pam_env.so added to system-session for /etc/environment support
- pam_systemd.so added to system-session for logind session registration

### shadow 4.18.0 (rebuilt with PAM)
- Rebuilt with --with-libpam to link against libpam
- Replaced default login PAM config (removed pam_securetty/pam_selinux/pam_console references)

### pulseaudio 17.0 (client libraries only)
- Built with -Ddaemon=false — PipeWire remains audio server
- Provides libpulse.so required by Firefox binary tarball
- Firefox audio confirmed working via pipewire-pulse socket

### Notes
- /etc/environment: XDG_SESSION_TYPE=wayland
- PULSE_SERVER=unix:/run/user/1000/pulse/native added to launch script
- wpctl confirms: HDA Intel PCH + Navi 48 HDMI enumerated

## Session: Locale + Environment Fix (2026-03-08)
- Added LANG=en_US.UTF-8 to ~/.bash_profile
- Regenerated locale with localedef -i en_US -f UTF-8 en_US.UTF-8
- Added XDG_SESSION_TYPE=wayland to /etc/environment
- pam_env.so readenv=1 added to system-session
- loginctl now shows Type: wayland
- Firefox locale warning resolved

## Session: SSH Hardening (2026-03-08)

- Installed maya (kaya) public key to ~/.ssh/authorized_keys

- Disabled password authentication

- Disabled root login

- Changed port to ######

- AllowUsers ######

- UsePAM yes

- X11Forwarding no

- MaxAuthTries 3

- LoginGraceTime 30


## Session: Security Stack + Microcode (2026-03-08)
- libpcap 1.10.5 installed
- tcpdump 4.99.5 installed  
- nmap 7.95 installed
- libnl 3.12.0 installed
- aircrack-ng 1.7 installed
- socat 1.8.0.3 installed
- masscan 1.3.9 installed
- Intel microcode blobs installed to /lib/firmware/intel-ucode/ (151 files)
- Initramfs rebuilt with intel-ucode support
- SecLists 2.5G cloned to /sources/SecLists
- sqlmap, hashcat, gobuster, masscan cloned to /sources

## Microcode + cpio (2026-03-08)
- Intel microcode blobs installed (151 files) to /lib/firmware/intel-ucode/
- initramfs rebuilt to include intel-ucode (25M)
- /opt/initramfs-tools created as permanent initramfs build dependency store
- make-initramfs.sh updated to use /opt/initramfs-tools instead of /tmp/initrd-inspect
- cpio 2.15 installed (GCC 15 xstat function pointer fix applied)
- nano 8.3 installed

## Security Stack Phase 2 — 2026-03-08

### Dependencies
- libgpg-error 1.51 — GPG error handling library (wireshark dep)
- libgcrypt 1.11.0 — cryptographic library (wireshark dep)
- speexdsp 1.2.1 — DSP library (wireshark dep)
- c-ares 1.34.6 — async DNS resolver (wireshark dep)

### Network Analysis
- wireshark 4.6.3 — tshark CLI only (BUILD_wireshark=OFF, ENABLE_QT6=OFF)

### Utilities
- which 2.21 — command location utility
- Go 1.24.1 — toolchain installed to /usr/local/go

### Security Tools
- sqlmap 1.10.2 — SQL injection tool (cloned, symlinked to /usr/bin)
- ffuf 2.1.0 — web fuzzer (binary tarball, installed to /usr/bin)
- gobuster 3.8.2 — directory/DNS brute forcer (built from source with Go)
- nikto 2.6.0 — web server vulnerability scanner (cloned, Perl)
- ncat — included with nmap 7.95

### Notes
- python symlink added: /usr/bin/python -> /usr/bin/python3 (sqlmap shebang fix)
- nikto requires Perl modules JSON and XML::Writer (installed via cpan)

## Security Stack Phase 3 — 2026-03-08

### Reverse Engineering
- gdb 16.3 — with debuginfod support (elfutils dep)
- elfutils 0.192 — debuginfod + DWARF libraries
- pwndbg — gdb plugin (installed via uv venv at /sources/pwndbg/.venv)
- pwntools 4.15.0 — CTF exploit framework (pip3)
- ROPgadget 7.7 — ROP chain builder (pip3)
- radare2 6.1.1 — reverse engineering framework (built from source)
- binwalk 3.1.1 — firmware analysis (Rust rewrite, built with cargo)

### Java / RE GUI
- OpenJDK 21.0.2 — installed to /opt/jdk
- Ghidra 11.3.1 — installed to /opt/ghidra (pending XWayland for GUI)

### Utilities
- sqlmap 1.10.2 — /usr/bin/python symlink added for shebang fix
- rustup + cargo — installed to /root/.cargo for binwalk build

### Notes
- /usr/local/bin and /usr/local/lib added to PATH and ld.so.conf
- XWayland deferred — needed for Ghidra GUI and Burp Suite

## Ruby 3.3.8
- Bootstrap: extracted ruby3.3 + libruby3.3 debs from Ubuntu archive into /tmp
- LD_LIBRARY_PATH + RUBYLIB needed to point Ubuntu binary at its own stdlib
- Build: make BASERUBY="env LD_LIBRARY_PATH=/tmp/usr/lib/x86_64-linux-gnu:/tmp:/usr/lib RUBYLIB=/tmp/usr/lib/ruby/3.3.0:/tmp/usr/lib/x86_64-linux-gnu/ruby/3.3.0 /tmp/usr/bin/ruby3.3" -j14
- sudo make install confirmed: ruby 3.3.8
- psych (YAML) extension skipped — libyaml headers not found at configure time

## PostgreSQL 16.6
- Client libs only (needed for pg gem / Metasploit)
- CFLAGS="-std=gnu17 -O2" required for GCC 15 C23 bool typedef conflict

## Metasploit Framework 6.4.122
- Cloned from github.com/rapid7/metasploit-framework (shallow --depth=1)
- bundle config set --local path vendor/bundle (pepper-owned, no system gem pollution)
- 245 gems installed, msfconsole confirmed working

## libpcap 1.10.5
- Source: https://www.tcpdump.org/release/libpcap-1.10.5.tar.gz
- ./configure --prefix=/usr --disable-static --with-pcap=linux
- make -j14 && make install
- Verified: pkg-config --modversion libpcap → 1.10.5

## tcpdump 4.99.5
- Source: https://www.tcpdump.org/release/tcpdump-4.99.5.tar.gz
- ./configure --prefix=/usr
- make -j14 && make install
- Verified: tcpdump --version → 4.99.5 / libpcap 1.10.5

## nmap 7.95
- Source: https://nmap.org/dist/nmap-7.95.tar.bz2
- ./configure --prefix=/usr --with-libpcap=/usr --without-ndiff --without-zenmap
- make -j14 && make install
- Verified: nmap --version → 7.95, libpcap-1.10.5 linked

## libgpg-error 1.51
- Source: https://www.gnupg.org/ftp/gcrypt/libgpg-error/libgpg-error-1.51.tar.bz2
- ./configure --prefix=/usr --enable-static=no
- make -j14 && make install

## libgcrypt 1.11.0
- Source: https://www.gnupg.org/ftp/gcrypt/libgcrypt/libgcrypt-1.11.0.tar.bz2
- ./configure --prefix=/usr --enable-static=no
- make -j14 && make install

## c-ares 1.34.4
- Source: https://github.com/c-ares/c-ares/releases/download/v1.34.4/c-ares-1.34.4.tar.gz
- cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_INSTALL_LIBDIR=lib -DCMAKE_BUILD_TYPE=Release
- cmake --build build -j14 && cmake --install build
- Verified: pkg-config --modversion libcares → 1.34.4

## tshark 4.6.4 (Wireshark CLI)
- Source: https://www.wireshark.org/download/src/wireshark-4.6.4.tar.xz
- cmake -DBUILD_wireshark=OFF -DBUILD_logray=OFF -DENABLE_QT6=OFF -DENABLE_QT5=OFF
- cmake --build build -j14 && cmake --install build
- Verified: tshark 4.6.4, libpcap 1.10.5 (TPACKET_V3), libgcrypt 1.11.0, c-ares 1.34.4, Lua 5.4.7

## ncat 7.95
- Bundled with nmap — no separate build required
- Verified: ncat --version → Ncat 7.95

## socat 1.8.0.3
- Source: http://www.dest-unreach.org/socat/download/socat-1.8.0.3.tar.bz2
- ./configure --prefix=/usr
- make -j14 && make install
- Verified: full feature build — WITH_PTY, WITH_OPENSSL, WITH_TUN, WITH_SOCKS4/4A/5

## masscan 1.3.2
- Source: https://github.com/robertdavidgraham/masscan/archive/refs/tags/1.3.2.tar.gz
- make -j14 && make install PREFIX=/usr
- Note: "not a git repository" warning at link time is harmless — no git hash embedded
- Verified: masscan 1.3.2

## Metasploit Framework 6.4.122 — PATH fix
- msfconsole located at /opt/metasploit-framework/msfconsole
- Symlinked to /usr/local/bin/msfconsole
- /usr/local/bin added to PATH via /etc/profile.d/local-bin.sh
- Verified: msfconsole --version → Framework Version 6.4.122

## hashcat 7.1.2
- Source: https://github.com/hashcat/hashcat/archive/refs/tags/v7.1.2.tar.gz
- make -j14 && make install PREFIX=/usr
- Verified: hashcat --version → v7.1.2
- Note: CPU mode only until ROCm built; HIP backend available in 7.x

## hcxdumptool 7.1.2
- Source: git clone https://github.com/ZerBea/hcxdumptool.git
- make -j14 && make install
- Verified: hcxdumptool --version → 7.1.2

## hcxtools 7.1.2
- Source: git clone https://github.com/ZerBea/hcxtools.git
- make -j14 && make install
- Verified: hcxpcapngtool --version → 7.1.2

## wireless-tools 29
- Source: https://hewlettpackard.github.io/wireless-tools/wireless_tools.29.tar.gz
- make -j14 && make install PREFIX=/usr
- Verified: iwconfig Wireless-Tools version 29, WE v11-v22
- Note: /proc/net/wireless warning expected — no interfaces in monitor mode

## pwndbg 2026.02.18
- Source: git clone https://github.com/pwndbg/pwndbg.git
- pip install --break-system-packages -e ".[dev]"
- Wired into gdb via /root/.gdbinit
- Verified: 194 commands loaded, gdb functions registered
- Note: setup.sh skipped — LFS not a supported distro; manual pip install used

## pwntools 4.14.1
- Installed as pwndbg dependency
- Verified: pwnlib.__version__ → 4.14.1

## ROPgadget 7.6
- Installed as pwndbg dependency
- Verified: ROPgadget v7.6

## binwalk 3.1.1
- Source: git clone https://github.com/ReFirmLabs/binwalk.git
- Built with cargo (Rust rewrite); cargo build --release
- Installed to /usr/local/bin/binwalk
- Note: /usr/local/bin missing from root PATH — added to /root/.bashrc
- Verified: binwalk 3.1.1

## radare2 6.1.1
- Source: git clone https://github.com/radareorg/radare2.git
- chown -R root:root required (sys/install.sh downgraded to pepper)
- ./configure --with-rpath --prefix=/usr/local && make -j14 && make install
- Verified: radare2 6.1.1 +35252

## AI Dev Stack — $(date +%Y-%m-%d)

### Dependencies
- patchelf 0.18.0 — built from source
- texinfo 7.2 — built from source (doc install skipped, locale bug)
- GCC 15.2.0 — rebuilt with --enable-languages=c,c++,fortran added

### Python AI Development Stack
Installed via pip to /home/pepper/.local/:
- anthropic 0.84.0
- openai 2.26.0
- langchain 1.2.10
- langgraph 1.0.10
- fastapi 0.135.1
- uvicorn 0.41.0
- pydantic 2.12.5
- httpx 0.28.1
- python-dotenv 1.2.2

PATH updated: ~/.local/bin added to ~/.bash_profile

### ROCm / TheRock — DEFERRED
TheRock full source build requires >32GB RAM for amd-llvm compilation.
OOM killer terminates cc1plus during Flang PCH build regardless of -j count.
Revisit when hardware is upgraded. Target: ROCm 7.x via TheRock, gfx1201.

---

## Desktop Environment Phase — Wayland Desktop Stack
**Date:** 2026-03-10

### Python 3.13.7
- Confirmed installed and functional: `/bin/python`
- No EXTERNALLY-MANAGED lockout file present — pip usable system-wide without venv
- pip, setuptools, wheel ready for pentest/AI tooling

### wl-clipboard 2.2.1
- Wayland clipboard utilities: wl-copy, wl-paste
- Installed to /bin/wl-copy, /bin/wl-paste
- Note: only functional inside active Wayland session as pepper (XDG_RUNTIME_DIR + WAYLAND_DISPLAY required)

### grim 1.4.1 + slurp 1.5.0
- Screenshot toolchain: slurp for region selection, grim for capture
- Installed to /bin/grim, /bin/slurp
- No new dependencies beyond existing wayland/cairo/libpng stack

### swayidle 1.8.0 + swaylock 1.7.2
- Idle management and screen lock
- swaylock built with -Dpam=enabled (Linux-PAM 1.7.2)
- swaylock setuid: chmod u+s /bin/swaylock (required for PAM auth)

### mako 1.9.0
- Wayland notification daemon
- No new dependencies

### scdoc 1.11.3
- Man page generator; required by fuzzel
- Built with make/make install; installed to /bin/scdoc, /usr/local/bin/scdoc (symlink)

### tllist 1.1.0
- Header-only linked list library; required by fuzzel/fcft

### fuzzel 1.11.1
- Wayland application launcher (replaces rofi/wofi for Wayland-native workflow)
- Built with fcft as subproject (font rendering)
- libutf8proc absent — non-fatal, unicode fallback used

### atk 2.38.0
- Accessibility toolkit (standalone build required before atkmm)
- Built with -Dintrospection=false (gobject-introspection not installed)

### libsigc++ 2.12.1
- C++ signal/slot library (2.x series — required by gtkmm3/glibmm 2.x chain)

### glibmm 2.66.7
- C++ GLib bindings (2.66.x — last sigc++-2.0 compatible series)

### cairomm 1.14.5
- C++ Cairo bindings (1.14.x — sigc++-2.0 compatible)

### pangomm 2.46.4
- C++ Pango bindings (2.46.x — sigc++-2.0 compatible)

### atkmm 2.28.4
- C++ ATK bindings

### gdk-pixbuf 2.42.12
- Image loading library (standalone build; required by gtkmm subproject resolution)
- Built with -Dintrospection=disabled -Dman=false -Dgtk_doc=false

### GTK3 lib64 fix
- GTK3 (3.24.43) was previously installed to /usr/lib64 (cmake default)
- Repaired: .so files copied to /usr/lib with correct symlinks, .pc files copied and path-corrected
- Same fix applied to gdk-pixbuf, gdk libs
- ldconfig run after repair

### gtkmm 3.24.9
- C++ GTK3 bindings; final dep before waybar

### jsoncpp 1.9.6
- JSON parsing library (cmake build, shared libs)

### fmt 11.1.4
- C++ formatting library (cmake build, tests disabled)

### spdlog 1.15.1
- C++ logging library (cmake build, external fmt backend)

### libnl 3.11.0
- Netlink library (required for waybar network module)
- autotools build

### waybar 0.11.0
- Full-featured Wayland status bar
- Built with -Dman-pages=disabled -Dtests=disabled
- All modules available: network (libnl), audio (pipewire/pulseaudio), system stats

### Key Learnings
- Stale /sources/build directory causes recurring meson "parent of source" error — always `rm -rf build` inside the package dir before building
- gtkmm/atkmm/glibmm chain must stay on 2.x/2.66/2.46/2.28 series — sigc++ 2.0 compatibility
- gobject-introspection not installed — pass -Dintrospection=disabled/false wherever required
- atk must be built standalone before atkmm (not bundled in GTK3 build)
- gdk-pixbuf must be built standalone before gtkmm (subproject resolution pulls glycin-2 Rust dep otherwise)
- scdoc installs to /bin but fuzzel hardcodes /usr/local/bin — symlink required


---

## Media & Security Stack Additions
**Date:** 2026-03-10

### Vulkan Headers 1.3.290
- Installed headers directly (cmake build skipped due to C++20 module issues)
- cp to /usr/include/vulkan/ and /usr/include/vk_video/
- Required by libplacebo and future ROCm/HIP work

### libplacebo 6.338.2
- GPU-accelerated video rendering library (required by mpv 0.39+)
- Built with Vulkan enabled, glslang/shaderc disabled (glslang built with ENABLE_OPT=OFF incompatible)
- Python 3.13 fix: ET.parse().getroot() patch in src/vulkan/utils_gen.py
- Vulkan registry: /sources/Vulkan-Headers-1.3.290/registry/vk.xml

### libass 0.17.3
- Subtitle rendering library (required by mpv)
- autotools build

### mpv 0.39.0
- Wayland-native video player
- Lua disabled (mpv requires 5.1/5.2, system has 5.4.7)
- Hardware accelerated decode via Vulkan/libplacebo
- Plays mkv/avi/mp4 beautifully on RDNA4

### Key Learnings
- libplacebo Python 3.13 incompatibility: ET.parse() returns ElementTree not Element — fix with .getroot()
- libplacebo glslang backend incompatible with our ENABLE_OPT=OFF glslang build — disable it
- mpv requires Lua 5.1 or 5.2 specifically — disable Lua for basic playback
- Vulkan headers must be installed standalone for non-Mesa packages to find them


---

## Kernel Rebuild #1 — dm-crypt Support
**Date:** 2026-03-10

### Kernel 6.16.1 rebuild #1
- Added: CONFIG_DM_CRYPT=m, CONFIG_DM_VERITY=m, CONFIG_DM_INTEGRITY=m
- Required for LUKS encrypted drive support
- make -j14, make modules_install, bzImage copied to /boot

### Kernel 6.16.1 rebuild #2
- Added: CONFIG_CRYPTO_XTS=y (XTS cipher mode — required by aes-xts-plain64 LUKS volumes)
- Without this, cryptsetup failed with "Error allocating crypto tfm (-ENOENT)"
- make -j14, make modules_install, bzImage copied to /boot

### libaio 0.3.113
- Async I/O library required by lvm2
- make/make install

### lvm2 2.03.28
- Device mapper userspace tools; provides libdevmapper
- Required by cryptsetup
- autotools build

### popt 1.19
- Command line option parsing library
- Required by cryptsetup
- autotools build

### cryptsetup 2.7.5 → 2.8.0
- Built 2.7.5 initially, upgraded to 2.8.0 to match Kubuntu version
- Flags: UDEV BLKID KEYRING KERNEL_CAPI HW_OPAL
- LUKS encrypted 4TB external drive now mountable

### Key Learnings — cryptsetup
- dm-crypt, dm-verity, dm-integrity all disabled in original kernel config
- CONFIG_CRYPTO_XTS was the critical missing piece — LUKS volumes use aes-xts-plain64
- 512e drive (512 logical / 4096 physical sectors) with 4096-sector LUKS header works fine once XTS is enabled

---

## Media Stack Additions
**Date:** 2026-03-10

### x264
- H.264 encoder library
- Built from master (videolan git)
- Required for wf-recorder screen recording

### ffmpeg 7.1 rebuild
- Rebuilt with --enable-gpl --enable-libx264 --disable-doc
- Adds H.264 encoding support
- Doc generation disabled (Texinfo::Convert::HTML perl issue)

### wf-recorder (master)
- Wayland screen recorder
- v0.4.0 and v0.5.0 both incompatible with ffmpeg 7.x (channel_layout → ch_layout API change)
- Master branch required for ffmpeg 7.x compatibility
- Usage: wf-recorder --audio -c libx264 -g "$(slurp)" -f output.mp4

### Key Learnings — wf-recorder
- wf-recorder needs git init in extracted tarball (uses git rev-parse for version)
- ffmpeg 7.x broke channel_layout API — only master branch of wf-recorder supports it
- libx264 must be built before ffmpeg and ffmpeg rebuilt with --enable-gpl --enable-libx264


## Kernel Rebuild #3 — WireGuard + Netfilter (2026-03-31)

### Kernel 6.16.1 rebuild #3
- Added: CONFIG_WIREGUARD=y, CONFIG_TUN=y
- Added: CONFIG_NETFILTER_ADVANCED=y, CONFIG_NF_TABLES=y, CONFIG_NF_NAT=y
- Added: CONFIG_IP_NF_IPTABLES=y, CONFIG_IP_NF_NAT=y, CONFIG_IP_NF_RAW=y
- Added: CONFIG_NETFILTER_XT_MATCH_COMMENT=y
- make -j14, make modules_install, bzImage copied to /boot
- Initramfs rebuilt

## WireGuard VPN (2026-03-31)

### wireguard-tools 1.0.20210914
- Built from source tarball
- Installed to /usr/bin/wg, /usr/bin/wg-quick

### VPN Configuration
- Server: Linode (172.233.26.17:51820)
- Tunnel IP: 10.6.0.4/24
- Config: /etc/wireguard/wg0.conf
- Table = off (iptables CONNMARK kernel module absent)
- PostUp/PreDown: manual default route + server IP exception via enp130s0
- Enabled: systemctl enable wg-quick@wg0
- Verified: curl -4 ifconfig.me returns 172.233.26.17

## Kernel Rebuild #4 — KVM + Bridge + VLAN (2026-03-31)

### Kernel 6.16.1 rebuild #4
- Added: CONFIG_KVM_INTEL=y, CONFIG_KVM_AMD=y
- Added: CONFIG_VHOST_NET=y
- Added: CONFIG_BRIDGE=y, CONFIG_VLAN_8021Q=y
- make -j14, make modules_install, bzImage copied to /boot
- Initramfs rebuilt
- Verified: /dev/kvm present

## QEMU 9.2.2 (2026-03-31)
- Source: https://download.qemu.org/qemu-9.2.2.tar.xz
- ./configure --prefix=/usr --target-list=x86_64-softmmu --enable-kvm --enable-virtfs --disable-docs --disable-gtk --disable-sdl
- make -j14 && make install
- Verified: qemu-system-x86_64 --version → 9.2.2
- pepper added to kvm group

## XWayland 24.1.6 (2026-03-31)
- Source: https://www.x.org/releases/individual/xserver/xwayland-24.1.6.tar.xz
- meson setup build --prefix=/usr --libdir=lib -Dxdmcp=false -Dxcsecurity=false
- ninja -C build && ninja -C build install
- Verified: Xwayland -version → 24.1.6
- Ghidra 11.3.1 GUI confirmed working via XWayland
- xwayland enable already present in sway config

## WireGuard VPN (2026-03-31)
- wireguard-tools 1.0.20210914 built from source
- Client config: /etc/wireguard/wg0.conf
- Server: Linode vajra (172.233.26.17:51820)
- Tunnel IP: 10.6.0.4/24
- Table = off (iptables CONNMARK kernel module absent)
- PostUp/PreDown: manual default route + server IP exception via enp130s0
- systemctl enable wg-quick@wg0
- Verified: curl -4 ifconfig.me returns 172.233.26.17

## KDE Plasma 6.3.4 Desktop Stack — 2026-04-01

### Qt6 Modules
- qtbase 6.8.2 (rebuilt with xcb support after adding xcb-util-cursor, xcb-util-image, xcb-util-renderutil, xcb-util-wm, xcb-util-keysyms)
- qtshadertools 6.8.2 (GCC 15 fix: -include cstdint)
- qtdeclarative 6.8.2
- qtwayland 6.8.2
- qtsvg 6.8.2
- qttools 6.8.2
- qt5compat 6.8.2
- qtimageformats 6.8.2
- qtmultimedia 6.8.2
- qtspeech 6.8.2 (TTS support — accessibility requirement)
- qtsensors 6.8.2
- qtpositioning 6.8.2
- qtwebsockets 6.8.2

### XCB Dependencies (added for Qt6 xcb platform plugin)
- xcb-util 0.4.1
- xcb-util-image 0.4.1
- xcb-util-renderutil 0.3.10
- xcb-util-wm 0.4.2
- xcb-util-keysyms 0.4.1
- xcb-util-cursor 0.1.4

### Extra CMake Modules
- extra-cmake-modules 6.11.0

### KDE Frameworks 6.11.0
- kcoreaddons, kconfig, karchive, kdbusaddons, kwindowsystem, kcrash
- kguiaddons, ki18n, kitemviews, kcompletion, kcodecs, kwidgetsaddons
- kconfigwidgets, kcolorscheme, kservice, kiconthemes, breeze-icons
- knotifications, kglobalaccel, kpackage, kdeclarative, kio, kbookmarks
- kjobwidgets, kauth, knewstuff, attica, kparts, kxmlgui, kitemmodels
- krunner, ktextwidgets, sonnet, kstatusnotifieritem, baloo, kidletime
- kfilemetadata, kdeclarative, ksvg, kirigami, kcmutils, ktexteditor
- syntax-highlighting, kunitconversion, kwallet (daemon disabled)
- knotifyconfig, kded, kbookmarks, kholidays, kuserfeedback
- kholidays, kcmutils, kwidgetsaddons, kcolorscheme, ksvg
- kdoctools (with DocBook XML 4.5 + DocBook XSL 1.79.2 + libxslt 1.1.42)
- prison (with qrencode 4.1.1)

### Dependencies
- plasma-wayland-protocols 1.16.0
- libcanberra 0.30 (with libogg 1.3.5 + libvorbis 1.3.7)
- hunspell 1.7.2
- lmdb 0.9.32
- boost 1.87.0 (headers only)
- lcms2 2.16
- libei 1.3.0
- libgudev 238
- libwacom 2.12.2
- lm-sensors 3.6.0
- libogg 1.3.5, libvorbis 1.3.7
- ICU 76.1
- libqalculate 5.5.0
- phonon 4.12.0 (Qt6, with libpulse-mainloop-glib manually installed)
- qcoro 0.12.0
- polkit 126 (with duktape 2.7.0)
- polkit-qt-1 (Qt6, built from git)
- qrencode 4.1.1

### Plasma Packages (6.3.4)
- plasma-wayland-protocols 1.16.0
- kdecoration 6.3.4
- libkscreen 6.3.4
- libksysguard 6.3.4
- kglobalacceld 6.3.4
- kwayland 6.3.4
- kscreenlocker 6.3.4
- layer-shell-qt 6.3.4
- libplasma 6.3.4
- plasma-activities 6.3.4
- plasma-activities-stats 6.3.4
- plasma5support 6.3.4
- kwin 6.3.4
- plasma-workspace 6.3.4
- plasma-desktop 6.3.4

### Display Manager
- sddm (git master, Qt6 build)
- sddm.service enabled
- /usr/share/wayland-sessions/plasma.desktop created
- /usr/share/wayland-sessions/sway.desktop present

### Key Learnings
- qtbase must be rebuilt with xcb after installing xcb-util-* packages
- qtshadertools needs -include cstdint for GCC 15
- libpulse-mainloop-glib built separately and manually installed
- polkit-qt-1 Qt6 build requires git master (0.200.0 is Qt5 only)
- sddm 0.20.0 has D-Bus XML bug with Qt6 — use git master
- prison requires qrencode built with -fPIC and shared libs
- SDDM Qt6 flag is BUILD_WITH_QT6=ON (not QT_MAJOR_VERSION)

---

## KDE Plasma 6 Build Attempt + Recovery — 2026-03-11

### What Was Built
Full KDE Plasma 6 stack built from source over two sessions:
- Qt6 (qtbase, qtdeclarative, qtshadertools, qt5compat, qtwayland, qtsvg, qttools, qtmultimedia)
- Extra CMake Modules (ECM) 6.11.0
- KDE Frameworks 6.11.0 (full dependency chain)
- KWin 6.3.4
- plasma-workspace 6.3.4
- plasma-desktop 6.3.4
- SDDM (git master, BUILD_WITH_QT6=ON)
- Supporting libs: xcb-util-*, libxcursor, libXrender, libdrm (already present), polkit-qt-1 (git)

Build scripts committed to build-scripts/: kde-plasma-build.sh, sway-stack-build.sh

### Root Cause of Boot Failure
SDDM failed to start. Debugging led down a false path (suspected USB enumeration delay).
Multiple grub.cfg modifications were made in an attempt to add boot delays.
Actual root cause: `/etc/vconsole.conf` contained `FONT=Lat2-Terminus16`, which does not
exist on this system. systemd-vconsole-setup.service failed, stalling the boot sequence
before SDDM could launch.

Fix is a one-liner: `sed -i '/^FONT=/d' /etc/vconsole.conf`

The GRUB edits made during debugging left the system unbootable before this was diagnosed.

### Backup Restoration Failure
Attempted to restore from sable-root-pre-kernel-rebuild.img.gz (Mar 10 partclone image).
Restore failed at 63%: partition geometry mismatch. The USB SSD was repartitioned during
a vacation Ubuntu installation, so the drive geometry no longer matches what partclone
recorded. partclone.restore -C (ignore geometry) was not sufficient to complete the restore.

### Recovery Plan
1. Repartition USB SSD to original layout (512M EFI / 2G boot / remainder root)
2. Restore from Mar 10 backups (sable-*-pre-kernel-rebuild.img.gz)
3. Chroot and apply vconsole fix before first boot
4. Verify Sway desktop boots cleanly
5. Resume KDE Plasma build using kde-plasma-build.sh

### Lessons Learned
- Never edit grub.cfg while chasing a suspected boot timing issue without confirming
  the actual failure point first (journalctl -xb, systemctl --failed)
- vconsole.conf FONT entries must reference fonts that actually exist in /usr/share/kbd/consolefonts/
- Partition backups must be retaken after any repartitioning event
- partclone geometry mismatch: -C flag is not a reliable workaround — recreate geometry first

### Status
Recovery in progress. Resuming from Mar 10 backup state.

---

## KDE Plasma 6 Build — Session 2 (Recovery + Successful Install) — 2026-04-02

### Recovery
- Restored from sable-root-pre-kernel-rebuild.img.gz (Mar 10 backup)
- Root cause of restore failure confirmed: Ubuntu had resized sda3 from ~463G to 231.6G
- Fix: deleted sda4-6, recreated sda3 from sector 5244928 to 976773134 (full remainder)
- All three partitions restored cleanly (EFI, boot, root)
- vconsole.conf FONT=Lat2-Terminus16 entry removed pre-boot

### Version Updates (from original script targets)
- KF6: 6.11.0 → 6.24.0 (6.11.0 no longer on KDE servers)
- Plasma: 6.3.4 → 6.4.0 (6.3.4 gone; 6.6.3 requires Qt 6.10.0; 6.4.0 compatible with Qt 6.8.x)
- wayland-protocols: 1.44 → 1.48 (kwindowsystem 6.24.0 needs ext-background-effect-v1.xml)
- plasma-wayland-protocols: 1.16.0 → 1.20.0 (libkscreen 6.4.0 needs EDR/DDC-CI protocols)
- Qt6Location added (plasma-workspace 6.4.0 requirement, missing from original Qt module list)

### Build Fixes Applied (KF6 6.24.0 vs 6.11.0 delta)
- CMAKE_COMMON: added -DBUILD_PYTHON_BINDINGS=OFF (Shiboken6 not installed)
- kguiaddons: -DUSE_DBUS=OFF (Qt private headers not available)
- kwindowsystem: must be built after plasma-wayland-protocols
- kwallet: -DBUILD_KWALLETD=OFF -DBUILD_KSECRETD=OFF -DBUILD_KWALLET_QUERY=OFF (all daemons disabled by design)
- prison: -DWITH_DMTX=OFF -DWITH_ZXING=OFF (barcode libs not installed, not needed)
- kcompletion: missing from original script, required by kio — added before kio
- kdoctools: must be built before kio, not after
- ECM: must be built before Phonon, not after
- plasma-wayland-protocols: must be built before kwindowsystem (Phase 5, not Phase 6)
- KWin 6.4.0: patch src/wayland/xdgsession_v1.h — add #include <QVariant> (GCC 15 strictness)
- kirigami: failed silently in script run — rebuilt manually

### Script Evolution
- kde-plasma-build.sh → kde-plasma-resume.sh → kde-plasma-resume2.sh
- resume2.sh adds skip guards (cmake config file checks) for fast restarts
- Full build completed successfully on resume2.sh

### Result
- KDE Plasma 6.4.0 + SDDM installed
- SDDM service enabled (display-manager.service → sddm.service)
- vconsole.conf clean (KEYMAP=us only)
- Backup taken: sable-root-kde-plasma-6.4.0.img.gz

### Pending
- First boot verification
- KWin/SDDM Wayland session confirmation
- Clean single-run script validation (restore Mar 10 → run corrected script)

---

## SDDM Debugging Session — 2026-04-03

### Hardware Change
- SableLinux 500GB SSD moved from USB 3.0 to internal SATA connection
- Confirmed: lsblk shows TRAN=sata, device /dev/sda
- Boot reliability improved — no more USB enumeration variability

### SDDM First Boot Attempt
- SDDM started successfully, kwin_wayland launched
- Fatal errors:
  - XDG_RUNTIME_DIR not set / invalid
  - kwin_core: Could not determine the active graphical session
  - FATAL ERROR: could not add wayland socket
- Root cause: not yet fully diagnosed — logind session registration
  for SDDM/KWin compositor not working correctly on LFS

### Fixes Applied (chroot from pots)
- sddm user added to video and input groups
- tmpfiles.d entry created: /usr/lib/tmpfiles.d/sddm.conf
  (ensures /run/sddm exists at boot with correct ownership)
- SDDM symlink confirmed intact: display-manager.service → sddm.service

### Script Update
- kde-plasma-build-v2.sh committed to build-scripts/
- Complete rewrite with all session fixes applied:
  - All build fixes from session 2 baked in
  - Skip guards on every package for fast restarts
  - Correct KF6 6.24.0 dependency order
  - SDDM PAM: explicit pam_systemd.so in session configs
  - tmpfiles.d entry for /run/sddm
  - sddm user video+input group membership
  - KWin GCC 15 patch automated
  - Qt6Location added to Qt modules

### Status
- SDDM debugging ongoing
- Sway desktop fully operational as fallback
- Next: reboot and check journalctl -u sddm for updated diagnostics
