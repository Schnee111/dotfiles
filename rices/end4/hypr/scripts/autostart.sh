#!/bin/bash
# ==============================================================================
# Hyprland Autostart Script - Schnee Custom Session State
# Driven dynamically by layout_engine.py and session_layout.json
# ==============================================================================

# Redirect stdout and stderr to avoid broken pipes (EPIPE) when the launcher exits
exec >/dev/null 2>&1

# "Session autostart" is a setting of the shell (hyprland.sessionAutostart in its state file).
# Honour it here instead of relying on this file's executable bit, which the installed
# symlink would pass on to the tracked file. Without jq or the state file, keep running;
# a state file that cannot be read counts as off.
STATE_FILE="$HOME/.config/illogical-impulse/config.json"
if command -v jq >/dev/null 2>&1 && [ -f "$STATE_FILE" ] &&
    [ "$(jq -r '.hyprland.sessionAutostart // false' "$STATE_FILE" 2>/dev/null)" != "true" ]; then
    exit 0
fi

# Ensure autostart runs only once per login session
RUN_LOCK="/tmp/hypr-autostart-${HYPRLAND_INSTANCE_SIGNATURE:-default}.lock"
if [ -f "$RUN_LOCK" ]; then
    exit 0
fi
touch "$RUN_LOCK"

python3 "$HOME/.config/hypr/scripts/layout_engine.py" --run
