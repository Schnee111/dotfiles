#!/usr/bin/env bash
# Toggle between Frosted Glass Mode (80%/70%) and Solid/Focus Mode (100%)

FLAG="$HOME/.config/hypr/custom/.solid_mode"
CONFIGURATOR="$HOME/.config/quickshell/end4-pC/scripts/hyprland/hyprconfigurator.py"
MAIN_LUA="$HOME/.config/hypr/hyprland/shellOverrides/main.lua"

if [[ -f "$FLAG" ]]; then
    rm -f "$FLAG"
    if [[ -f "$CONFIGURATOR" && -f "$MAIN_LUA" ]]; then
        python3 "$CONFIGURATOR" --file "$MAIN_LUA" --set "decoration:active_opacity" "0.8"
        python3 "$CONFIGURATOR" --file "$MAIN_LUA" --set "decoration:inactive_opacity" "0.7"
    fi
    hyprctl reload
    notify-send -a "Hyprland" -i preferences-desktop-theme "Window Opacity" "Mode: Frosted Glass (80% / 70%)" -t 1500
else
    touch "$FLAG"
    if [[ -f "$CONFIGURATOR" && -f "$MAIN_LUA" ]]; then
        python3 "$CONFIGURATOR" --file "$MAIN_LUA" --set "decoration:active_opacity" "1.0"
        python3 "$CONFIGURATOR" --file "$MAIN_LUA" --set "decoration:inactive_opacity" "1.0"
    fi
    hyprctl reload
    notify-send -a "Hyprland" -i preferences-desktop-theme "Window Opacity" "Mode: Solid / Focus (100%)" -t 1500
fi
