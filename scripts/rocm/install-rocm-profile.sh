#!/bin/sh
set -eu

TARGET_ROOT="${1:-/}"
REPO_ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)"

SRC="$REPO_ROOT/configs/etc/profile.d/rocm.sh"
DEST_DIR="$TARGET_ROOT/etc/profile.d"
DEST="$DEST_DIR/rocm.sh"

if [ ! -f "$SRC" ]; then
    echo "ERROR: missing source profile: $SRC" >&2
    exit 1
fi

install -d -m 0755 "$DEST_DIR"
install -m 0644 "$SRC" "$DEST"

echo "Installed ROCm profile: $DEST"
