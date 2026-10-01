#!/usr/bin/env bash

# Toggle: If rofi is already running, kill it and exit immediately (toggle behavior)
if pidof rofi >/dev/null 2>&1; then
    killall rofi 2>/dev/null
    exit 0
fi

# Sync colors with Quickshell / Matugen palette if needed
COLORS_JSON="$HOME/.local/state/quickshell/user/generated/colors.json"
ROFI_COLORS="$HOME/.config/rofi/colors.rasi"

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

CONFIG="$HOME/.config/hypr/monitors.lua"

case "$CHOSEN" in
    *"External Monitor Only"*)
        # Verify physical HDMI connection before disabling laptop screen
        HDMI_STATUS=$(ls /sys/class/drm/card*-HDMI-A-1/status 2>/dev/null | head -n1)
        if [ -z "$HDMI_STATUS" ] || [ ! -f "$HDMI_STATUS" ] || [ "$(cat "$HDMI_STATUS" 2>/dev/null)" != "connected" ]; then
            notify-send -u critical -t 3000 -a "Display" "Display Error" "HDMI monitor not detected. Switch cancelled." -i dialog-error &
            exit 1
        fi

        # Official Hyprland transition pattern:
        # Step 1: Enable target monitor alongside current monitor so destination exists
        cat << 'EOF' > "$CONFIG"
hl.monitor({
    output = "HDMI-A-1",
    mode = "1920x1080@200",
    position = "0x0",
    scale = 1,
})

hl.monitor({
    output = "eDP-1",
    mode = "2880x1800@90",
    position = "1920x0",
    scale = 1.5,
})

hl.monitor({
    output = "HEADLESS-1",
    mode = "1920x1080@60",
    position = "0x0",
    scale = 1,
})
EOF
        hyprctl reload >/dev/null 2>&1
        sleep 0.5

        # Step 2: Disable source monitor. Hyprland detects monitor removal and moves all windows/workspaces to HDMI-A-1
        cat << 'EOF' > "$CONFIG"
hl.monitor({
    output = "HDMI-A-1",
    mode = "1920x1080@200",
    position = "0x0",
    scale = 1,
})

hl.monitor({
    output = "eDP-1",
    disabled = true,
})

hl.monitor({
    output = "HEADLESS-1",
    mode = "1920x1080@60",
    position = "0x0",
    scale = 1,
})
EOF
        hyprctl reload >/dev/null 2>&1
        notify-send -t 2000 -a "Display" "Display Output" "External Monitor Only (1080p @ 200Hz)" -i video-display &
        ;;

    *"Laptop Screen Only"*)
        # Official Hyprland transition pattern:
        # Step 1: Enable target monitor alongside current monitor so destination exists
        cat << 'EOF' > "$CONFIG"
hl.monitor({
    output = "eDP-1",
    mode = "2880x1800@90",
    position = "0x0",
    scale = 1.5,
})

hl.monitor({
    output = "HDMI-A-1",
    mode = "1920x1080@200",
    position = "auto-right",
    scale = 1,
})

hl.monitor({
    output = "HEADLESS-1",
    mode = "1920x1080@60",
    position = "0x0",
    scale = 1,
})
EOF
        hyprctl reload >/dev/null 2>&1
        sleep 0.5

        # Step 2: Disable source monitor. Hyprland detects monitor removal and moves all windows/workspaces to eDP-1
        cat << 'EOF' > "$CONFIG"
hl.monitor({
    output = "eDP-1",
    mode = "2880x1800@90",
    position = "0x0",
    scale = 1.5,
})

hl.monitor({
    output = "HDMI-A-1",
    disabled = true,
})

hl.monitor({
    output = "HEADLESS-1",
    mode = "1920x1080@60",
    position = "0x0",
    scale = 1,
})
EOF
        hyprctl reload >/dev/null 2>&1
        notify-send -t 2000 -a "Display" "Display Output" "Laptop Screen Only (2.8K @ 90Hz, Scale 1.5)" -i computer &
        ;;

    *"Extend Displays"*)
        HDMI_STATUS=$(ls /sys/class/drm/card*-HDMI-A-1/status 2>/dev/null | head -n1)
        if [ -z "$HDMI_STATUS" ] || [ ! -f "$HDMI_STATUS" ] || [ "$(cat "$HDMI_STATUS" 2>/dev/null)" != "connected" ]; then
            notify-send -u critical -t 3000 -a "Display" "Display Error" "HDMI monitor not detected. Switch cancelled." -i dialog-error &
            exit 1
        fi

        cat << 'EOF' > "$CONFIG"
hl.monitor({
    output = "eDP-1",
    mode = "2880x1800@90",
    position = "0x0",
    scale = 1.5,
})

hl.monitor({
    output = "HDMI-A-1",
    mode = "1920x1080@200",
    position = "auto-right",
    scale = 1,
})

hl.monitor({
    output = "HEADLESS-1",
    mode = "1920x1080@60",
    position = "0x0",
    scale = 1,
})
EOF
        hyprctl reload >/dev/null 2>&1
        notify-send -t 2000 -a "Display" "Display Output" "Extended Displays (Dual Screen)" -i video-display &
        ;;
esac
