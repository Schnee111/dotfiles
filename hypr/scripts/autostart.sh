#!/bin/bash
# ==============================================================================
# Hyprland Autostart Script - Schnee Custom Session State
# ==============================================================================
# Workspace placement happens ONLY here at login, via
# `hyprctl dispatch exec "[workspace N silent] <cmd>"`.
# custom/rules.lua intentionally has NO `workspace` window rules, so apps
# opened manually later follow the active workspace.

# Redirect stdout and stderr to avoid broken pipes (EPIPE) when the launcher exits
exec >/dev/null 2>&1

# Ensure autostart runs only once per login session
RUN_LOCK="/tmp/hypr-autostart-${HYPRLAND_INSTANCE_SIGNATURE:-default}.lock"
if [ -f "$RUN_LOCK" ]; then
    exit 0
fi
touch "$RUN_LOCK"

# ------------------------------------------------------------------------------
# Workspace 2: Kitty (Fastfetch top-left), Kitty (Main right), Kitty (Btop bottom-left)
# ------------------------------------------------------------------------------
hyprctl dispatch exec "[workspace 2 silent] kitty --class kitty-fastfetch -o font_size=9.0 fish -c 'fastfetch; exec fish'"
sleep 0.5
hyprctl dispatch exec "[workspace 2 silent] kitty --class kitty-main"
sleep 0.5
hyprctl dispatch focuswindow class:kitty-fastfetch
sleep 0.2
hyprctl dispatch exec "[workspace 2 silent] kitty --class kitty-btop -o font_size=9.0 -e btop"
sleep 0.3

# ------------------------------------------------------------------------------
# Workspace 3: Hermes Desktop
# ------------------------------------------------------------------------------
hyprctl dispatch exec "[workspace 3 silent] /home/schnee/.local/bin/hermes desktop"

# ------------------------------------------------------------------------------
# Workspace 4: Google Chrome
# ------------------------------------------------------------------------------
hyprctl dispatch exec "[workspace 4 silent] google-chrome-stable"

# ------------------------------------------------------------------------------
# Workspace 6: Pinterest (left), Firefox (top-right), Ptyxis btop (bottom-right)
# ------------------------------------------------------------------------------
hyprctl dispatch exec "[workspace 6 silent] google-chrome-stable --profile-directory=Default --app-id=fbibgohghoobeeljoejfdmdhgoadhjbc"
sleep 0.6
hyprctl dispatch exec "[workspace 6 silent] firefox"
sleep 0.6
hyprctl dispatch focuswindow class:org.mozilla.firefox
sleep 0.2
hyprctl dispatch exec "[workspace 6 silent] ptyxis -s -T 'btop-ws6' -- btop"

# ------------------------------------------------------------------------------
# Workspace 7: WhatsApp (left), Telegram (right)
# ------------------------------------------------------------------------------
hyprctl dispatch exec "[workspace 7 silent] firefox --name whatsapp-app --new-instance -P whatsapp-pwa https://web.whatsapp.com"
sleep 0.6
hyprctl dispatch exec "[workspace 7 silent] /home/schnee/.local/bin/telegram"

# ------------------------------------------------------------------------------
# Workspace 8: Discord (left), Kitty (top-right), Spotify (bottom-right)
# ------------------------------------------------------------------------------
hyprctl dispatch exec "[workspace 8 silent] flatpak run com.discordapp.Discord"
sleep 0.8
hyprctl dispatch exec "[workspace 8 silent] kitty --class kitty-ws8"
sleep 0.5
hyprctl dispatch focuswindow class:kitty-ws8
sleep 0.2
hyprctl dispatch exec "[workspace 8 silent] flatpak run com.spotify.Client"

# ------------------------------------------------------------------------------
# Focus back to Workspace 2 (Main Terminal)
# ------------------------------------------------------------------------------
sleep 0.5
hyprctl dispatch workspace 2
sleep 0.2
hyprctl dispatch focuswindow class:kitty-main

# Apply adaptive smoked glass based on current wallpaper
/home/schnee/.config/hypr/scripts/apply_adaptive_glass.sh &
