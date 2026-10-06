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
# - Very bright (>= 80%): Deep smoked glass (0.55) to kill glare on near-white wallpapers
# - Bright (65% - 79%): Smoked glass (0.70) to prevent glare and eye strain
# - Medium (35% - 64%): Soft smoked glass (0.85)
# - Dark (< 35%): Natural brightness (1.00) so dark wallpapers stay rich and clear
if (( LUM_INT >= 80 )); then
    TARGET_BRIGHTNESS="0.55"
elif (( LUM_INT >= 65 )); then
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
    sed -i -E "s/brightness = [0-9.]+([,}])/brightness = $TARGET_BRIGHTNESS\\1/g" "$GENERAL_LUA"
fi

# ------------------------------------------------------------------------------
# Nudge GTK theme listeners
# Chrome in GTK mode only re-reads theme colors when GtkSettings emits
# notify::gtk-theme-name (it does NOT watch gtk.css file changes). Toggling to a
# byte-identical twin theme and back fires that signal with no visual change,
# so Chrome repaints with the freshly generated palette within ~1s.
# Create the twin once per theme, e.g.:
#   ln -s /usr/share/themes/adw-gtk3-dark ~/.local/share/themes/adw-gtk3-dark-twin
# ------------------------------------------------------------------------------
GTK_THEME="$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null | tr -d "'")"
if [[ -n "$GTK_THEME" && "$GTK_THEME" != *-twin ]]; then
    TWIN_EXISTS=""
    for THEME_DIR in "$HOME/.local/share/themes" "/usr/share/themes"; do
        if [[ -e "$THEME_DIR/${GTK_THEME}-twin" ]]; then
            TWIN_EXISTS=1
            break
        fi
    done
    if [[ -n "$TWIN_EXISTS" ]]; then
        gsettings set org.gnome.desktop.interface gtk-theme "${GTK_THEME}-twin"
        sleep 0.15
        gsettings set org.gnome.desktop.interface gtk-theme "$GTK_THEME"
    fi
fi
