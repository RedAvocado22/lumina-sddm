#!/bin/bash
# Syncs current Caelestia wallpaper to /var/cache/lumina-sddm/wallpaper.jpg
WALL_PATH_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/caelestia/wallpaper/path.txt"
WALLPAPER="${1:-$(cat "$WALL_PATH_FILE" 2>/dev/null)}"
[ -z "$WALLPAPER" ] && exit 0
[ -f "$WALLPAPER" ] || exit 0
cp "$WALLPAPER" /var/cache/lumina-sddm/wallpaper.jpg
