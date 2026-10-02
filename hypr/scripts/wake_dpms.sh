#!/bin/bash
# ==============================================================================
# wake_dpms.sh: Restore display output and safely destroy temporary headless anchor
# ==============================================================================

# Exclusive lock to serialize sleep/wake execution and prevent race conditions
exec 200>/run/user/$UID/hypr-dpms.lock
flock -w 5 200 || exit 1

# If not sleeping and no headless anchor exists, nothing to wake
if [ ! -f /tmp/hypr-dpms-sleeping ] && ! hyprctl monitors -j | jq -e '.[] | select(.name == "HEADLESS-1")' >/dev/null 2>&1; then
    exit 0
fi

# 1. Power on physical HDMI display
hyprctl dispatch 'hl.dsp.dpms({ action = "enable", monitor = "HDMI-A-1" })' >/dev/null 2>&1

# 2. Allow monitor handshake & clock signal to stabilize:
# Wait up to 3 seconds until HDMI-A-1 is genuinely active and reported with dpmsStatus: true
for i in {1..30}; do
    if hyprctl monitors -j | jq -e '.[] | select(.name == "HDMI-A-1" and .dpmsStatus == true)' >/dev/null 2>&1; then
        break
    fi
    sleep 0.1
done

# Small grace period for client surfaces to adapt
sleep 0.2

# 3. Remove headless anchor ONLY IF HDMI-A-1 is verified active!
# If HDMI-A-1 is active, outputs transition safely from 2 -> 1 (never hits 0).
# If HDMI-A-1 failed to wake (e.g. cable unplugged), KEEP HEADLESS-1 to prevent Quickshell 0-output crash.
if hyprctl monitors -j | jq -e '.[] | select(.name == "HDMI-A-1" and .dpmsStatus == true)' >/dev/null 2>&1; then
    if hyprctl monitors -j | jq -e '.[] | select(.name == "HEADLESS-1")' >/dev/null 2>&1; then
        hyprctl output remove HEADLESS-1 >/dev/null 2>&1
    fi
    # Clear sleep state marker ONLY after monitor is confirmed alive and anchor removed
    rm -f /tmp/hypr-dpms-sleeping
fi

# 4. Restore lockscreen keyboard focus
hyprctl dispatch 'hl.dsp.global("quickshell:lockFocus")' >/dev/null 2>&1
