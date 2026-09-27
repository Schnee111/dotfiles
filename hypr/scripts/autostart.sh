#!/bin/bash
# ==============================================================================
# Hyprland Autostart Script - Schnee Custom Session State
# ==============================================================================

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
kitty --class kitty-fastfetch -o font_size=9.0 fish -c "fastfetch; exec fish" &
sleep 0.5
kitty --class kitty-main &
sleep 0.5
hyprctl dispatch focuswindow class:kitty-fastfetch
sleep 0.2
kitty --class kitty-btop -o font_size=9.0 -e btop &
sleep 0.3

# ------------------------------------------------------------------------------
# Workspace 3: Hermes Desktop
# ------------------------------------------------------------------------------
/home/schnee/.local/bin/hermes desktop &

# ------------------------------------------------------------------------------
# Workspace 4: Google Chrome
# ------------------------------------------------------------------------------
flatpak run com.google.Chrome &

# ------------------------------------------------------------------------------
# Workspace 6: Pinterest (left), Firefox (top-right), Ptyxis btop (bottom-right)
# ------------------------------------------------------------------------------
flatpak run --command=/app/bin/chrome com.google.Chrome --profile-directory=Default --app-id=fbibgohghoobeeljoejfdmdhgoadhjbc &
sleep 0.6
firefox &
sleep 0.6
hyprctl dispatch focuswindow class:org.mozilla.firefox
sleep 0.2
ptyxis -s -T "btop-ws6" -- btop &

# ------------------------------------------------------------------------------
# Workspace 7: WhatsApp (left), Telegram (right)
# ------------------------------------------------------------------------------
firefox --name whatsapp-app --new-instance -P whatsapp-pwa https://web.whatsapp.com &
sleep 0.6
/home/schnee/.local/bin/telegram &

# ------------------------------------------------------------------------------
# Workspace 8: Discord (left), Kitty (top-right), Spotify (bottom-right)
# ------------------------------------------------------------------------------
flatpak run com.discordapp.Discord &
sleep 0.8
kitty --class kitty-ws8 &
sleep 0.5
hyprctl dispatch focuswindow class:kitty-ws8
sleep 0.2
flatpak run com.spotify.Client &

# ------------------------------------------------------------------------------
# Focus back to Workspace 2 (Main Terminal)
# ------------------------------------------------------------------------------
sleep 0.5
hyprctl dispatch workspace 2
sleep 0.2
hyprctl dispatch focuswindow class:kitty-main
