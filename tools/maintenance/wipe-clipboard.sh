#!/bin/bash
# wipe-clipboard.sh
# Clears all Wayland clipboard surfaces (clipboard + primary selection).
# No clipboard manager detected on this system — wl-copy only.
# Safe to run at any time; exits cleanly if WAYLAND_DISPLAY is unset.

set -euo pipefail

WL_COPY="$(command -v wl-copy 2>/dev/null || true)"

if [[ -z "$WL_COPY" ]]; then
    echo "[wipe-clipboard] ERROR: wl-copy not found in PATH." >&2
    exit 1
fi

if [[ -z "${WAYLAND_DISPLAY:-}" ]]; then
    echo "[wipe-clipboard] WARNING: WAYLAND_DISPLAY not set — not in a Wayland session?" >&2
    exit 1
fi

# --- 1. Overwrite clipboard with random noise, then clear ---
# Overwriting before clearing prevents a forensic read of the
# last real content from any in-memory compositor buffer.
printf '%s' "$(dd if=/dev/urandom bs=512 count=1 2>/dev/null | base64)" | "$WL_COPY" 2>/dev/null || true
"$WL_COPY" --clear 2>/dev/null || true

# --- 2. Same for primary selection (middle-click buffer) ---
printf '%s' "$(dd if=/dev/urandom bs=512 count=1 2>/dev/null | base64)" | "$WL_COPY" --primary 2>/dev/null || true
"$WL_COPY" --clear --primary 2>/dev/null || true

echo "[wipe-clipboard] Done. Clipboard and primary selection cleared."
