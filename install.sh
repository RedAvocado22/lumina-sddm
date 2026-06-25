#!/bin/bash
set -e

THEME_DIR="/usr/share/sddm/themes/lumina-sddm"
FONT_DIR="/usr/share/fonts/lumina-sddm"
CACHE_DIR="/var/cache/lumina-sddm"
SDDM_CONF="/etc/sddm.conf.d/10-lumina.conf"
HYPR_CONF="/etc/hypr/sddm-greeter.conf"

if [ "$EUID" -ne 0 ]; then
  echo "Run as root: sudo bash install.sh"
  exit 1
fi

echo "Installing lumina-sddm..."

# Theme
rm -rf "$THEME_DIR"
mkdir -p "$THEME_DIR"
cp -r "$(dirname "$0")"/. "$THEME_DIR"/
chmod -R 755 "$THEME_DIR"

# Fonts
mkdir -p "$FONT_DIR"
cp "$THEME_DIR/assets/fonts/"* "$FONT_DIR/"
fc-cache -fv > /dev/null

# Wallpaper cache
mkdir -p "$CACHE_DIR"
chown sddm:sddm "$CACHE_DIR"

# Hyprland greeter config
mkdir -p /etc/hypr
cat > "$HYPR_CONF" << 'EOF'
monitor = ,preferred,auto,1

env = XCURSOR_THEME,Adwaita
env = XCURSOR_SIZE,24

input {
    touchpad {
        tap-to-click = true
        natural_scroll = true
    }
    follow_mouse = 1
}

animations {
    enabled = false
}

misc {
    disable_splash_rendering = true
    disable_hyprland_logo = true
    force_default_wallpaper = 0
    disable_hyprland_guiutils_check = true
}
EOF

# SDDM config
mkdir -p /etc/sddm.conf.d
cat > "$SDDM_CONF" << 'EOF'
[General]
GreeterEnvironment=QML_XHR_ALLOW_FILE_READ=1,XCURSOR_THEME=Adwaita,XCURSOR_SIZE=24

[Theme]
Current=lumina-sddm
CursorTheme=Adwaita
CursorSize=24

[Wayland]
CompositorCommand=/usr/local/bin/start-hyprland -- --config /etc/hypr/sddm-greeter.conf
CursorTheme=Adwaita
CursorSize=24
EOF

# Wallpaper preseed service
cp "$THEME_DIR/lumina-wallpaper-preseed.service" /etc/systemd/system/
systemctl daemon-reload
systemctl enable lumina-wallpaper-preseed.service

echo "Done. Restart SDDM or reboot to apply."
