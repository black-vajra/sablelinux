
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
