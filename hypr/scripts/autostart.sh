#!/bin/bash
# ==============================================================================
# Hyprland Autostart Script - Schnee Custom Session State
# ==============================================================================
# Workspace placement happens ONLY here at login.
# NOTE: this setup uses the dots-hyprland Lua fork, so `hyprctl dispatch`
# takes Lua expressions (hl.dsp.*), NOT raw Hyprland dispatcher syntax.
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

# Run Quickshell tmpfs log cleanup on login
/home/schnee/.config/hypr/scripts/quickshell_log_cleaner.sh &

# Helpers (Lua-wrapped dispatch)
dexec()   { hyprctl dispatch "hl.dsp.exec_cmd(\"$2\", { workspace = \"$1 silent\" })"; }  # $1=ws $2=cmd
dfocus()  { hyprctl dispatch "hl.dsp.focus({ window = \"$1\" })"; }                         # $1=window selector
dws()     { hyprctl dispatch "hl.dsp.focus({ workspace = $1 })"; }                         # $1=workspace id

# ------------------------------------------------------------------------------
# Workspace 2: Kitty (Fastfetch top-left), Kitty (Main right), Kitty (Btop bottom-left)
# ------------------------------------------------------------------------------
dexec 2 "kitty --class kitty-fastfetch -o font_size=9.0 fish -c 'fastfetch; exec fish'"
sleep 0.5
dexec 2 "kitty --class kitty-main"
sleep 0.5
dfocus "class:kitty-fastfetch"
sleep 0.2
dexec 2 "kitty --class kitty-btop -o font_size=9.0 -e btop"
sleep 0.3

# ------------------------------------------------------------------------------
# Workspace 3: Hermes Desktop
# ------------------------------------------------------------------------------
dexec 3 "/home/schnee/.local/bin/hermes desktop"

# ------------------------------------------------------------------------------
# Workspace 4: Google Chrome
# ------------------------------------------------------------------------------
dexec 4 "google-chrome-stable"

# ------------------------------------------------------------------------------
# Workspace 5: Firefox
# ------------------------------------------------------------------------------
dexec 5 "firefox"

# ------------------------------------------------------------------------------
# Workspace 7: WhatsApp (left), Telegram (right)
# ------------------------------------------------------------------------------
dexec 7 "firefox --name whatsapp-app --new-instance -P whatsapp-pwa https://web.whatsapp.com"
sleep 0.6
dexec 7 "/home/schnee/.local/bin/telegram"

# ------------------------------------------------------------------------------
# Workspace 8: Development Terminals (Hermes left, Dev top-right, Btop bottom-right)
# ------------------------------------------------------------------------------
dexec 8 "kitty --class kitty-main"
sleep 0.5
dexec 8 "kitty"
sleep 0.3
dfocus "class:kitty"
sleep 0.2
dexec 8 "kitty --class kitty-btop-ws8 -e btop"

# ------------------------------------------------------------------------------
# Workspace 9: Discord (left), Spotify (top-right), Kitty (bottom-right)
# ------------------------------------------------------------------------------
dexec 9 "flatpak run com.discordapp.Discord"
sleep 0.8
dexec 9 "flatpak run com.spotify.Client"
sleep 0.5
dfocus "class:spotify"
sleep 0.2
dexec 9 "kitty --class kitty-ws9"

# ------------------------------------------------------------------------------
# Focus back to Workspace 2 (Main Terminal)
# ------------------------------------------------------------------------------
sleep 0.5
dws 2
sleep 0.2
dfocus "class:kitty-main"

# Apply adaptive smoked glass based on current wallpaper
/home/schnee/.config/hypr/scripts/apply_adaptive_glass.sh &
