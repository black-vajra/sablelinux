#!/bin/sh

set -u

TARGET_RELEASE="6.16.1-sable-lhc-test1"
CUSTOM_CFG="/boot/grub/custom.cfg"
CUSTOM_BACKUP="/srv/sablelinux/builds/20260719T211841Z-eb762ba-k6.16.1-sable-lhc-test1/system-backups/custom.cfg-before-6.16.1-sable-lhc-test1"
CUSTOM_EXISTED="false"

if [ "$(uname -r)" = "$TARGET_RELEASE" ]; then
    echo "REFUSING: candidate kernel is currently running."
    exit 1
fi

if [ "$CUSTOM_EXISTED" = "true" ]; then
    install         -o root         -g root         -m 0644         "$CUSTOM_BACKUP"         "$CUSTOM_CFG"

    echo "Restored the previous custom.cfg."
else
    rm -f -- "$CUSTOM_CFG"
    echo "Removed the candidate-only custom.cfg."
fi

echo "Generated grub.cfg and GRUB defaults were never modified."
