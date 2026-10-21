#!/bin/bash
# ==============================================================================
# Hyprland Autostart Script - Schnee Custom Session State
# Driven dynamically by layout_engine.py and session_layout.json
# ==============================================================================

# Redirect stdout and stderr to avoid broken pipes (EPIPE) when the launcher exits
exec >/dev/null 2>&1

# Ensure autostart runs only once per login session
RUN_LOCK="/tmp/hypr-autostart-${HYPRLAND_INSTANCE_SIGNATURE:-default}.lock"
if [ -f "$RUN_LOCK" ]; then
    exit 0
fi
touch "$RUN_LOCK"

python3 $HOME/.config/hypr/scripts/layout_engine.py --run
