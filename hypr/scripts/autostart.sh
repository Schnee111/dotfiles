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
dpre_d()  { hyprctl dispatch 'hl.dsp.layout("preselect d")'; }
dpre_r()  { hyprctl dispatch 'hl.dsp.layout("preselect r")'; }
dresize() { hyprctl dispatch "hl.dsp.window.resize({ window = \"$1\", x = $2, y = $3, relative = false })"; }

# ------------------------------------------------------------------------------
# Workspace 2: Kitty (Fastfetch top-left, Main right, Btop bottom-left)
# ------------------------------------------------------------------------------
dexec 2 "kitty --class kitty-fastfetch -o font_size=9.0 fish -c 'fastfetch; exec fish'"
sleep 0.6
dfocus "class:kitty-fastfetch"
sleep 0.2
dpre_r
dexec 2 "kitty --class kitty-main"
sleep 0.6
dfocus "class:kitty-fastfetch"
sleep 0.2
dpre_d
dexec 2 "kitty --class kitty-btop -o font_size=9.0 -e btop"
sleep 0.4
dresize "class:kitty-fastfetch" 951 427

# ------------------------------------------------------------------------------
# Workspace 3: Hermes Desktop (Dual side-by-side windows)
# ------------------------------------------------------------------------------
dexec 3 "/home/schnee/.local/bin/hermes desktop"
sleep 1.2
dfocus "class:com.nousresearch.hermes"
sleep 0.2
dpre_r
hyprctl dispatch 'hl.dsp.send_shortcut({mods="CTRL SHIFT", key="N", window="class:com.nousresearch.hermes"})'
sleep 0.6
dresize "class:com.nousresearch.hermes" 1100 1019

# ------------------------------------------------------------------------------
# Workspace 4: Google Chrome
# ------------------------------------------------------------------------------
dexec 4 "google-chrome-stable"

# ------------------------------------------------------------------------------
# Workspace 5: Mozilla Firefox
# ------------------------------------------------------------------------------
dexec 5 "firefox"

# ------------------------------------------------------------------------------
# Workspace 7: WhatsApp (left), Telegram (right)
# ------------------------------------------------------------------------------
dexec 7 "firefox --name whatsapp-app --new-instance -P whatsapp-pwa https://web.whatsapp.com"
sleep 0.8
dfocus "class:whatsapp-app"
sleep 0.2
dpre_r
dexec 7 "/home/schnee/.local/bin/telegram"
sleep 0.6
dresize "class:whatsapp-app" 1258 1019

# ------------------------------------------------------------------------------
# Workspace 8: Development Terminals (Hermes left, Agy top-right, Btop bottom-right)
# ------------------------------------------------------------------------------
dexec 8 "kitty --class kitty-main"
sleep 0.6
dfocus "class:kitty-main"
sleep 0.2
dpre_r
dexec 8 "kitty fish -c 'agy; exec fish'"
sleep 0.6
dfocus "title:agy"
sleep 0.2
dpre_d
dexec 8 "kitty fish -c 'btop; exec fish'"

# ------------------------------------------------------------------------------
# Workspace 9: Social & Entertainment (Discord left, Spotify top-right, Kitty bottom-right)
# ------------------------------------------------------------------------------
dexec 9 "flatpak run com.discordapp.Discord"
sleep 0.8
dfocus "class:discord"
sleep 0.2
dpre_r
dexec 9 "flatpak run com.spotify.Client"
sleep 0.6
dfocus "class:spotify"
sleep 0.2
dpre_d
dexec 9 "kitty --class kitty-ws9"
sleep 0.6
dresize "class:discord" 1075 1019
sleep 0.2
dresize "class:spotify" 823 625

# ------------------------------------------------------------------------------
# Focus back to Workspace 2 (Main Terminal)
# ------------------------------------------------------------------------------
sleep 0.5
dws 2
sleep 0.2
dfocus "class:kitty-main"

# Apply adaptive smoked glass based on current wallpaper
/home/schnee/.config/hypr/scripts/apply_adaptive_glass.sh &
