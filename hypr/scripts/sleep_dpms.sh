#!/bin/bash
# ==============================================================================
# sleep_dpms.sh: Safe display sleep for Hyprland + Quickshell
# ==============================================================================

# Exclusive lock to serialize sleep/wake execution and prevent race conditions
exec 200>/run/user/$UID/hypr-dpms.lock
flock -w 5 200 || exit 1

# If already sleeping, do nothing
if [ -f /tmp/hypr-dpms-sleeping ]; then
    exit 0
fi

# 1. State marker for monitor_watcher & monitors_safeguard
touch /tmp/hypr-dpms-sleeping

# 2. Guarantee at least 1 active Wayland output exists BEFORE HDMI-A-1 turns off.
# This prevents QtWayland / Quickshell from seeing 0 outputs and aborting with qFatal.
if ! hyprctl monitors -j | jq -e '.[] | select(.name == "HEADLESS-1")' >/dev/null 2>&1; then
    hyprctl output create headless HEADLESS-1 >/dev/null 2>&1
    # Verify that HEADLESS-1 is acknowledged by the compositor
    for i in {1..20}; do
        if hyprctl monitors -j | jq -e '.[] | select(.name == "HEADLESS-1")' >/dev/null 2>&1; then
            break
        fi
        sleep 0.05
    done
fi

# 3. Power off physical HDMI display via DPMS
hyprctl dispatch 'hl.dsp.dpms({ action = "disable", monitor = "HDMI-A-1" })' >/dev/null 2>&1
