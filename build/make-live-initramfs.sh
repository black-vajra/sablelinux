#!/usr/bin/env bash
# Compatibility wrapper for the canonical SableLinux BusyBox live initramfs builder.
#
# Historical versions of this script depended on /opt/initramfs-tools and wrote
# directly to /tmp/usb-root/boot/initramfs-live.img. The canonical implementation
# now lives under scripts/live/ and accepts an explicit output path.
#
# Usage:
#   build/make-live-initramfs.sh [OUTPUT.img]

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="${1:-/tmp/usb-root/boot/initramfs-live.img}"

exec "$REPO_ROOT/scripts/live/build-live-initramfs-busybox.sh" "$OUT"
