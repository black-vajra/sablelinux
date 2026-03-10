
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

