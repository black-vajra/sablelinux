
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

---

## kde-plasma-build-v3.sh — 2026-04-03

### Script Corrections vs v2
- plasma-wayland-protocols moved to Phase 6 (after ECM) — was failing in Phase 2 because ECM not yet installed
- ECM explicitly Phase 5 — hard wall before Phonon, QCoro, polkit-qt-1, and all KF6
- Phonon and QCoro moved to Phase 7 (after ECM)
- polkit-qt-1 moved to Phase 7 (needs ECM + polkit + Qt6)
- KF6 framework dependency tiers documented and ordered correctly
- kirigami explicitly before ksvg
- kcompletion added before kio
- kdoctools placed before kio in correct tier
- syntax-highlighting before ktexteditor
- kholidays/kuserfeedback/kunitconversion/attica/solid moved to Tier 1 (no KF6 deps)
- Duplicate kholidays/kuserfeedback/kunitconversion entries removed
- Skip guards use consistent has_cmake/has_lib/has_cmd helpers
- All phase ordering documented in header comments
- Qt6Location confirmed in Qt module list
- KWin GCC 15 patch automated
- SDDM PAM explicit pam_systemd.so for XDG_RUNTIME_DIR
- tmpfiles.d entry for /run/sddm
- sddm user added to video+input groups

### Status
- v3 committed, clean run in progress from March 10 restore

## WireGuard + QEMU/KVM — 2026-04-03

### Kernel Rebuild #3
- Added: CONFIG_WIREGUARD=y, CONFIG_TUN=y, CONFIG_KVM=y, CONFIG_KVM_INTEL=y
- Added: full VIRTIO family (PCI, NET, BLK, BALLOON, INPUT, CONSOLE, RNG)
- Added: VHOST_NET=y (was built-in already), BRIDGE=y (already present)

### GnuPG 2.4.7
- Deps: libassuan 3.0.2, libksba 1.6.7, npth 1.8, pinentry 1.3.1
- gnupg 2.4.7 installed; gpg-build.sh in build-scripts/

### WireGuard VPN
- wireguard-tools 1.0.20210914 built and installed
- Tunnel to vajra (172.233.26.17:51820), SableLinux assigned 10.6.0.4/24
- Confirmed: ping 10.6.0.1 0% packet loss, 121ms RTT
- systemctl enable wg-quick@wg0

### QEMU 9.2.3
- Deps: libcap-ng 0.8.5, libslirp 4.8.0, nettle 3.10
- --target-list=x86_64-softmmu, --enable-kvm --enable-slirp --enable-cap-ng
- KVM accelerator confirmed
- pepper added to kvm group; /var/lib/qemu created

### .bash_profile
- Auto-sway-launch block restored (lost in KDE restore)

## Kernel Rebuild #4 + QEMU/KVM + Ubuntu VM + WireGuard Full Tunnel + wf-recorder — 2026-04-04

### Kernel Rebuild #4
- Added: CONFIG_IP_NF_RAW=m, CONFIG_DM_CRYPT=m, CONFIG_CRYPTO_XTS=y
- Note: Rebuilds #3 and #4 together restored all flags lost in KDE restore:
  CONFIG_WIREGUARD=y, CONFIG_TUN=y, CONFIG_KVM=y, CONFIG_KVM_INTEL=y,
  full VIRTIO family, VHOST_NET=y, BRIDGE=y, IP_NF_RAW=m, DM_CRYPT=m, CRYPTO_XTS=y

### GnuPG 2.4.7
- Deps: libassuan 3.0.2, libksba 1.6.7, npth 1.8, pinentry 1.3.1
- gnupg 2.4.7 installed
- gpg -d with --pinentry-mode loopback confirmed working
- gpg-build.sh added to build-scripts/

### SDL2 2.32.2
- Built with -DSDL_WAYLAND=ON -DSDL_X11=OFF
- Native Wayland window support for QEMU VM display

### QEMU/KVM 9.2.3
- Deps: libcap-ng 0.8.5, libslirp 4.8.0, nettle 3.10, SDL2 2.32.2
- Built with --enable-kvm --enable-slirp --enable-cap-ng --enable-sdl
- /dev/kvm confirmed present, kvm_intel built-in (=y)
- pepper added to kvm group
- /var/lib/qemu/{disks,iso,scripts} created
- qcow2 disk images: windows 80G, kali 40G, blackarch 40G, ubuntu 30G, alpine 10G
- Install + boot scripts for all VMs at /var/lib/qemu/scripts/
- qemu-build.sh added to build-scripts/

### Ubuntu 24.04.2 VM
- ISO: ubuntu-24.04.2-desktop-amd64.iso (6.0G)
- Installed and booted with full KVM acceleration
- Full GNOME desktop functional in SDL2 Wayland window
- Audio: -audiodev pipewire,id=audio0 -device intel-hda -device hda-duplex,audiodev=audio0
- Network: virtio-net user mode NATs through SableLinux/WireGuard tunnel

### iptables 1.8.11
- Deps: libmnl 1.0.5, libnfnetlink 1.0.2, libnftnl 1.2.8
- Required for WireGuard full tunnel routing

### WireGuard Full Tunnel
- wireguard-tools 1.0.20210914 built and installed
- Table=off in wg0.conf (CONFIG_NETFILTER_XT_MATCH_COMMENT absent in 6.16.x)
- PostUp: pins Linode endpoint via home router, dels default, adds default via wg0
- PreDown: restores home router default route
- Routing loop fix: explicit host route for 172.233.26.17 via 192.168.0.1
- curl ifconfig.me → 172.233.26.17 (Linode Sao Paulo) confirmed
- speedtest-cli through tunnel: 168 Mbps down / 19 Mbps up
- wg-quick@wg0 enabled, auto-starts on boot confirmed after reboot

### Vajra server (Linode Debian 12)
- apt install iptables
- net.ipv4.ip_forward=1 persisted to /etc/sysctl.conf
- iptables MASQUERADE on eth0, FORWARD rules for wg0

### x264 + ffmpeg 7.1 rebuild
- x264 rebuilt from VideoLAN git (--enable-shared)
- ffmpeg 7.1 rebuilt with --enable-shared --enable-gpl --enable-libx264 --disable-static
- Critical fix: previous ffmpeg build did not install shared libs (Mar 7 timestamp)
- New build: libavcodec.so.61.19.100 dated Apr 4, 15.5MB (was 15.3MB without x264)
- Verified: avcodec_find_encoder_by_name('libx264') → Found

### wf-recorder (master) rebuild
- Rebuilt against new ffmpeg shared libs
- Screen capture confirmed working: wf-recorder -c ffv1
- x264 encoding confirmed: wf-recorder --audio -c libx264 --pixel-format yuv420p
- Audio capture via PipeWire: --audio flag
- YouTube screen capture tested and confirmed working
- Usage: timeout <seconds> wf-recorder --audio -c libx264 --pixel-format yuv420p -f ~/recordings/output.mp4
- Recordings stored at ~/recordings/

### rsync 3.3.0
- Dep: xxhash 0.8.2
- CFLAGS="-std=gnu17 -O2" required (GCC 15 lseek64 empty parameter list bug)

### speedtest-cli
- pip install speedtest-cli --break-system-packages

### .bash_profile
- Auto-sway-launch block restored (lost in KDE restore)
- XDG_SESSION_DESKTOP=sway, WLR_DRM_DEVICES=/dev/dri/card1 re-added

---

## DNS + Network Recon Stack — 2026-04-08

### DNS Configuration
- Systemwide DNS changed to Quad9 (9.9.9.9) via /etc/resolv.conf
- Firefox TTS (Read Aloud extension) broke after DNS change — root cause identified:
  Google WaveNet voice proxied through cxl-services.appspot.com returning 503
  Workaround: switched to Microsoft voice in Read Aloud settings
- sudo DNS routing issue identified: default WireGuard route (link-scope, no gateway)
  prevented root from resolving DNS — fixed with:
  sudo ip route add default via 10.6.0.1 dev wg0 metric 50
  (affects sudo make install steps that fetch during install)

### Network Recon / Pentest Stack

#### DNS Tools
- bind 9.20.22 — dig, host, nslookup, full DNS toolset
  - Deps: userspace-rcu 0.15.1, libuv 1.50.0
  - Built --disable-doh (nghttp2 not installed)

#### Network Discovery
- whois 5.5.23 — domain/IP WHOIS queries
- traceroute 2.1.5 — network path tracing
- mtr 0.95 — combined traceroute+ping, live per-hop stats
- arp-scan 1.10.0 — ARP-based host discovery
- netdiscover 0.10 — passive/active ARP recon
  - GCC 15 fix: usage() prototype corrected (void → char *)
- nbtscan 1.7.2 — NetBIOS name enumeration

#### LDAP / SMB
- openldap 2.6.13 — ldapsearch + client libs (--disable-slapd)
- enum4linux-ng 1.3.10 — Windows/Samba enumeration (Python)
  - impacket 0.13.0, ldap3 2.9.1, ldapdomaindump 0.10.0 installed
  - Pending: smbclient (samba build) for full functionality

#### SNMP
- net-snmp 5.9.4 — snmpwalk, snmpget, full SNMP toolset
- onesixtyone 0.3.4 — fast SNMP community string scanner

#### Go-based Recon
- dnsx 1.2.3 — DNS enumeration and brute force
- subfinder — subdomain discovery
- amass — attack surface mapping (OWASP)

#### Notes
- Go tools installed to ~/go/bin; PATH export required:
  export PATH=$PATH:/usr/local/go/bin:~/go/bin

---

## RE / Binary Exploitation Stack — 2026-04-08

### System Tracing
- strace 6.13 — system call tracer
- ltrace 0.8.1 — library call tracer (built from git, no formal release)
- valgrind 3.24.0 — memory error detector, profiler

### Disassembly / Emulation Frameworks
- capstone 5.0.6 — disassembly framework (C + Python bindings)
- keystone 0.9.2 — assembler framework (C + Python bindings)
  - GCC 15 fixes: #include <cstdint> added to STLExtras.h, -std=c++14
- unicorn 2.1.3 — CPU emulator framework (C + Python bindings)

### Binary Analysis (Python)
- pyelftools — ELF parsing library
- pefile — PE file analysis
- checksec.py — binary hardening checker
- z3-solver — SMT solver (angr dependency)
- angr — binary analysis framework

### Reverse Engineering Tools
- rizin 0.9.0 — radare2 fork, modern RE framework
  - rz-ghidra: abandoned — API incompatibility with rizin 0.9.0 at all tagged versions
- r2dec — radare2 decompiler plugin (installed via r2pm)
  - sudo DNS fix required for r2pm -U to reach GitHub
- Ghidra headless decompiler — CLI wrapper around Ghidra 12.0.4
  - /usr/local/bin/ghidra-headless → /opt/ghidra_12.0.4_PUBLIC/support/analyzeHeadless
  - /usr/local/bin/decompile — wrapper script: imports binary, runs DecompileAllFunctions.java
  - DecompileAllFunctions.java installed to Ghidra decompiler scripts directory
  - Output written to /tmp/decompiled.c (or specified path)
  - Ghidra 11.3.1 removed (superseded by 12.0.4)
  - Ghidra native binaries chmod +x applied (decompile, demangler_gnu_v2_41)

### Exploitation / CTF Tools
- one_gadget 1.10.0 — one-shot RCE gadget finder (Ruby gem)
- seccomp-tools 2 gems — seccomp filter analysis
  - RubyGems updated (noted for git commit)
- heaptrace 2.2.8 — heap operation tracer for exploit dev

### Fuzzing
- AFL++ — coverage-guided fuzzer, full install with gcc_plugin
- honggfuzz 2.6 — structure-aware fuzzer
  - Deps: libunwind 1.8.1 (headers manually installed from source)
  - libiberty built from binutils-2.45 source, installed to /usr/lib/
  - Makefile patched: added -lz, -lzstd, -lsframe, -liberty to ARCH_LDFLAGS
  - libhfuzz.so skipped (libbfd.a not -fPIC compiled); main binary + hfuzz-cc installed manually

### Dynamic Instrumentation
- frida + frida-tools — dynamic instrumentation toolkit (pip3)

---

## DNS + Network Recon Stack — 2026-04-08

### DNS Configuration
- Systemwide DNS changed to Quad9 (9.9.9.9) via /etc/resolv.conf

### Firefox Read Aloud (Text-to-Speech) Debugging
- Symptom: Read Aloud extension opened, showed text preview, then closed silently
- Initial suspicion: DNS blocking by Quad9 — ruled out via dig + curl tests
  (translate.google.com and translate.googleapis.com resolve and return HTTP 200)
- speechSynthesis.getVoices() returning empty array — no local voices installed
- Root cause identified via about:debugging → Read Aloud extension inspector:
  - Error: Timeout WebSpeech getVoices (no speech-dispatcher installed)
  - Error: Failed to fetch https://cxl-services.appspot.com/proxy?url=https://texttospeech.googleapis.com/...
  - HTTP 503 from cxl-services.appspot.com — Read Aloud's Google WaveNet proxy is degraded
- Resolution: switched voice engine from Google WaveNet to Microsoft in Read Aloud settings
  Microsoft voices use a different endpoint not routed through cxl-services proxy
- Long-term fix: install speech-dispatcher + espeak-ng for local WebSpeech fallback
  (deferred — not required while Microsoft voice is working)
- sudo DNS routing issue identified as side effect of this investigation:
  Default WireGuard route (link-scope, no gateway) prevents root from resolving DNS
  Fixed: sudo ip route add default via 10.6.0.1 dev wg0 metric 50
  (required for r2pm, any sudo tool that fetches from network)

### Network Recon / Pentest Stack

#### DNS Tools
- bind 9.20.22 — dig, host, nslookup, full DNS toolset
  - Deps: userspace-rcu 0.15.1, libuv 1.50.0
  - Built --disable-doh (nghttp2 not installed)

#### Network Discovery
- whois 5.5.23 — domain/IP WHOIS queries
- traceroute 2.1.5 — network path tracing
- mtr 0.95 — combined traceroute+ping, live per-hop stats
- arp-scan 1.10.0 — ARP-based host discovery
- netdiscover 0.10 — passive/active ARP recon
  - GCC 15 fix: usage() prototype corrected (void → char *)
- nbtscan 1.7.2 — NetBIOS name enumeration

#### LDAP / SMB
- openldap 2.6.13 — ldapsearch + client libs (--disable-slapd)
- enum4linux-ng 1.3.10 — Windows/Samba enumeration (Python)
  - impacket 0.13.0, ldap3 2.9.1, ldapdomaindump 0.10.0 installed
  - Pending: smbclient (samba build) for full functionality

#### SNMP
- net-snmp 5.9.4 — snmpwalk, snmpget, full SNMP toolset
- onesixtyone 0.3.4 — fast SNMP community string scanner

#### Go-based Recon
- dnsx 1.2.3 — DNS enumeration and brute force
- subfinder — subdomain discovery
- amass — attack surface mapping (OWASP)

#### Notes
- Go tools installed to ~/go/bin; PATH export required:
  export PATH=$PATH:/usr/local/go/bin:~/go/bin

---

## RE / Binary Exploitation Stack — 2026-04-08

### System Tracing
- strace 6.13 — system call tracer
- ltrace 0.8.1 — library call tracer (built from git, no formal release)
- valgrind 3.24.0 — memory error detector, profiler

### Disassembly / Emulation Frameworks
- capstone 5.0.6 — disassembly framework (C + Python bindings)
- keystone 0.9.2 — assembler framework (C + Python bindings)
  - GCC 15 fixes: #include <cstdint> added to STLExtras.h, -std=c++14
- unicorn 2.1.3 — CPU emulator framework (C + Python bindings)

### Binary Analysis (Python)
- pyelftools — ELF parsing library
- pefile — PE file analysis
- checksec.py — binary hardening checker
- z3-solver — SMT solver (angr dependency)
- angr — binary analysis framework

### Reverse Engineering Tools
- rizin 0.9.0 — radare2 fork, modern RE framework
  - rz-ghidra: abandoned — API incompatibility with rizin 0.9.0 at all tagged versions
- r2dec — radare2 decompiler plugin (installed via r2pm)
  - sudo DNS fix required for r2pm -U to reach GitHub
- Ghidra headless decompiler — CLI wrapper around Ghidra 12.0.4
  - /usr/local/bin/ghidra-headless → /opt/ghidra_12.0.4_PUBLIC/support/analyzeHeadless
  - /usr/local/bin/decompile — wrapper script: imports binary, runs DecompileAllFunctions.java
  - DecompileAllFunctions.java installed to Ghidra decompiler scripts directory
  - Output written to /tmp/decompiled.c (or specified path)
  - Ghidra 11.3.1 removed (superseded by 12.0.4)
  - Ghidra native binaries chmod +x applied (decompile, demangler_gnu_v2_41)

### Exploitation / CTF Tools
- one_gadget 1.10.0 — one-shot RCE gadget finder (Ruby gem)
- seccomp-tools 2 gems — seccomp filter analysis
  - RubyGems updated (noted for git commit)
- heaptrace 2.2.8 — heap operation tracer for exploit dev

### Fuzzing
- AFL++ — coverage-guided fuzzer, full install with gcc_plugin
- honggfuzz 2.6 — structure-aware fuzzer
  - Deps: libunwind 1.8.1 (headers manually installed from source)
  - libiberty built from binutils-2.45 source, installed to /usr/lib/
  - Makefile patched: added -lz, -lzstd, -lsframe, -liberty to ARCH_LDFLAGS
  - libhfuzz.so skipped (libbfd.a not -fPIC compiled); main binary + hfuzz-cc installed manually

### Dynamic Instrumentation
- frida + frida-tools — dynamic instrumentation toolkit (pip3)

---

## DNS + Network Recon Stack — 2026-04-08

### DNS Configuration
- Systemwide DNS changed to Quad9 (9.9.9.9) via /etc/resolv.conf

### Firefox Read Aloud (Text-to-Speech) Debugging
- Symptom: Read Aloud extension opened, showed text preview, then closed silently
- Initial suspicion: DNS blocking by Quad9 — ruled out via dig + curl tests
  (translate.google.com and translate.googleapis.com resolve and return HTTP 200)
- speechSynthesis.getVoices() returning empty array — no local voices installed
- Root cause identified via about:debugging → Read Aloud extension inspector:
  - Error: Timeout WebSpeech getVoices (no speech-dispatcher installed)
  - Error: Failed to fetch https://cxl-services.appspot.com/proxy?url=https://texttospeech.googleapis.com/...
  - HTTP 503 from cxl-services.appspot.com — Read Aloud's Google WaveNet proxy is degraded
- Resolution: switched voice engine from Google WaveNet to Microsoft in Read Aloud settings
  Microsoft voices use a different endpoint not routed through cxl-services proxy
- Long-term fix: install speech-dispatcher + espeak-ng for local WebSpeech fallback
  (deferred — not required while Microsoft voice is working)
- sudo DNS routing issue identified as side effect of this investigation:
  Default WireGuard route (link-scope, no gateway) prevents root from resolving DNS
  Fixed: sudo ip route add default via 10.6.0.1 dev wg0 metric 50
  (required for r2pm, any sudo tool that fetches from network)

### Network Recon / Pentest Stack

#### DNS Tools
- bind 9.20.22 — dig, host, nslookup, full DNS toolset
  - Deps: userspace-rcu 0.15.1, libuv 1.50.0
  - Built --disable-doh (nghttp2 not installed)

#### Network Discovery
- whois 5.5.23 — domain/IP WHOIS queries
- traceroute 2.1.5 — network path tracing
- mtr 0.95 — combined traceroute+ping, live per-hop stats
- arp-scan 1.10.0 — ARP-based host discovery
- netdiscover 0.10 — passive/active ARP recon
  - GCC 15 fix: usage() prototype corrected (void → char *)
- nbtscan 1.7.2 — NetBIOS name enumeration

#### LDAP / SMB
- openldap 2.6.13 — ldapsearch + client libs (--disable-slapd)
- enum4linux-ng 1.3.10 — Windows/Samba enumeration (Python)
  - impacket 0.13.0, ldap3 2.9.1, ldapdomaindump 0.10.0 installed
  - Pending: smbclient (samba build) for full functionality

#### SNMP
- net-snmp 5.9.4 — snmpwalk, snmpget, full SNMP toolset
- onesixtyone 0.3.4 — fast SNMP community string scanner

#### Go-based Recon
- dnsx 1.2.3 — DNS enumeration and brute force
- subfinder — subdomain discovery
- amass — attack surface mapping (OWASP)

#### Notes
- Go tools installed to ~/go/bin; PATH export required:
  export PATH=$PATH:/usr/local/go/bin:~/go/bin

---

## RE / Binary Exploitation Stack — 2026-04-08

### System Tracing
- strace 6.13 — system call tracer
- ltrace 0.8.1 — library call tracer (built from git, no formal release)
- valgrind 3.24.0 — memory error detector, profiler

### Disassembly / Emulation Frameworks
- capstone 5.0.6 — disassembly framework (C + Python bindings)
- keystone 0.9.2 — assembler framework (C + Python bindings)
  - GCC 15 fixes: #include <cstdint> added to STLExtras.h, -std=c++14
- unicorn 2.1.3 — CPU emulator framework (C + Python bindings)

### Binary Analysis (Python)
- pyelftools — ELF parsing library
- pefile — PE file analysis
- checksec.py — binary hardening checker
- z3-solver — SMT solver (angr dependency)
- angr — binary analysis framework

### Reverse Engineering Tools
- rizin 0.9.0 — radare2 fork, modern RE framework
  - rz-ghidra: abandoned — API incompatibility with rizin 0.9.0 at all tagged versions
- r2dec — radare2 decompiler plugin (installed via r2pm)
  - sudo DNS fix required for r2pm -U to reach GitHub
- Ghidra headless decompiler — CLI wrapper around Ghidra 12.0.4
  - /usr/local/bin/ghidra-headless → /opt/ghidra_12.0.4_PUBLIC/support/analyzeHeadless
  - /usr/local/bin/decompile — wrapper script: imports binary, runs DecompileAllFunctions.java
  - DecompileAllFunctions.java installed to Ghidra decompiler scripts directory
  - Output written to /tmp/decompiled.c (or specified path)
  - Ghidra 11.3.1 removed (superseded by 12.0.4)
  - Ghidra native binaries chmod +x applied (decompile, demangler_gnu_v2_41)

### Exploitation / CTF Tools
- one_gadget 1.10.0 — one-shot RCE gadget finder (Ruby gem)
- seccomp-tools 2 gems — seccomp filter analysis
  - RubyGems updated (noted for git commit)
- heaptrace 2.2.8 — heap operation tracer for exploit dev

### Fuzzing
- AFL++ — coverage-guided fuzzer, full install with gcc_plugin
- honggfuzz 2.6 — structure-aware fuzzer
  - Deps: libunwind 1.8.1 (headers manually installed from source)
  - libiberty built from binutils-2.45 source, installed to /usr/lib/
  - Makefile patched: added -lz, -lzstd, -lsframe, -liberty to ARCH_LDFLAGS
  - libhfuzz.so skipped (libbfd.a not -fPIC compiled); main binary + hfuzz-cc installed manually

### Dynamic Instrumentation
- frida + frida-tools — dynamic instrumentation toolkit (pip3)

---

## Web Application Testing Stack — 2026-04-08

### Go-based Tools
- nuclei — template-based vulnerability scanner (ProjectDiscovery)
- httpx — HTTP probe and fingerprinting tool (ProjectDiscovery)
- katana — web crawler and spidering framework (ProjectDiscovery)
- dalfox — XSS scanner and parameter analysis tool
- cariddi — web crawler with secrets/endpoint discovery

### Python-based Tools
- wapiti3 — black-box web application vulnerability scanner (pip3)
- commix v4.2.dev16 — automated command injection exploitation
  - setup.py install to /usr/lib/python3.13/site-packages/
  - /usr/bin/commix wrapper: cd /sources/commix && python3 commix.py
- mitmproxy — CLI/TUI intercepting proxy for HTTP/HTTPS traffic analysis (pip3)

### Notes
- All Go tools installed to ~/go/bin
- PATH must include /usr/local/go/bin:~/go/bin for Go tools to be accessible
- Previously installed (complete): curl, ffuf, nikto, sqlmap, gobuster

## NVMe Migration — 2026-04-10

### Problem
SableLinux running on SATA SSD (sda). Migrated to WD SN560 1TB NVMe (nvme1n1).
Multiple boot failures across two sessions. Root causes identified and fixed.

### Root Causes (in order of discovery)
1. **initramfs hardcoded /dev/sda3** — init script used raw device path, not UUID. NVMe root is nvme1n1p3, not sda3. Fixed by rewriting init to use `findfs UUID=`.
2. **CONFIG_BLK_DEV_NVME not set** — original 6.16.1 kernel had NVMe explicitly disabled. Rebuilt with CONFIG_NVME_CORE=y + CONFIG_BLK_DEV_NVME=y.
3. **fstab EFI UUID wrong** — restored from SATA backup, /boot/efi entry had old SATA EFI UUID (5F1D-6806). NVMe EFI UUID is 3745-AF41. Fixed with sed.
4. **CONFIG_NLS_CP437 + CONFIG_NLS_ISO8859_1 missing** — vfat /boot/efi mount failed with "IO charset iso8859-1 not found". Added both NLS options, rebuilt kernel.
5. **boot-efi.mount blocking systemd** — without nofail, EFI mount failure dropped system to emergency mode. Added nofail to fstab entry.

### Kernel 6.16.1 rebuild #3
- Added: CONFIG_NVME_CORE=y, CONFIG_BLK_DEV_NVME=y
- Added: CONFIG_NLS_CP437=y, CONFIG_NLS_ISO8859_1=y
- Added: CONFIG_FB=y, CONFIG_FB_EFI=y, CONFIG_FRAMEBUFFER_CONSOLE=y (console visibility)
- make -j14, modules_install, bzImage copied to /boot

### initramfs init script
- Rewrote /opt/initramfs-tools/sable-init to use findfs UUID= instead of hardcoded /dev/sda3
- Drops to shell with error message if UUID resolution fails
- Initramfs rebuilt and verified

### fstab fixes
- /boot/efi UUID: 5F1D-6806 → 3745-AF41
- Added nofail option to /boot/efi mount entry

### GRUB
- grub-install run from chroot (efibootmgr missing — non-fatal, grubx64.efi already in place)
- grub-mkconfig regenerated clean config with 6.16.1 kernel only
- Ubuntu kernel files (vmlinuz-6.17.0-20-generic, initrd) removed from Sable /boot

### Result
SableLinux boots cleanly on NVMe. systemd fully initializes. Sway + amdgpu working on card1.

## Post-NVMe Migration Cleanup — 2026-04-11

### Firmware additions
- rtl_nic/rtl8125d-1.fw — Realtek RTL8125D NIC firmware (wget from linux-firmware.git)
- regulatory.db + regulatory.db.p7s — WiFi regulatory database (wget from wireless-regdb.git)
- Both installed to /lib/firmware/, take effect on next reboot

### usbutils 0.17
- Required libusb 1.0.27 (built first)
- Provides lsusb for USB device enumeration
- Confirmed: Foxconn/Hon Hai MediaTek WiFi adapter on Bus 003, WD Elements 4.5TB on Bus 004

### Security assessment
- CVE-2025-14302 (Z890 IOMMU pre-boot DMA): patched — running BIOS F19 (2026-02-02)
- IOMMU active: all 32 PCIe devices assigned to IOMMU groups per dmesg
- Secure Boot deferred to RC phase as planned

---

## ISO Distribution Pipeline — Phase 1 & 2
**Date:** 2026-04-11

### Phase 1 — Kernel Rebuild #3 (Generic Hardware Support)
- Added: CONFIG_SQUASHFS=y (live ISO root — was missing, hard blocker)
- Added: CONFIG_OVERLAY_FS=y (live writable layer — was missing, hard blocker)
- Added: CONFIG_DRM_NOUVEAU=m (NVIDIA hardware)
- Added: CONFIG_DRM_VMWGFX=m (VMware/QEMU)
- Added: CONFIG_DRM_BOCHS=m (QEMU bochs display)
- Added: CONFIG_IGB=m (Intel GbE)
- Added: CONFIG_IXGBE=m (Intel 10GbE)
- Added: CONFIG_INPUT_MOUSEDEV=y (mouse input)
- Added: CONFIG_IWLWIFI=m (Intel WiFi)
- Kernel rebuild #9 successful, initramfs rebuilt, system boots clean

### Phase 2 — Live Environment Construction
- squashfs-tools 4.6.1 built with zstd/xz/lz4/gzip support
- xorriso 1.5.6 built
- mtools 4.0.44 built (mformat required by grub-mkrescue)
- Live filesystem staged at /mnt/liveroot (25G uncompressed)
- Exclusions: /sources, /swapfile, /home/pepper, /var/lib/qemu/disks+iso,
  coredumps, logs, machine-id, SSH host keys, tester user removed
- Live user: sable (uid 1000, wheel group, NOPASSWD sudo, autologin tty1)
- sway config adapted for sable user, WLR_DRM_DEVICES removed for portability
- machine-id cleared, fstab replaced, SSH host keys removed
- squashfs.img: 6.3G compressed (26% of 25G uncompressed), zstd level 19
- Live initramfs: busybox-based, squashfs+overlayfs pivot_root init script
- ISO assembled with xorriso -iso-level 3 (required for >4GB files)
- Hybrid UEFI+BIOS bootable ISO: sablelinux-live-2026-04-11.iso (6.3G)
- Backup saved to /mnt/one/backups/

### Tools Added
- squashfs-tools 4.6.1 (/usr/local/bin/mksquashfs, unsquashfs)
- xorriso 1.5.6 (/bin/xorriso)
- mtools 4.0.44 (/bin/mformat)

### Key Learnings
- xorriso requires -iso-level 3 for files >4GB (squashfs exceeded ISO 9660 limit)
- grub-mkrescue cannot be used directly for large files — call xorriso directly
- busybox at /opt/initramfs-tools/bin/busybox is statically linked — suitable for initramfs
- WLR_DRM_DEVICES must not be hardcoded in live ISO sway config
- opt/jdk symlink pointed to jdk-21.0.2 (incomplete) — fixed to jdk-21 (full Temurin build)

## ISO Live Boot Testing — 2026-04-11

### Issues Found and Fixed
- pepper user UID conflict with sable (both 1000) — removed pepper from squashfs passwd/group
- /run/user/1000 not created — added mkdir to sable .bash_profile
- sable missing video/render/input/seat groups — fixed in squashfs
- init script set -e causing silent failures — removed, added explicit error handling

### Remaining Blocker
- iris Gallium driver missing from Mesa build — Intel iGPU (Skylake/2015 hardware) cannot initialize
- Blocked on: libclc → SPIRV-LLVM-Translator → Mesa rebuild with -Dgallium-drivers=radeonsi,llvmpipe,iris
- AMD hardware boots fine, Intel integrated GPU does not

### Next Session
- Build libclc + SPIRV-LLVM-Translator
- Rebuild Mesa with iris driver added
- Rebuild squashfs/ISO and retest

## 2026-04-13 — Phase 0: Mesa 25.0.1 iris rebuild

- Added iris to gallium-drivers, retained radeonsi + llvmpipe
- vulkan-drivers: amd only (intel blocked by SPIRV-Tools/mesa-clc at configure time)
- Required SPIRV-Tools upgrade: 2024.4 built against SPIRV-Headers vulkan-sdk-1.4.304.0
- iris_dri.so installed to /usr/lib64/dri/
- maya now has hardware-accelerated display path via i915/iris
- pots radeonsi unaffected

## 2026-04-13 — Phase 1: Kernel compat build (6.16.1-sable-compat)

- Based on existing SableLinux .config with LOCALVERSION="-sable-compat"
- Added: IWLMVM=m, IWLDVM=m, BT=m, BT_HCIBTUSB=m, BT_INTEL=m
- Added: MMC=m, MISC_RTSX_USB=m, MMC_REALTEK_USB=m
- Added: ASUS_WMI=m, ASUS_NB_WMI=m, INTEL_RAPL_CORE=m
- DRM_I915, SQUASHFS, OVERLAY_FS already present and correct
- Installed to /boot/vmlinuz-6.16.1-sable-compat
- Modules in /lib/modules/6.16.1-sable-compat/
- Running kernel (6.16.1-lfs-12.4-systemd) untouched

## 2026-04-13 — Phase 1: Kernel compat build (6.16.1-sable-compat)

- Based on existing SableLinux .config with LOCALVERSION="-sable-compat"
- Added: IWLMVM=m, IWLDVM=m, BT=m, BT_HCIBTUSB=m, BT_INTEL=m
- Added: MMC=m, MISC_RTSX_USB=m, MMC_REALTEK_USB=m
- Added: ASUS_WMI=m, ASUS_NB_WMI=m, INTEL_RAPL_CORE=m
- DRM_I915, SQUASHFS, OVERLAY_FS already present and correct
- Installed to /boot/vmlinuz-6.16.1-sable-compat
- Modules in /lib/modules/6.16.1-sable-compat/
- Running kernel (6.16.1-lfs-12.4-systemd) untouched

## 2026-04-13 — Phase 2: Firmware bundle

- Cloned linux-firmware to /sources/linux-firmware
- Installed iwlwifi (7265D, 7265, 7260, 8265, 9260, QuZ) to /lib/firmware/intel/iwlwifi/
- Installed i915 Skylake firmware (skl_*) to /lib/firmware/i915/
- Installed Intel BT firmware (ibt-hw-37.8*) to /lib/firmware/intel/
- regulatory.db already present
- All mandatory maya firmware confirmed present

## partclone 0.3.47 — 2026-04-23

- Source: https://github.com/Thomas-Tsai/partclone/archive/refs/tags/0.3.47.tar.gz
- autoreconf -fiv required (no configure script in tarball)
- ./configure --prefix=/usr --enable-ext4
- make -j14 && sudo make -C src install
- docs install fails (xsltproc missing) — binaries install cleanly via src target
- partclone.ext4 symlink: sudo ln -s /usr/sbin/partclone.imager /usr/sbin/partclone.ext4
- Verified: partclone.ext4 --version → v0.3.47

## ROCm 7.2.2 — GPU Inference Stack (2026-04-24)

### Method: AMD Ubuntu .deb extraction (Option B)
- No source compilation — extracted binaries from AMD official Ubuntu 24.04 packages
- patchelf not required — all RPATHs are $ORIGIN-relative, install path matches deb expectation

### Packages extracted to /opt/rocm-7.2.2
- hsa-rocr 1.18.0 + hsa-rocr-dev
- hip-runtime-amd 7.2.53211 + hip-dev
- hipcc 1.1.1
- rocm-device-libs 1.0.0
- comgr 3.0.0
- rocblas 5.2.0 + rocblas-dev
- hipblas 3.2.0 + hipblas-dev + hipblas-common-dev
- hipblaslt 1.2.2 + hipblaslt-dev
- rocsolver 3.32.0
- roctracer 4.1.70202
- rocprofiler-register 0.6.0
- rocminfo 1.0.0
- rocm-core 7.2.2
- rocm-llvm 22.0.0 (AMD clang 22 — required for gfx1201 bitcode)

### Additional dependencies built from source
- numactl 2.0.18 (libnuma required by ROCm runtime)

### Configuration fixes
- /opt/rocm-7.2.2/lib/llvm/bin/clang + clang++ — wrapper scripts calling amdclang/amdclang++
- amdclang/amdclang++ symlinked to clang-22 (amdllvm shell dispatch was broken)
- /opt/rocm-7.2.2/share/hip/version — key=value format required by hipvars.pm
- /etc/ld.so.conf.d/rocm.conf — /opt/rocm-7.2.2/lib

### llama.cpp HIP build
- Built from source (ggml-org/llama.cpp master) with DGGML_HIP=ON, DAMDGPU_TARGETS=gfx1201
- AMD clang 22 used for HIP kernel compilation

### Validation
- HSA_OVERRIDE_GFX_VERSION=12.0.1 required (rocm_agent_enumerator reports gfx1200)
- Device detected: AMD Radeon Graphics, gfx1201, 16304 MiB VRAM
- Model: Llama-3.2-1B-Instruct-Q4_K_M.gguf
- Generation speed: 147 t/s — GPU fully utilized

## ROCm 7.2.2 + llama.cpp HIP — AI Inference Stack Complete (2026-04-24)

### llama-server systemd service
- /etc/systemd/system/llama-server.service
- User: pepper, auto-starts at boot
- Model: DeepSeek-R1-Distill-Qwen-14B-Q4_K_M.gguf
- Flags: -ngl 999 --reasoning-format deepseek --host 0.0.0.0 --port 8080

### Client tooling
- /usr/local/bin/sable-ai — interactive llama-cli wrapper, HSA_OVERRIDE_GFX_VERSION set
- /usr/local/bin/ds — Python API client for llama-server
  - Clean output by default (no markdown, no LaTeX)
  - --think flag toggles reasoning display
  - Interactive mode when called with no prompt argument

### Models at /opt/models/
- Llama-3.2-1B-Instruct-Q4_K_M.gguf (~800MB) — default sable-ai model
- DeepSeek-R1-Distill-Qwen-14B-Q4_K_M.gguf (8.99GB) — server default

### numactl 2.0.18
- Built from source, libnuma required by ROCm HSA runtime

## Local Inference Security Audit & Hardening — 2026-04-28

### Context
Conducted a full persistence audit of the local DeepSeek inference workflow (ds CLI → llama-server → llama.cpp) to enumerate and eliminate all surfaces where query/response content could be recorded without explicit action.

### Audit Findings — Persistence Surfaces

**Clean (no content exposure):**
- `ds` wrapper script — pure HTTP POST to localhost:8080, stdout only, no logging, no tee, no side channels
- llama-server journal output — default verbosity logs only metadata (token counts, timing, slot IDs, POST confirmations); request bodies NOT logged
- No log files found on disk (~/.local/share/llama*, ~/.cache/llama*, /var/log/llama* — all absent)

**Required remediation:**
- ~/.bash_history — ds invocations recorded verbatim with full query strings; HISTCONTROL was unset
- Current in-memory shell history — not written until session ends
- systemd journal for llama-server.service — timestamp/metadata records (no content, but worth vacuuming)
- llama-server bound to 0.0.0.0 — inference endpoint exposed to full LAN, not just localhost

**In-RAM surface (volatile, non-persistent):**
- llama-server prompt KV cache — ~1.1GB in-memory cache of recent prompt token sequences across 4 slots; cleared on service restart

### Remediation Implemented

Scripts committed to sablelinux/docs/:
- wipe-cp.sh — Wayland clipboard wipe; two-pass overwrite (random base64 noise then --clear) on both clipboard and primary selection surfaces; no XWayland present so no X11 clipboard triple needed
- wipe-ds.sh — Full ds trace wipe: bash history file truncation, in-session history -c, journal vacuum for llama-server.service unit

Shell hardening added to ~/.bashrc:
- HISTCONTROL=ignoreboth:erasedups
- HISTIGNORE="ds *:ds"
Prevents ds queries from accumulating in history going forward; deduplicates all history entries.

llama-server.service unit hardened:
- Changed --host 0.0.0.0 to --host 127.0.0.1
- Inference endpoint now localhost-only; LAN exposure eliminated
- sudo systemctl daemon-reload && sudo systemctl restart llama-server.service applied

### Key Learnings
- llama-server stdout/stderr pipe to journald when launched as a systemd unit (fd/1 and fd/2 to socket:[N] to /run/systemd/journal/stdout); --log-file absent does NOT mean journal-free
- llama-server default verbosity does not log prompt/response content — token counts and timing only
- HISTCONTROL unset on a fresh LFS bash install — must be explicitly set; not inherited from any default profile
- 0.0.0.0 binding in service unit is a silent footgun; always scope inference endpoints to 127.0.0.1 unless LAN access is explicitly required
- In-memory prompt cache is the last volatile surface; cleared by service restart or via POST /slots/{id}?action=erase

## Local Inference Security Audit & Hardening — 2026-04-28

### Context
Conducted a full persistence audit of the local DeepSeek inference workflow (ds CLI → llama-server → llama.cpp) to enumerate and eliminate all surfaces where query/response content could be recorded without explicit action.

### Audit Findings — Persistence Surfaces

**Clean (no content exposure):**
- `ds` wrapper script — pure HTTP POST to localhost:8080, stdout only, no logging, no tee, no side channels
- llama-server journal output — default verbosity logs only metadata (token counts, timing, slot IDs, POST confirmations); request bodies NOT logged
- No log files found on disk (~/.local/share/llama*, ~/.cache/llama*, /var/log/llama* — all absent)

**Required remediation:**
- ~/.bash_history — ds invocations recorded verbatim with full query strings; HISTCONTROL was unset
- Current in-memory shell history — not written until session ends
- systemd journal for llama-server.service — timestamp/metadata records (no content, but worth vacuuming)
- llama-server bound to 0.0.0.0 — inference endpoint exposed to full LAN, not just localhost

**In-RAM surface (volatile, non-persistent):**
- llama-server prompt KV cache — ~1.1GB in-memory cache of recent prompt token sequences across 4 slots; cleared on service restart

### Remediation Implemented

Scripts committed to sablelinux/docs/:
- wipe-cp.sh — Wayland clipboard wipe; two-pass overwrite (random base64 noise then --clear) on both clipboard and primary selection surfaces; no XWayland present so no X11 clipboard triple needed
- wipe-ds.sh — Full ds trace wipe: bash history file truncation, in-session history -c, journal vacuum for llama-server.service unit

Shell hardening added to ~/.bashrc:
- HISTCONTROL=ignoreboth:erasedups
- HISTIGNORE="ds *:ds"
Prevents ds queries from accumulating in history going forward; deduplicates all history entries.

llama-server.service unit hardened:
- Changed --host 0.0.0.0 to --host 127.0.0.1
- Inference endpoint now localhost-only; LAN exposure eliminated
- sudo systemctl daemon-reload && sudo systemctl restart llama-server.service applied

### Key Learnings
- llama-server stdout/stderr pipe to journald when launched as a systemd unit (fd/1 and fd/2 to socket:[N] to /run/systemd/journal/stdout); --log-file absent does NOT mean journal-free
- llama-server default verbosity does not log prompt/response content — token counts and timing only
- HISTCONTROL unset on a fresh LFS bash install — must be explicitly set; not inherited from any default profile
- 0.0.0.0 binding in service unit is a silent footgun; always scope inference endpoints to 127.0.0.1 unless LAN access is explicitly required
- In-memory prompt cache is the last volatile surface; cleared by service restart or via POST /slots/{id}?action=erase

## Local Inference Security Audit & Hardening — 2026-04-28

### Context
Conducted a full persistence audit of the local DeepSeek inference workflow (ds CLI → llama-server → llama.cpp) to enumerate and eliminate all surfaces where query/response content could be recorded without explicit action.

### Audit Findings — Persistence Surfaces

**Clean (no content exposure):**
- `ds` wrapper script — pure HTTP POST to localhost:8080, stdout only, no logging, no tee, no side channels
- llama-server journal output — default verbosity logs only metadata (token counts, timing, slot IDs, POST confirmations); request bodies NOT logged
- No log files found on disk (~/.local/share/llama*, ~/.cache/llama*, /var/log/llama* — all absent)

**Required remediation:**
- ~/.bash_history — ds invocations recorded verbatim with full query strings; HISTCONTROL was unset
- Current in-memory shell history — not written until session ends
- systemd journal for llama-server.service — timestamp/metadata records (no content, but worth vacuuming)
- llama-server bound to 0.0.0.0 — inference endpoint exposed to full LAN, not just localhost

**In-RAM surface (volatile, non-persistent):**
- llama-server prompt KV cache — ~1.1GB in-memory cache of recent prompt token sequences across 4 slots; cleared on service restart

### Remediation Implemented

Scripts committed to sablelinux/docs/:
- wipe-cp.sh — Wayland clipboard wipe; two-pass overwrite (random base64 noise then --clear) on both clipboard and primary selection surfaces; no XWayland present so no X11 clipboard triple needed
- wipe-ds.sh — Full ds trace wipe: bash history file truncation, in-session history -c, journal vacuum for llama-server.service unit

Shell hardening added to /home/pepper/.bashrc:
- HISTCONTROL=ignoreboth:erasedups
- HISTIGNORE="ds *:ds"
Prevents ds queries from accumulating in history going forward; deduplicates all history entries.

llama-server.service unit hardened:
- Changed --host 0.0.0.0 to --host 127.0.0.1
- Inference endpoint now localhost-only; LAN exposure eliminated
- systemctl daemon-reload && systemctl restart llama-server.service applied

### Key Learnings
- llama-server stdout/stderr pipe to journald when launched as a systemd unit (fd/1 and fd/2 to socket:[N] to /run/systemd/journal/stdout); --log-file absent does NOT mean journal-free
- llama-server default verbosity does not log prompt/response content — token counts and timing only
- HISTCONTROL unset on a fresh LFS bash install — must be explicitly set; not inherited from any default profile
- 0.0.0.0 binding in service unit is a silent footgun; always scope inference endpoints to 127.0.0.1 unless LAN access is explicitly required
- In-memory prompt cache is the last volatile surface; cleared by service restart or via POST /slots/{id}?action=erase

## Boot Noise Fix — llama-server userptr pinning (2026-04-28)

### Symptom
3631x `amdgpu: init_user_pages: Failed to get user pages: -1` in dmesg every boot,
appearing at ~t=9.45s. Non-fatal — inference remained functional.

### Root Cause
llama-server starts early in boot (multi-user.target) with -ngl 999. llama.cpp mmaps
the model file (lazy load), then ROCm KFD attempts to pin those un-faulted mmap'd pages
via get_user_pages for GPU DMA. Pages not yet resident → EPERM (-1) × 3631 (one per
retry across the model's memory region). KFD falls back to bounce-buffer path and
proceeds — hence functional inference despite the error storm.

### Fix
Added --no-mmap to llama-server ExecStart. Forces read() instead of mmap() for model
loading, bypassing the userptr pinning path entirely. Zero impact on inference performance.

Also fixed pre-existing bug: --log-disable was missing its continuation backslash and
was being silently ignored. Fixed by adding \ to end of --port 8080 line.

Also added LimitMEMLOCK=infinity and LimitAS=infinity to service unit (precautionary,
applied during diagnosis — no harm leaving in place).

### Result
dmesg: 0 "Failed to get user pages" errors post-reboot.

## Desktop Screenshots — $(date +%Y-%m-%d)
- Added assets/screenshots/ directory to repo
- ranger-fm installed (pip3 install ranger-fm) — TUI file manager
- Sway desktop screenshots captured and committed

## Desktop Utilities — $(date +%Y-%m-%d)

### Thunar 4.20.3 — GTK3 file manager
- Dependencies: libxfce4util 4.20.0, xfconf 4.20.0, libxfce4ui 4.20.0, exo 4.20.0
- autotools build, --prefix=/usr --disable-static --disable-gtk-doc
- Verified: thunar launches, full file management functional

### imv 4.5.0 — Wayland-native image viewer
- Dependencies: ICU 76.1, GLU 9.0.3, libjpeg-turbo 3.1.1
- meson build; ICU pc files patched (Requires.private → Requires) for correct link flags
- Backends: libpng, libturbojpeg (PNG + JPEG support)
- Window systems: wayland, x11
- Verified: PNG and JPEG images display correctly

## Mesa 25.0.1 Rebuild — iris + Intel ANV Added
**Date:** 2026-05-02

### Motivation
ISO validation target (HP Pavilion, i3-8100, UHD 630) requires iris Gallium driver.
Previous Mesa build had radeonsi+llvmpipe only.

### Changes from previous build
- Added: iris Gallium driver
- Added: intel Vulkan driver (ANV)
- All other options identical

### Verified
- /usr/lib/dri/iris_dri.so ✓
- /usr/share/vulkan/icd.d/intel_icd.x86_64.json ✓

## SableLinux Live ISO — First Successful Boot
**Date:** 2026-05-02

### Target Hardware
- HP Pavilion (~2015), Intel Core i3-8100 (Coffee Lake), Intel UHD 630, 16GB RAM, 1TB SATA SSD
- Boot: UEFI, wired ethernet (RTL8111, r8169)

### Architecture
- GPT USB: sdb1=100M vfat EFI, sdb2=14.5G ext4 SABLELINUX
- squashfs (xz, no-xattrs) → overlayfs (tmpfs upper) → switch_root → systemd
- GRUB mkstandalone EFI with ext2/ext4/part_gpt/linux/search modules
- Live user: sable, no password, auto-login on tty1, auto-launch sway

### Key Fixes Required
- wipefs required to clear old iso9660 signature before GPT would be recognized
- GRUB standalone needs --modules="part_gpt fat ext2 linux search" for ext4 read
- squashfs must be built with -no-xattrs
- /etc/fstab must be stripped to tmpfs only — UUID entries cause emergency mode loop
- WLR_DRM_DEVICES=card0 for Intel UHD 630 (not card1)
- iris Gallium driver required in Mesa build for Intel UHD 630

### Result
Sway desktop running on HP Pavilion from live USB. First successful SableLinux live boot.

## WiFi + Bluetooth Firmware Session — 2026-05-05

### Kernel Rebuild #3 — WiFi Module Support
- Identified MT7925 (MediaTek) WiFi on Z890 main board — built-in, firmware missing
- Identified RTL8821CE (Realtek) on HP Pavilion — not compiled
- Identified Intel 7265 on ASUS Q503UA — IWLMVM missing
- Added: CONFIG_IWLMVM=m, CONFIG_RTW88=m, CONFIG_RTW88_CORE=m, CONFIG_RTW88_8821C=m, CONFIG_RTW88_8821CE=m
- Changed: CONFIG_MT7925_COMMON=m, CONFIG_MT7925E=m (was =y, caused firmware timing failure)
- Fixed syncconfig failure: CONFIG_RUST disabled (rustc not installed), mrproper required to clear stale build state
- make -j14, modules_install, bzImage → /boot/vmlinuz-6.16.1-lfs-12.4-systemd

### MT7925 Firmware
- Cloned linux-firmware from kernel.org
- Installed: /lib/firmware/mediatek/mt7925/{WIFI_RAM_CODE_MT7925_1_1.bin,WIFI_MT7925_PATCH_MCU_1_1_hdr.bin,BT_RAM_CODE_MT7925_1_1_hdr.bin}
- wlp131s0 interface confirmed after reboot

### WiFi Connection
- wpa_supplicant 2.11 built from source, installed to /usr/local/sbin
- /etc/wpa_supplicant/wpa_supplicant.conf configured for idoru (WPA2-PSK, 5GHz WiFi 6E)
- /etc/systemd/network/25-wifi.network: DHCP=ipv4, RouteMetric=2048
- wpa_supplicant@wlp131s0.service created and enabled — auto-connects at boot
- WiFi IP: 192.168.0.235, wired priority maintained at metric 1024

### WireGuard Fix
- wg0.conf PostUp/PreDown hardcoded enp132s0 — broke when wired absent
- Replaced with dynamic gateway/interface detection via ip route get
- WireGuard now works over both wired and WiFi

## WiFi/BT Firmware + Live ISO WiFi Session — 2026-05-05

### Kernel Rebuild #4 — Bluetooth Stack
- Added: CONFIG_BT=m, CONFIG_BT_RFCOMM=m, CONFIG_BT_BNEP=m, CONFIG_BT_HIDP=m
- Added: CONFIG_BT_HCIBTUSB=m, CONFIG_BT_MTK=m, CONFIG_BT_INTEL=m, CONFIG_BT_BCM=m, CONFIG_BT_RTL=m
- Bluetooth hci0 confirmed working on main box (MT7925 BT)

### Firmware Installed (main box + liveroot)
- mediatek/mt7925: WIFI_RAM_CODE_MT7925_1_1.bin, WIFI_MT7925_PATCH_MCU_1_1_hdr.bin, BT_RAM_CODE_MT7925_1_1_hdr.bin
- intel/iwlwifi: iwlwifi-7265D-29.ucode (+ symlinks D-22 through D-28)
- rtw88/rtw8821c_fw.bin
- Firmware added to initramfs (/opt/initramfs-tools/lib/firmware) — required for early boot loading

### Live ISO Fixes
- /etc/systemd/network/25-wifi.network added to liveroot (DHCP=ipv4, RouteMetric=2048)
- /etc/modules-load.d/wifi.conf: iwlmvm, rtw88_8821ce — autoload at boot
- /usr/local/bin/wifi-connect script — interactive WiFi connection helper
- wpa_supplicant 2.11 binaries in liveroot
- initramfs rebuilt with correct live init (findfs LABEL=SABLELINUX) + firmware

### Validated
- Main box (Z890/MT7925): WiFi wlp131s0 online, WireGuard dynamic routing fixed
- HP Pavilion (i3-8100/RTL8821CE): WiFi working via wifi-connect
- ASUS Q503UA (Skylake/Intel 7265): WiFi working via wifi-connect + modprobe iwlmvm

## 2026-05-09 — Live ISO USB-C Drive + PipeWire Fix

### USB-C Live Drive (SanDisk 3.2Gen1, 114.6GB)
- New drive partitioned with sgdisk: GPT, 3 partitions
  - sdd1: 100M vfat EFI (dd cloned from working Cruzer Glide)
  - sdd2: 40G ext4 LABEL=SABLELINUX (files copied from sdc2)
  - sdd3: 74.5G ext4 LABEL=storage
- Confirmed bootable from USB-C port on HP Pavilion (i3-8100)
- BIOS: Legacy Support disabled, Secure Boot disabled, pure UEFI mode

### PipeWire Autostart Fix (installed system)
- Root cause: installed system had no PipeWire systemd user service symlinks
- ulimit -n was 1024 (default) — raised to 65536 via /etc/security/limits.d/99-filedesc.conf
- pam_limits.so added to /etc/pam.d/system-session
- Fix: baked systemd user service symlinks into /etc/skel in liveroot so all installed users inherit them:
  - default.target.wants/pipewire.service
  - default.target.wants/pipewire-pulse.service
  - default.target.wants/wireplumber.service
  - sockets.target.wants/pipewire.socket
  - sockets.target.wants/pipewire-pulse.socket
  - pipewire.service.wants/wireplumber.service
- Squashfs rebuilt and deployed to both USB drives (sdc + sdd)
- Validated: SableLinux installed to ASUS Q503UA (maya) — Sway + waybar + audio all working

### Key Learnings
- Backup compression: use pigz -1 -p 14 instead of gzip -9 (14x faster, restore with pigz -dc)
- USB-C port on HP Pavilion is boot-capable in pure UEFI mode (Legacy Support must be off)
- PipeWire must be enabled via systemd user services on installed system — audio-init.sh approach used in live ISO is not sufficient post-install
- /etc/skel is the correct place to bake in user-level systemd service symlinks for new installs

## CVE-2026-31431 + Microcode Update — 2026-05-10

### CVE-2026-31431 ("Copy Fail") — CVSS 7.8 — LPE via algif_aead
- Upstream patch: mainline commit a664bf3d603d (Herbert Xu, 2026-03-26)
- Affected: crypto/algif_aead.c — in-place cipher operation memory mismanagement
- Fix: reverts in-place operation in algif_aead, operates out-of-place
- Files patched: crypto/af_alg.c, crypto/algif_aead.c, crypto/algif_skcipher.c, include/crypto/if_alg.h
- Applied cleanly to 6.16.1 tree (minor offsets only)
- Kernel rebuilt: bzImage #2, make -j14
- make modules_install completed
- bzImage copied to /boot/vmlinuz-6.16.1-lfs-12.4-systemd
- initramfs rebuilt via build/make-initramfs.sh → /boot/initrd.img-6.16.1-lfs-12.4-systemd (25M)

### Intel Microcode — Arrow Lake-S (Core Ultra 245K)
- Issue: x86/CPU: Model not found in latest microcode list at boot
- CPU: family 0x6, model 0xc6, stepping 0x2 — not in previous intel-ucode bundle
- Fix: fetched 06-c6-02 from intel/Intel-Linux-Processor-Microcode-Data-Files (git)
- Installed to /lib/firmware/intel-ucode/ and /opt/initramfs-tools/lib/firmware/intel-ucode/
- initramfs rebuilt to include updated microcode for early load

### liveroot sync
- /mnt/liveroot/boot/vmlinuz and initramfs updated
- /mnt/liveroot/lib/firmware/intel-ucode/06-c6-02 installed
- /mnt/liveroot/lib/modules/6.16.1/ rsynced

## sable-install Fixes + Live ISO Rebuild — 2026-05-10

### Problems Fixed

#### 1. iwlwifi firmware path bug
- `cp /lib/firmware/iwlwifi-7265D-*.ucode` glob expanded to nothing — files are at
  `/lib/firmware/intel/iwlwifi/iwlwifi-7265D-*.ucode`
- Fixed in both `$IWORK` (initramfs) and `$TARGET` (installed root) sections
- Firmware now copies flat to `$IWORK/lib/firmware/` and `$TARGET/lib/firmware/`
  (kernel firmware loader does not recurse subdirectories)

#### 2. KVER detection wrong host
- `KVER=$(uname -r)` on z890 returns `6.16.1-lfs-12.4-systemd`
- Installed system needs `6.16.1-sable-compat` — the live USB kernel
- Fixed: `KVER=$(uname -r)` runs on the ASUS during install, returns correct value
- Was previously set after the initramfs cpio build — moved before `TOOLS=` line

#### 3. Dracut initramfs on live USB
- Previous initramfs-live.img was a dracut archive, not our busybox init
- Rebuilt with canonical busybox/switch_root/findfs LABEL=SABLELINUX procedure

#### 4. iwlwifi.ko missing from liveroot
- `/mnt/liveroot/lib/modules/6.16.1-sable-compat/` was missing:
  - `kernel/drivers/net/wireless/intel/iwlwifi/iwlwifi.ko` (transport layer)
  - `kernel/drivers/net/wireless/intel/iwlwifi/dvm/iwldvm.ko`
  - `kernel/crypto/ecc.ko` (iwlwifi crypto dependency)
  - `kernel/crypto/ecdh_generic.ko` (iwlwifi crypto dependency)
- Copied from z890's `/lib/modules/6.16.1-sable-compat/`
- `depmod -b /mnt/liveroot 6.16.1-sable-compat` run to rebuild modules.dep

### Key Learnings
- Always run `sync` before `umount` on USB writes
- `modprobe -v` with no output means module is already loaded or modprobe found nothing to do
- iwlwifi.ko must be present for iwlmvm.ko to load — iwlmvm exports no symbols without it
- Missing modules.dep entries cause silent load failures even when .ko files are present
- liveroot module tree must be kept in sync with z890's built modules after every kernel rebuild
- `uname -r` in installer must run on target machine, not build host

### Result
- SableLinux installed successfully to ASUS Q503UA (maya, Skylake i5-6200U)
- Kernel: 6.16.1-sable-compat
- iwlwifi firmware present flat in /lib/firmware/
- iwlwifi.ko + dependencies present in modules tree
- WiFi confirmed working on installed system

## pigz 2.8 — 2026-05-10
- Source: https://zlib.net/pigz/pigz-2.8.tar.gz
- make -j14 && cp pigz /usr/local/bin/
- Verified: pigz --version → pigz 2.8

## Micro-Tools Installation — 2026-05-24

### Session 1 (sable-microtools.sh)
Installed (28): dmidecode, pciutils, smartmontools, acpi, htop, ncdu, tree,
ripgrep, fd, bat, eza, delta, zoxide, fzf, yq, jq, zsh, fdupes, ethtool,
iperf3, age, ssdeep, theHarvester, scapy, aria2, yt-dlp, tig, lazygit

Skipped/already present (4): psmisc, pigz, lz4, sherlock

### Session 2 — Fixes (sable-microtools-fixes.sh)
Installed (11): nvme-cli (+ libnvme dep), lm-sensors, memtester, lsof,
ngrep, macchanger, inotify-tools, rhash, exiftool, w3m (+ libgc dep), iotop

### Key GCC 15 fixes applied
- memtester: conf-cc patched to use gcc -std=gnu17 -O2
- lsof: function pointer declarations patched in lib/misc.c
- ngrep: bundled regex-0.12 patched with missing includes, old declarations removed
- zip/unzip: abandoned — replaced with 7-zip 24.09 (already present)
- w3m: --disable-image (glib-object.h absent), -std=gnu17 -O2

### Key source fixes
- lm-sensors: extracts to lm-sensors-3-6-0/ (dashes not dots)
- ngrep: extracts to ngrep-1_47/ (underscores)
- macchanger: 1.8.0 release tag 404 — built from master (1.7)
- exiftool: version 13.58 (not 13.00)
- libnvme: required dep for nvme-cli, built from git
- libgc 8.2.8: required dep for w3m, built from source
- iotop: not on PyPI — built from source v1.25

## Micro-Tools Installation — 2026-05-24

### Session 1 (sable-microtools.sh)
Installed (28): dmidecode, pciutils, smartmontools, acpi, htop, ncdu, tree,
ripgrep, fd, bat, eza, delta, zoxide, fzf, yq, jq, zsh, fdupes, ethtool,
iperf3, age, ssdeep, theHarvester, scapy, aria2, yt-dlp, tig, lazygit

Skipped/already present (4): psmisc, pigz, lz4, sherlock

### Session 2 — Fixes (sable-microtools-fixes.sh)
Installed (11): nvme-cli (+ libnvme dep), lm-sensors, memtester, lsof,
ngrep, macchanger, inotify-tools, rhash, exiftool, w3m (+ libgc dep), iotop

### Key GCC 15 fixes applied
- memtester: conf-cc patched to use gcc -std=gnu17 -O2
- lsof: function pointer declarations patched in lib/misc.c
- ngrep: bundled regex-0.12 patched with missing includes, old declarations removed
- zip/unzip: abandoned — replaced with 7-zip 24.09 (already present)
- w3m: --disable-image (glib-object.h absent), -std=gnu17 -O2

### Key source fixes
- lm-sensors: extracts to lm-sensors-3-6-0/ (dashes not dots)
- ngrep: extracts to ngrep-1_47/ (underscores)
- macchanger: 1.8.0 release tag 404 — built from master (1.7)
- exiftool: version 13.58 (not 13.00)
- libnvme: required dep for nvme-cli, built from git
- libgc 8.2.8: required dep for w3m, built from source
- iotop: not on PyPI — built from source v1.25

## WiFi — sable-hp (WCN6855 hw2.1) — 2026-05-24

### Hardware
- HP laptop (sable-hp): Qualcomm WCN6855 hw2.1 PCIe WiFi (17CB:1103)
- USB 0489:e0d6 is Bluetooth only — not WiFi

### Kernel additions (6.16.1-sable-compat)
- CONFIG_ATH11K=m, CONFIG_ATH11K_PCI=m
- CONFIG_DEV_COREDUMP=y (required — ath11k_core won't link without it)

### Firmware
- WCN6855/hw2.1 not in linux-firmware repo (only hw2.0 present)
- Sourced amss.bin, m3.bin, board-2.bin separately
- Installed to /lib/firmware/ath11k/WCN6855/hw2.1/
- Mirrored to /mnt/liveroot/lib/firmware/ath11k/WCN6855/hw2.1/

### wifi-connect fix
- Replaced systemd-networkd DHCP dependency with udhcpc (busybox)
- udhcpc symlinked: /bin/udhcpc -> /bin/busybox
- wifi-connect now: wpa_supplicant -B + udhcpc -i $IFACE -t 10 -q

### modules-load.d
- ath11k_pci added to /etc/modules-load.d/wifi.conf

## SableLinux on HP Laptop (sable-hp) — 2026-05-24

### Hardware
- HP Elitebook, AMD Ryzen 7 PRO 5875U (Zen 3), with Radeon Graphics and
  Qualcomm WCN6855 WiFi
- Full install via sable-install to nvme0n1

### What worked out of the box
- iris Gallium driver — Intel UHD 630 display
- Sway 1.10 — full Wayland session
- Audio — PipeWire + WirePlumber
- Ethernet — r8169
- Firefox — MOZ_ENABLE_WAYLAND=1
- sable-install — end-to-end install pipeline validated on non-reference hardware

### WiFi — WCN6855 hw2.1
- Qualcomm WCN6855 PCIe (17CB:1103) — needs ath11k_pci
- CONFIG_ATH11K=m, CONFIG_ATH11K_PCI=m, CONFIG_DEV_COREDUMP=y added to compat kernel
- hw2.1 firmware not in linux-firmware repo — sourced separately
- Installed to /lib/firmware/ath11k/WCN6855/hw2.1/
- ath11k_pci added to /etc/modules-load.d/wifi.conf
- wifi-connect updated to use udhcpc instead of systemd-networkd
- udhcpc symlinked: /bin/udhcpc -> /bin/busybox

### sable-install fixes
- WCN6855 firmware copy added to both installed root and initramfs sections
- Installer validated: partitioning, LUKS prompt, user creation, GRUB, first boot all clean

### Significance
- Hardware-agnostic install pipeline proven on second machine
- Live ISO boots and installs on unknown hardware without manual intervention
- WiFi out of the box on modern Qualcomm hardware confirmed

## Live USB Recovery from Backup ISO — 2026-06-12

### Context
Live install USB became corrupted. Recovery performed by restoring from known-good backup ISO rather than from partition image.

### Recovery Procedure
- Located working backup: `/mnt/one/backups/sable-system/iso/sablelinux-live-wifi.iso.gz` (15G compressed, May 7)
- Confirmed disk image format via: `pigz -dc sablelinux-live-wifi.iso.gz | file -` → DOS/MBR boot sector (GPT hybrid disk image)
- Wrote directly to USB: `pigz -dc sablelinux-live-wifi.iso.gz | sudo dd of=/dev/sdb bs=4M status=progress`
- Cloned working USB to backup drive: `sudo dd if=/dev/sdb of=/dev/sdd bs=4M status=progress`
- Extracted clean liveroot from working USB via unsquashfs → `/mnt/liveroot-clean`

### Validated
- HP Pavilion (i3-8100, RTL8821CE): live boot + WiFi confirmed
- ASUS Q503UA (Skylake, Intel 7265): live boot + WiFi confirmed
- HP Elitebook (WCN6855 hw2.1): live boot + WiFi confirmed
- CF-2111WM (Celeron N4120, RTL8821CE): shell + network functional; Sway failed (below target demographic — deferred)

### Key Learnings
- sablelinux-live-install.iso.gz (61G) was a full nvme1n1 disk image, not a live ISO — do not use for USB recovery
- sablelinux-live-wifi.iso.gz is the correct live USB backup format
- Always confirm image type with `file -` before writing to USB

---

## Hardware-Agnostic Build Initiative — 2026-06-13

### New Staging Directory
- Created `/mnt/liveroot-agno1` as clean staging base (rsync from /mnt/liveroot-clean, 21G)

### Full Firmware Bundle
- Replaced cherry-picked firmware with complete `/sources/linux-firmware` copy
- `rsync -aHX /sources/linux-firmware/ /mnt/liveroot-agno1/lib/firmware/`
- Coverage: 367 entries (full upstream linux-firmware + previously installed additions)
- Rationale: security researchers operate on unknown target hardware; missing firmware mid-engagement is unacceptable

### GPU Auto-Detection
- Removed hardcoded `exec_always export WLR_DRM_DEVICES=/dev/dri/card0` from sway config
- Replaced with detection function in `/home/sable/.bash_profile`
- Priority: NVIDIA (rank 1) → AMD/amdgpu (rank 2) → Intel i915/xe (rank 3) → skip virtio/bochs/vboxvideo/vmwgfx
- Uses `readlink /sys/class/drm/cardN/device/driver` to read kernel driver association from sysfs
- Falls back to `/dev/dri/card0` if no card detected

### AVX Binary Audit
- Scanned all ELF binaries in `/usr/bin` and `/usr/local/bin` for ymm/zmm/avx instructions
- Flagged binaries reviewed: gcc/g++/gfortran toolchain, LLVM tools, QEMU, coreutils (gzip/wc/cksum/rsync), gpg, spa-resample, ffuf, gobuster, binwalk
- Verdict: all clean for target demographic (security researchers on modern hardware)
  - Toolchain AVX: expected, researchers have capable CPUs
  - QEMU AVX: feature, not a bug
  - Coreutils AVX: glibc ifunc dispatch — runtime CPU detection, graceful fallback on older hardware
  - Go/Rust binaries (ffuf, gobuster, binwalk): confirmed no ymm/zmm register usage despite initial grep hit

### Squashfs Rebuild
- Built directly to USB (/dev/sdb2): `mksquashfs /mnt/liveroot-agno1 ... -comp xz -no-xattrs -noappend`
