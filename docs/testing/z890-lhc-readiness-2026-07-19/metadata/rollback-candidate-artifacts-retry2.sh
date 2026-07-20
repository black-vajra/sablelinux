#!/bin/sh

set -u

TARGET_RELEASE="6.16.1-sable-lhc-test1"

if [ "$(uname -r)" = "$TARGET_RELEASE" ]; then
    echo "REFUSING: candidate kernel is currently running."
    exit 1
fi

rm -rf --     "/lib/modules/$TARGET_RELEASE"     "/lib/modules/.$TARGET_RELEASE.installing-retry2"

rm -f --     "/boot/vmlinuz-$TARGET_RELEASE"     "/boot/config-$TARGET_RELEASE"     "/boot/System.map-$TARGET_RELEASE"     "/boot/initramfs-$TARGET_RELEASE.img"     "/boot/.vmlinuz-$TARGET_RELEASE.installing-retry2"     "/boot/.config-$TARGET_RELEASE.installing-retry2"     "/boot/.System.map-$TARGET_RELEASE.installing-retry2"     "/boot/.initramfs-$TARGET_RELEASE.installing-retry2"

echo "Removed retry-2 candidate installation artifacts."
echo "GRUB was not modified."
