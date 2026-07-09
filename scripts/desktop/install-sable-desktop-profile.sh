#!/bin/sh
set -eu

USER_NAME="${1:-pepper}"
USER_HOME="/home/$USER_NAME"
REPO_ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)"

echo "Installing Sable desktop profile for user: $USER_NAME"

install -d -m 0755 "$USER_HOME/.config/sway"
install -d -m 0755 "$USER_HOME/.config/waybar"

if [ -f "$USER_HOME/.config/sway/config" ]; then
    cp -a "$USER_HOME/.config/sway/config" "$USER_HOME/.config/sway/config.bak.$(date +%Y%m%d-%H%M%S)"
fi

if [ -d "$USER_HOME/.config/waybar" ]; then
    cp -a "$USER_HOME/.config/waybar" "$USER_HOME/.config/waybar.bak.$(date +%Y%m%d-%H%M%S)"
fi

cp -a "$REPO_ROOT/configs/desktop/sway/config" "$USER_HOME/.config/sway/config"
cp -a "$REPO_ROOT/configs/desktop/waybar/config" "$USER_HOME/.config/waybar/config"
cp -a "$REPO_ROOT/configs/desktop/waybar/style.css" "$USER_HOME/.config/waybar/style.css"

chown -R "$USER_NAME:$USER_NAME" "$USER_HOME/.config/sway" "$USER_HOME/.config/waybar"

echo "Sable desktop profile installed."
echo "Restart Waybar with: pkill waybar; setsid waybar >/tmp/waybar.log 2>&1 &"
