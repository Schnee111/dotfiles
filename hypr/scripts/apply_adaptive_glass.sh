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

# Calculate perceived photometric luminance (0 - 100) using ITU-R BT.709 sRGB luma
# Note: `-alpha off` is critical so 100% opaque alpha channels on PNGs don't skew the calculation
LUM=$(magick "$WALLPAPER" -resize 250x250\! -alpha off -colorspace Gray -format "%[fx:mean*100]" info: 2>/dev/null)

if [[ -z "$LUM" ]]; then
    exit 0
fi

LUM_INT=${LUM%.*}

# Determine target blur brightness, global opacity, and terminal native background opacity based on luminance:
# - Sangat Terang (>= 65%): Clean blur (0.95) | Global (0.90 / 0.80) | Kitty BG (0.70)
# - Terang / Cerah (45% - 64%): Natural blur (1.00) | Global (0.88 / 0.78) | Kitty BG (0.60)
# - Sedang (25% - 44%): Luminous glass (1.08) | Global (0.86 / 0.76) | Kitty BG (0.50)
# - Gelap (< 25%): Crystal glow (1.15)        | Global (0.84 / 0.74) | Kitty BG (0.40)
if (( LUM_INT >= 65 )); then
    TARGET_BRIGHTNESS="0.95"
    TARGET_GLOBAL_ACTIVE="0.90"
    TARGET_GLOBAL_INACTIVE="0.80"
    TARGET_KITTY_BG="0.70"
elif (( LUM_INT >= 45 )); then
    TARGET_BRIGHTNESS="1.00"
    TARGET_GLOBAL_ACTIVE="0.88"
    TARGET_GLOBAL_INACTIVE="0.78"
    TARGET_KITTY_BG="0.60"
elif (( LUM_INT >= 25 )); then
    TARGET_BRIGHTNESS="1.08"
    TARGET_GLOBAL_ACTIVE="0.86"
    TARGET_GLOBAL_INACTIVE="0.76"
    TARGET_KITTY_BG="0.50"
else
    TARGET_BRIGHTNESS="1.15"
    TARGET_GLOBAL_ACTIVE="0.84"
    TARGET_GLOBAL_INACTIVE="0.74"
    TARGET_KITTY_BG="0.40"
fi

# Persist to custom/general.lua (follow symlink: live file links into dotfiles,
# and plain `sed -i` would replace the symlink with a regular file)
GENERAL_LUA="$HOME/.config/hypr/custom/general.lua"
if [[ -f "$GENERAL_LUA" ]]; then
    sed --follow-symlinks -i -E "s/brightness = [0-9.]+([,}])/brightness = $TARGET_BRIGHTNESS\\1/g" "$GENERAL_LUA"
fi

FLAG="$HOME/.config/hypr/custom/.solid_mode"

# Persist native background opacity to kitty.conf and hot-reload running Kitty windows
KITTY_CONF="$HOME/.config/kitty/kitty.conf"
if [[ -f "$KITTY_CONF" && ! -f "$FLAG" ]]; then
    sed --follow-symlinks -i -E "s/^background_opacity [0-9.]+/background_opacity $TARGET_KITTY_BG/" "$KITTY_CONF"
    kill -SIGUSR1 $(pgrep -x kitty) 2>/dev/null || true
fi

# Persist adaptive global opacity to shellOverrides/main.lua if not in solid mode
CONFIGURATOR="$HOME/.config/quickshell/end4-pC/scripts/hyprland/hyprconfigurator.py"
MAIN_LUA="$HOME/.config/hypr/hyprland/shellOverrides/main.lua"
if [[ ! -f "$FLAG" && -f "$CONFIGURATOR" && -f "$MAIN_LUA" ]]; then
    python3 "$CONFIGURATOR" --file "$MAIN_LUA" --set "decoration:active_opacity" "$TARGET_GLOBAL_ACTIVE" >/dev/null 2>&1
    python3 "$CONFIGURATOR" --file "$MAIN_LUA" --set "decoration:inactive_opacity" "$TARGET_GLOBAL_INACTIVE" >/dev/null 2>&1
fi

# Reload config dynamically in real-time (config-only avoids display flicker)
hyprctl reload config-only >/dev/null 2>&1

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
