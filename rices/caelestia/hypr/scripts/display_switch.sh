#!/usr/bin/env bash
# ==============================================================================
# Display Output Switcher (Caelestia / Hyprland)
# Bound to:  SUPER + P  and the XF86Display key
#
# Presents a rofi menu to move between External Only / Laptop Only / Extend.
# The choice is persisted to ~/.config/caelestia/display-mode, which the
# caelestia hyprland.lua entry-point reads on every reload / login (falling
# back to its physical-DRM default when the HDMI panel is not connected).
#
# Transitions use the proven two-step pattern: first bring up the destination
# next to the current monitor ("extend"), then disable the source monitor.
# ==============================================================================

MODE_FILE="$HOME/.config/caelestia/display-mode"

# Toggle: If rofi is already running, kill it and exit immediately
if pidof rofi >/dev/null 2>&1; then
    killall rofi 2>/dev/null
    exit 0
fi

# Sync colors with the Caelestia / Matugen palette so the menu matches the shell
COLORS_JSON="$HOME/.local/state/quickshell/user/generated/colors.json"

if [ -f "$COLORS_JSON" ]; then
    python3 -c '
import json, os
try:
    with open(os.path.expanduser("~/.local/state/quickshell/user/generated/colors.json")) as f:
        c = json.load(f)
    bg = c.get("surface_container", "#1e1e1e") + "eb"
    bg_alt = c.get("surface_container_high", "#2d2d2d") + "aa"
    fg = c.get("on_surface", "#ffffff") + "ff"
    fg_muted = c.get("outline", "#aaaaaa") + "ff"
    selected = c.get("primary_container", "#3b4a41") + "dd"
    selected_fg = c.get("on_primary_container", "#ffffff") + "ff"
    border = c.get("primary", "#ffffff") + "88"
    with open(os.path.expanduser("~/.config/rofi/colors.rasi"), "w") as f:
        f.write("/* Auto-generated from Quickshell Material You palette */\n* {\n")
        f.write(f"    bg: {bg};\n    bg-alt: {bg_alt};\n    fg: {fg};\n    fg-muted: {fg_muted};\n")
        f.write(f"    selected: {selected};\n    selected-fg: {selected_fg};\n    border-col: {border};\n}}\n")
except Exception:
    pass
' 2>/dev/null
fi

OPTIONS="󰍹  External Monitor Only\n󰌢  Laptop Screen Only\n󰍺  Extend Displays"

CHOSEN=$(printf "%b" "$OPTIONS" | rofi -dmenu -i -p "󰍹 " -theme "$HOME/.config/rofi/display.rasi")

# If user cancels (Escape or click outside), exit immediately
[ -z "$CHOSEN" ] && exit 0

set_mode() {
    mkdir -p "$(dirname "$MODE_FILE")"
    printf '%s\n' "$1" > "$MODE_FILE"
    hyprctl reload >/dev/null 2>&1
}

hdmi_connected() {
    local status_file
    status_file=$(ls /sys/class/drm/card*-HDMI-A-1/status 2>/dev/null | head -n1)
    [ -n "$status_file" ] && [ -f "$status_file" ] && [ "$(cat "$status_file" 2>/dev/null)" = "connected" ]
}

case "$CHOSEN" in
    *"External Monitor Only"*)
        if ! hdmi_connected; then
            notify-send -u critical -t 3000 -a "Display" -n "error" "Display Error" "HDMI monitor not detected. Switch cancelled." &
            exit 1
        fi

        # Step 1: bring the HDMI panel up next to the laptop panel
        set_mode extend
        sleep 0.5

        # Step 2: disable the laptop panel; Hyprland moves its workspaces over
        set_mode external
        play_sound.sh Chord.mp3
        notify-send -t 2000 -a "Display" -n "desktop_windows" "Display Output" "External Monitor Only (1080p @ 200Hz)" &
        ;;

    *"Laptop Screen Only"*)
        # Step 1: make sure the laptop panel is active next to the HDMI one
        set_mode extend
        sleep 0.5

        # Step 2: disable the HDMI panel
        set_mode laptop
        play_sound.sh Swish.mp3
        notify-send -t 2000 -a "Display" -n "laptop_chromebook" "Display Output" "Laptop Screen Only (2.8K @ 90Hz, Scale 1.6)" &
        ;;

    *"Extend Displays"*)
        if ! hdmi_connected; then
            notify-send -u critical -t 3000 -a "Display" -n "error" "Display Error" "HDMI monitor not detected. Switch cancelled." &
            exit 1
        fi

        set_mode extend
        play_sound.sh Chord.mp3
        notify-send -t 2000 -a "Display" -n "devices" "Display Output" "Extended Displays (Dual Screen)" &
        ;;
esac
