#!/bin/bash
# ==============================================================================
# sleep_dpms.sh: Safe display sleep for Hyprland + Quickshell
# ==============================================================================

# 1. State marker for monitor_watcher & monitors_safeguard
touch /tmp/hypr-dpms-sleeping

# 2. Guarantee at least 1 active Wayland output exists before HDMI-A-1 turns off.
# This prevents QtWayland / Quickshell from seeing 0 outputs and aborting with qFatal.
if ! hyprctl monitors -j | grep -q '"name": "HEADLESS-1"'; then
    hyprctl output create headless HEADLESS-1 >/dev/null 2>&1
    sleep 0.1
fi

# 3. Power off physical HDMI display via DPMS
hyprctl dispatch 'hl.dsp.dpms({ action = "disable", monitor = "HDMI-A-1" })' >/dev/null 2>&1
