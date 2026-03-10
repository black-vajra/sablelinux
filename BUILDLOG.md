
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
