#!/usr/bin/env bash

# Toggle: If already running, kill and exit immediately
if pidof rofi >/dev/null 2>&1; then
    killall rofi 2>/dev/null
    exit 0
fi

COLORS_JSON="$HOME/.local/state/quickshell/user/generated/colors.json"
ROFI_COLORS="$HOME/.config/rofi/colors.rasi"

# Sync colors with Quickshell / Matugen
if [ -f "$COLORS_JSON" ]; then
    python3 -c '
import json, os

json_path = os.path.expanduser("~/.local/state/quickshell/user/generated/colors.json")
out_path = os.path.expanduser("~/.config/rofi/colors.rasi")

try:
    with open(json_path) as f:
        c = json.load(f)
    
    bg = c.get("surface_container", "#1e1e1e") + "eb"
    bg_alt = c.get("surface_container_high", "#2d2d2d") + "aa"
    fg = c.get("on_surface", "#ffffff") + "ff"
    fg_muted = c.get("outline", "#aaaaaa") + "ff"
    selected = c.get("primary_container", "#3b4a41") + "dd"
    selected_fg = c.get("on_primary_container", "#ffffff") + "ff"
    border = c.get("primary", "#ffffff") + "88"
    
    with open(out_path, "w") as f:
        f.write("/* Auto-generated from Quickshell Material You palette */\n")
        f.write("* {\n")
        f.write(f"    bg: {bg};\n")
        f.write(f"    bg-alt: {bg_alt};\n")
        f.write(f"    fg: {fg};\n")
        f.write(f"    fg-muted: {fg_muted};\n")
        f.write(f"    selected: {selected};\n")
        f.write(f"    selected-fg: {selected_fg};\n")
        f.write(f"    border-col: {border};\n")
        f.write("}\n")
except Exception:
    pass
'
fi

exec rofi -show drun -theme "$HOME/.config/rofi/launchpad.rasi"
