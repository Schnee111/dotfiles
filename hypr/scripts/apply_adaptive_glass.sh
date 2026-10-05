#!/usr/bin/env bash
# ==============================================================================
# Adaptive Smoked Glass for Hyprland
# Dynamically adjusts blur:brightness based on wallpaper luminance
# ==============================================================================

WALLPAPER="$1"
PATH_FILE="$HOME/.local/state/quickshell/user/generated/wallpaper/path.txt"

if [[ -z "$WALLPAPER" || ! -f "$WALLPAPER" ]]; then
    if [[ -f "$PATH_FILE" ]]; then
        WALLPAPER="$(cat "$PATH_FILE")"
    fi
fi

if [[ -z "$WALLPAPER" || ! -f "$WALLPAPER" ]]; then
    exit 0
fi

# Calculate perceived luminance (0 - 100) using ImageMagick on a downscaled sample for speed
LUM=$(magick "$WALLPAPER" -resize 250x250\! -colorspace Gray -format "%[fx:mean*100]" info: 2>/dev/null)

if [[ -z "$LUM" ]]; then
    exit 0
fi

LUM_INT=${LUM%.*}

# Determine target blur brightness based on luminance:
# - Bright (>= 65%): Smoked glass (0.70) to prevent glare and eye strain
# - Medium (35% - 64%): Soft smoked glass (0.85)
# - Dark (< 35%): Natural brightness (1.00) so dark wallpapers stay rich and clear
if (( LUM_INT >= 65 )); then
    TARGET_BRIGHTNESS="0.7"
elif (( LUM_INT >= 35 )); then
    TARGET_BRIGHTNESS="0.85"
else
    TARGET_BRIGHTNESS="1.0"
fi

# Apply in real-time to Hyprland
hyprctl eval "hl.config({ decoration = { blur = { brightness = $TARGET_BRIGHTNESS } } })" >/dev/null 2>&1

# Persist to custom/general.lua
GENERAL_LUA="$HOME/.config/hypr/custom/general.lua"
if [[ -f "$GENERAL_LUA" ]]; then
    sed -i -E "s/brightness = [0-9.]+([,}])/brightness = $TARGET_BRIGHTNESS\1/g" "$GENERAL_LUA"
fi
