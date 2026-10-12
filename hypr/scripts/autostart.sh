#!/bin/bash
# ==============================================================================
# Hyprland Autostart Script - Schnee Custom Session State
# ==============================================================================
# Workspace placement happens ONLY here at login.
# NOTE: this setup uses the dots-hyprland Lua fork, so `hyprctl dispatch`
# takes Lua expressions (hl.dsp.*), NOT raw Hyprland dispatcher syntax.
# custom/rules.lua intentionally has NO `workspace` window rules for manual apps,
# so apps opened manually later follow the active workspace.

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

# Active Window Polling Helpers (Guarantees layout order regardless of cold-boot speed)
wait_for_window() {
    local pattern="$1"
    local timeout="${2:-15}"
    local count=0
    while ! hyprctl clients -j 2>/dev/null | jq -e --arg p "$pattern" '[.[] | select((.class | test($p; "i")) or (.title | test($p; "i")))] | length > 0' >/dev/null 2>&1; do
        sleep 0.25
        count=$((count + 1))
        [ "$count" -ge "$((timeout * 4))" ] && break
    done
}

wait_for_window_count() {
    local pattern="$1"
    local expected="$2"
    local timeout="${3:-15}"
    local count=0
    while ! hyprctl clients -j 2>/dev/null | jq -e --arg p "$pattern" --argjson exp "$expected" '[.[] | select((.class | test($p; "i")) or (.title | test($p; "i")))] | length >= $exp' >/dev/null 2>&1; do
        sleep 0.25
        count=$((count + 1))
        [ "$count" -ge "$((timeout * 4))" ] && break
    done
}

# ------------------------------------------------------------------------------
# Workspace 2: Kitty (Fastfetch top-left, Main right, Btop bottom-left)
# ------------------------------------------------------------------------------
dexec 2 "kitty --class kitty-fastfetch fish -c 'fastfetch; exec fish'"
wait_for_window "kitty-fastfetch" 10
sleep 0.2
dfocus "class:kitty-fastfetch"
dpre_r
dexec 2 "kitty --class kitty-main"
wait_for_window "kitty-main" 10
sleep 0.2
dfocus "class:kitty-fastfetch"
dpre_d
dexec 2 "kitty --class kitty-btop -o font_size=9.0 -e btop"
wait_for_window "kitty-btop" 10
sleep 0.3
dresize "class:kitty-fastfetch" 951 427

# ------------------------------------------------------------------------------
# Workspace 3: Hermes Desktop (Dual side-by-side windows)
# ------------------------------------------------------------------------------
dexec 3 "/home/schnee/.local/bin/hermes desktop"
wait_for_window "com.nousresearch.hermes" 15
sleep 0.5
dfocus "class:com.nousresearch.hermes"
dpre_r
hyprctl dispatch 'hl.dsp.send_shortcut({mods="CTRL SHIFT", key="N", window="class:com.nousresearch.hermes"})'
wait_for_window_count "com.nousresearch.hermes" 2 15
sleep 0.5
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
# Workspace 7: WhatsApp (left, width 1258), Telegram (right, width 640)
# ------------------------------------------------------------------------------
dexec 7 "firefox --name whatsapp-app --new-instance -P whatsapp-pwa https://web.whatsapp.com"
wait_for_window "whatsapp-app" 25
sleep 0.5
dfocus "class:whatsapp-app"
dpre_r
dexec 7 "/home/schnee/.local/bin/telegram"
wait_for_window "telegram" 15
sleep 0.5
dresize "class:whatsapp-app" 1258 1019

# ------------------------------------------------------------------------------
# Workspace 8: Development Terminals (Hermes left, Agy top-right, Btop bottom-right)
# ------------------------------------------------------------------------------
dexec 8 "kitty --class kitty-main"
wait_for_window "kitty-main" 10
sleep 0.2
dfocus "class:kitty-main"
dpre_r
dexec 8 "kitty fish -c 'agy; exec fish'"
wait_for_window "agy" 10
sleep 0.2
dfocus "title:agy"
dpre_d
dexec 8 "kitty -o font_size=10.0 fish -c 'btop; exec fish'"
wait_for_window "btop" 10

# ------------------------------------------------------------------------------
# Workspace 9: Social & Entertainment (Discord left, Spotify top-right, Kitty bottom-right)
# ------------------------------------------------------------------------------
dexec 9 "flatpak run com.discordapp.Discord"
wait_for_window "discord" 30
sleep 0.5
dfocus "class:discord"
dpre_r
dexec 9 "flatpak run com.spotify.Client"
wait_for_window "spotify" 25
sleep 0.5
dfocus "class:spotify"
dpre_d
dexec 9 "kitty --class kitty-ws9 -o font_size=10.0 fish -c 'fastfetch; exec fish'"
wait_for_window "kitty-ws9" 10
sleep 0.5
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
