#!/bin/bash
# SableLinux — WireGuard VPN Client
# Requires: CONFIG_WIREGUARD=y, CONFIG_TUN=y (kernel rebuild #3)
# Run as pepper.

set -euo pipefail
cd /sources

# wireguard-tools 1.0.20210914
curl -LO https://git.zx2c4.com/wireguard-tools/snapshot/wireguard-tools-1.0.20210914.tar.xz
tar xf wireguard-tools-1.0.20210914.tar.xz && cd wireguard-tools-1.0.20210914
make -C src -j14 WITH_WGQUICK=yes
sudo make -C src install WITH_WGQUICK=yes
wg --version
cd /sources && rm -rf wireguard-tools-1.0.20210914

# Keypair generation
sudo mkdir -p /etc/wireguard
sudo chmod 700 /etc/wireguard
wg genkey | sudo tee /etc/wireguard/privatekey | wg pubkey | sudo tee /etc/wireguard/publickey
sudo chmod 600 /etc/wireguard/privatekey

echo "Public key (register on server):"
cat /etc/wireguard/publickey

# Create /etc/wireguard/wg0.conf manually with server details, then:
#   sudo wg-quick up wg0
#   sudo wg show
#   ping 10.6.0.1
#   sudo systemctl enable wg-quick@wg0
