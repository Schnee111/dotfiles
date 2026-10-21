#!/usr/bin/env bash
# Toggle between Frosted Glass Mode (80%/70%) and Solid/Focus Mode (100%)

FLAG="$HOME/.config/hypr/custom/.solid_mode"
CONFIGURATOR="$HOME/.config/quickshell/end4-pC/scripts/hyprland/hyprconfigurator.py"
MAIN_LUA="$HOME/.config/hypr/hyprland/shellOverrides/main.lua"
ICON_GLASS="$HOME/.config/hypr/assets/glass_mode.svg"
ICON_SOLID="$HOME/.config/hypr/assets/solid_mode.svg"

if [[ -f "$FLAG" ]]; then
    rm -f "$FLAG"
    # Restore adaptive glass and kitty background opacity dynamically
    "$HOME/.config/hypr/scripts/apply_adaptive_glass.sh" &
    play_sound.sh Bottle.opus
    notify-send -a "Window Opacity" -n "blur_on" "Window Opacity" "Mode: Frosted Glass (Adaptive)" -t 1500
else
    touch "$FLAG"
    if [[ -f "$CONFIGURATOR" && -f "$MAIN_LUA" ]]; then
        python3 "$CONFIGURATOR" --file "$MAIN_LUA" --set "decoration:active_opacity" "1.0"
        python3 "$CONFIGURATOR" --file "$MAIN_LUA" --set "decoration:inactive_opacity" "1.0"
    fi
    KITTY_CONF="$HOME/.config/kitty/kitty.conf"
    if [[ -f "$KITTY_CONF" ]]; then
        sed --follow-symlinks -i -E "s/^background_opacity [0-9.]+/background_opacity 1.0/" "$KITTY_CONF"
        for pid in $(pgrep -x kitty 2>/dev/null); do
            kitten @ --to "unix:@kitty-$pid" set-background-opacity 1.0 2>/dev/null || true
        done
    fi
    hyprctl reload config-only
    play_sound.sh Bottle.opus
    notify-send -a "Window Opacity" -n "contrast" "Window Opacity" "Mode: Solid / Focus (100%)" -t 1500
fi
