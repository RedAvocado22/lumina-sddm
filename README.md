# lumina-sddm

An adaptive SDDM login theme for Hyprland + Wayland. Automatically extracts colors from your wallpaper and generates a matching palette using the Oklch color space.

## Previews

| | |
|---|---|
| ![](previews/preview1.png) | ![](previews/preview2.png) |
| ![](previews/preview3.png) | ![](previews/preview4.png) |

## Features

- Wallpaper-synced color palette via Oklch color extraction
- Frosted glass split layout
- Live clock, battery indicator, hostname pills
- Session picker + power confirm overlay
- Bundled fonts — no system font dependency (Rubik + Material Symbols Rounded)

## Install

```bash
git clone https://github.com/RedAvocado22/lumina-sddm.git
cd lumina-sddm
sudo bash install.sh
```

Then reboot.

## Requirements

- SDDM with Wayland support
- Hyprland installed at `/usr/local/bin/start-hyprland`

## Wallpaper Sync

The theme reads your wallpaper automatically on boot. For live sync on wallpaper change (Caelestia shell):

```bash
systemctl --user enable --now lumina-wallpaper-sync.path
```

Or manually sync any image:

```bash
sudo bash sync-wallpaper.sh /path/to/wallpaper.jpg
```

## License

MIT
