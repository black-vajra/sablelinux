#!/bin/bash
# SableLinux — QEMU/KVM Build
# Kernel KVM+virtio confirmed. /dev/kvm present. Run as pepper.
# sudo only for make install steps.

set -euo pipefail
cd /sources

# ── libcap-ng 0.8.5 ──────────────────────────────────────────────────────────
curl -LO https://github.com/stevegrubb/libcap-ng/releases/download/v0.8.5/libcap-ng-0.8.5.tar.gz
tar xf libcap-ng-0.8.5.tar.gz && cd libcap-ng-0.8.5
./configure --prefix=/usr --disable-static --without-python3
make -j14
sudo make install
cd /sources && rm -rf libcap-ng-0.8.5

# ── libslirp 4.8.0 ───────────────────────────────────────────────────────────
curl -LO https://gitlab.freedesktop.org/slirp/libslirp/-/archive/v4.8.0/libslirp-v4.8.0.tar.gz
tar xf libslirp-v4.8.0.tar.gz && cd libslirp-v4.8.0
mkdir build && cd build
meson setup .. --prefix=/usr --libdir=lib --buildtype=release
ninja -j14
sudo ninja install
cd /sources && rm -rf libslirp-v4.8.0

# ── nettle 3.10 ──────────────────────────────────────────────────────────────
curl -LO https://ftp.gnu.org/gnu/nettle/nettle-3.10.tar.gz
tar xf nettle-3.10.tar.gz && cd nettle-3.10
./configure --prefix=/usr --disable-static --enable-shared
make -j14
sudo make install
sudo ldconfig
cd /sources && rm -rf nettle-3.10

# ── QEMU 9.2.3 ───────────────────────────────────────────────────────────────
curl -LO https://download.qemu.org/qemu-9.2.3.tar.xz
tar xf qemu-9.2.3.tar.xz && cd qemu-9.2.3
mkdir build && cd build

../configure \
  --prefix=/usr \
  --sysconfdir=/etc \
  --localstatedir=/var \
  --target-list="x86_64-softmmu" \
  --enable-kvm \
  --enable-slirp \
  --enable-cap-ng \
  --disable-docs \
  --disable-werror \
  --disable-sdl

make -j14
sudo make install
sudo ldconfig
cd /sources && rm -rf qemu-9.2.3

# Verify:
qemu-system-x86_64 --version
qemu-system-x86_64 -accel help

# ── Groups ───────────────────────────────────────────────────────────────────
sudo groupadd -r kvm 2>/dev/null || true
sudo usermod -aG kvm pepper

# ── VM storage dir ───────────────────────────────────────────────────────────
sudo mkdir -p /var/lib/qemu
sudo chown pepper:kvm /var/lib/qemu
sudo chmod 770 /var/lib/qemu

# ── Bridge helper ACL ────────────────────────────────────────────────────────
sudo mkdir -p /etc/qemu
echo "allow br0" | sudo tee /etc/qemu/bridge.conf > /dev/null
sudo chmod 640 /etc/qemu/bridge.conf

echo ""
echo "QEMU/KVM build complete."
echo "Re-login or 'newgrp kvm' for group membership to take effect."
echo "Test: qemu-system-x86_64 -enable-kvm -cpu host -m 1G -nographic -no-reboot"
