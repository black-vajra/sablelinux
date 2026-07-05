#!/bin/bash
# wipe-ds-traces.sh
# Wipes all local persistence surfaces for llama-server / ds query sessions.
# Covers: Wayland clipboard, bash history (file + session), systemd journal.
# Run as pepper; sudo required for journal vacuum section.
#
# Usage:
#   ./wipe-ds-traces.sh          # wipe everything
#   ./wipe-ds-traces.sh --dry-run  # show what would be done without doing it

set -euo pipefail

DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

run() {
    if $DRY_RUN; then
        echo "[DRY-RUN] $*"
    else
        eval "$@"
    fi
}

echo "=== wipe-ds-traces.sh ==="
echo "Mode: $( $DRY_RUN && echo DRY-RUN || echo LIVE )"
echo ""

# -----------------------------------------------------------------------
# 1. WAYLAND CLIPBOARD
# -----------------------------------------------------------------------
echo "[1/3] Wiping Wayland clipboard surfaces..."

if [[ -z "${WAYLAND_DISPLAY:-}" ]]; then
    echo "  WARNING: WAYLAND_DISPLAY not set — skipping clipboard wipe."
else
    WL_COPY="$(command -v wl-copy 2>/dev/null || true)"
    if [[ -z "$WL_COPY" ]]; then
        echo "  WARNING: wl-copy not found — skipping clipboard wipe."
    else
        # Overwrite with noise then clear — both clipboard and primary selection
        run "printf '%s' \"\$(dd if=/dev/urandom bs=512 count=1 2>/dev/null | base64)\" | \"$WL_COPY\" 2>/dev/null || true"
        run "\"$WL_COPY\" --clear 2>/dev/null || true"
        run "printf '%s' \"\$(dd if=/dev/urandom bs=512 count=1 2>/dev/null | base64)\" | \"$WL_COPY\" --primary 2>/dev/null || true"
        run "\"$WL_COPY\" --clear --primary 2>/dev/null || true"
        echo "  Done: clipboard and primary selection cleared."
    fi
fi
echo ""

# -----------------------------------------------------------------------
# 2. BASH HISTORY
# -----------------------------------------------------------------------
echo "[2/3] Wiping bash history..."

HISTFILE_PATH="${HISTFILE:-$HOME/.bash_history}"

if [[ -f "$HISTFILE_PATH" ]]; then
    LINES_BEFORE=$(wc -l < "$HISTFILE_PATH")
    # Overwrite file contents with zeros before truncating
    run "dd if=/dev/zero of=\"$HISTFILE_PATH\" bs=1 count=\$(wc -c < \"$HISTFILE_PATH\") conv=notrunc 2>/dev/null"
    run "truncate -s 0 \"$HISTFILE_PATH\""
    echo "  Done: $HISTFILE_PATH wiped ($LINES_BEFORE lines)."
else
    echo "  $HISTFILE_PATH not found — nothing to wipe."
fi

# Clear in-memory history for this session
# Note: this only affects the current shell if sourced; when run as a
# subprocess it clears the subprocess's own history, not the parent shell's.
# After running this script, also run:  history -c && history -w
run "history -c 2>/dev/null || true"
echo "  Note: also run 'history -c && history -w' in your current shell"
echo "  to clear the parent session's in-memory history."
echo ""

# -----------------------------------------------------------------------
# 3. SYSTEMD JOURNAL — llama-server.service
# -----------------------------------------------------------------------
echo "[3/3] Vacuuming systemd journal for llama-server.service..."

if ! command -v journalctl &>/dev/null; then
    echo "  WARNING: journalctl not found — skipping."
else
    # Vacuum all journal data older than 1 second (effectively everything to now)
    run "sudo journalctl --rotate"
    run "sudo journalctl --vacuum-time=1s"
    echo "  Done: journal vacuumed."
    echo "  Note: --vacuum-time=1s removes all journal data."
    echo "  If you want to preserve non-llama logs, use instead:"
    echo "    sudo journalctl --unit=llama-server.service --rotate"
    echo "    (per-unit vacuum is not supported; full vacuum is the only option)"
fi
echo ""

echo "=== Wipe complete ==="
echo ""
echo "REMAINING ACTION REQUIRED in your current shell:"
echo "  history -c && history -w"
