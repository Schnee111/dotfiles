#!/usr/bin/env bash
# ==============================================================================
# Display Output Switcher (Caelestia / Hyprland)
# Bound to:  SUPER + P  and the XF86Display key
#
# Installed to ~/.local/bin by the dotfiles installer, so keybinds can call it
# by name (caelestia-display-switch.sh) like the sibling toggle scripts.
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

# `$USER` is normally exported by the session; fall back for safety
RUN_USER="${USER:-$(id -un)}"

# Toggle: If this user's rofi is already running, kill it and exit immediately
if pgrep -u "$RUN_USER" -x rofi >/dev/null 2>&1; then
    pkill -u "$RUN_USER" -x rofi 2>/dev/null
    exit 0
fi

# Sync colors with the Caelestia / Matugen palette so the menu matches the shell
COLORS_JSON="$HOME/.local/state/quickshell/user/generated/colors.json"
ROFI_COLORS="$HOME/.config/rofi/colors.rasi"

if [ -f "$COLORS_JSON" ] && [ "$COLORS_JSON" -nt "$ROFI_COLORS" ]; then
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
    rofi_dir = os.path.expanduser("~/.config/rofi")
    os.makedirs(rofi_dir, exist_ok=True)
    with open(os.path.join(rofi_dir, "colors.rasi"), "w") as f:
        f.write("/* Auto-generated from Quickshell Material You palette */\n* {\n")
        f.write(f"    bg: {bg};\n    bg-alt: {bg_alt};\n    fg: {fg};\n    fg-muted: {fg_muted};\n")
        f.write(f"    selected: {selected};\n    selected-fg: {selected_fg};\n    border-col: {border};\n}}\n")
except Exception:
    pass
' 2>/dev/null
fi

OPTIONS="󰍹  External Monitor Only\n󰌢  Laptop Screen Only\n󰍺  Extend Displays"

# Only use the custom theme when it is actually installed
ROFI_THEME_ARGS=()
[ -f "$HOME/.config/rofi/display.rasi" ] && ROFI_THEME_ARGS=(-theme "$HOME/.config/rofi/display.rasi")

CHOSEN=$(printf '%b\n' "$OPTIONS" | rofi -dmenu -i -no-custom -p "󰍹 " ${ROFI_THEME_ARGS[@]+"${ROFI_THEME_ARGS[@]}"})

# If user cancels (Escape or click outside), exit immediately
[ -z "$CHOSEN" ] && exit 0

set_mode() {
    mkdir -p "$(dirname "$MODE_FILE")"
    printf '%s\n' "$1" > "$MODE_FILE"
    hyprctl reload >/dev/null 2>&1
}

# Effective mode derived from Hyprland's live monitor state — NOT from the
# persisted file. They can disagree: when the HDMI panel is unplugged the
# entry-point silently falls back to the laptop panel while MODE_FILE still
# says "external", so trusting the file would report a stale "already on"
# and refuse to re-enable the external monitor after re-docking.
# Prints "external", "laptop", "extend", or nothing when neither is on.
effective_mode() {
    local state
    state=$(hyprctl monitors all -j 2>/dev/null | jq -r '
        def on: (if (.disabled or .width == 0) then "off" else "on" end);
        [ (.[] | select(.name == "eDP-1")  | on) ] as $edp
        | [ (.[] | select(.name == "HDMI-A-1") | on) ] as $hdmi
        | ($edp[0] // "off") + ($hdmi[0] // "off")' 2>/dev/null)

    case "$state" in
        onon)  echo extend ;;
        offon) echo external ;;
        onoff) echo laptop ;;
    esac
}

hdmi_connected() {
    # Any HDMI-A-1 connector on any DRM card counts: on hybrid-GPU laptops the
    # external port can be wired to card1 while card0 reports disconnected.
    grep -qx 'connected' /sys/class/drm/card*-HDMI-A-1/status 2>/dev/null
}

case "$CHOSEN" in
    *"External Monitor Only"*)
        if ! hdmi_connected; then
            notify-send -u critical -t 3000 -a "Display" -i "error" "Display Error" "HDMI monitor not detected. Switch cancelled." &
            exit 1
        fi

        if [ "$(effective_mode)" = "external" ]; then
            notify-send -t 2000 -a "Display" -i "desktop_windows" "Display Output" "Already on External Monitor Only" &
            exit 0
        fi

        # Step 1: bring the HDMI panel up next to the laptop panel
        set_mode extend
        sleep 0.5

        # Step 2: disable the laptop panel; Hyprland moves its workspaces over
        set_mode external
        play_sound.sh Chord.mp3
        notify-send -t 2000 -a "Display" -i "desktop_windows" "Display Output" "External Monitor Only (1080p @ 200Hz)" &
        ;;

    *"Laptop Screen Only"*)
        if [ "$(effective_mode)" = "laptop" ]; then
            notify-send -t 2000 -a "Display" -i "laptop_chromebook" "Display Output" "Already on Laptop Screen Only" &
            exit 0
        fi

        # Step 1: make sure the laptop panel is active next to the HDMI one
        set_mode extend
        sleep 0.5

        # Step 2: disable the HDMI panel
        set_mode laptop
        play_sound.sh Swish.mp3
        notify-send -t 2000 -a "Display" -i "laptop_chromebook" "Display Output" "Laptop Screen Only (2.8K @ 90Hz, Scale 1.6)" &
        ;;

    *"Extend Displays"*)
        if ! hdmi_connected; then
            notify-send -u critical -t 3000 -a "Display" -i "error" "Display Error" "HDMI monitor not detected. Switch cancelled." &
            exit 1
        fi

        if [ "$(effective_mode)" = "extend" ]; then
            notify-send -t 2000 -a "Display" -i "devices" "Display Output" "Already on Extended Displays" &
            exit 0
        fi

        set_mode extend
        play_sound.sh Chord.mp3
        notify-send -t 2000 -a "Display" -i "devices" "Display Output" "Extended Displays (Dual Screen)" &
        ;;
esac
