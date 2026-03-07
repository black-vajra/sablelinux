
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
