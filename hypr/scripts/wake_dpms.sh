#!/bin/bash
# ==============================================================================
# wake_dpms.sh: Restore display output and destroy temporary headless anchor
# ==============================================================================

# 1. Clear sleep state marker
rm -f /tmp/hypr-dpms-sleeping

# 2. Power on physical HDMI display
hyprctl dispatch 'hl.dsp.dpms({ action = "enable", monitor = "HDMI-A-1" })' >/dev/null 2>&1

# 3. Allow monitor handshake & clock signal to stabilize
sleep 0.5

# 4. Remove headless anchor so games (osu!), tablet, and desktop stay 100% single-display
if hyprctl monitors -j | grep -q '"name": "HEADLESS-1"'; then
    hyprctl output remove HEADLESS-1 >/dev/null 2>&1
fi

# 5. Restore lockscreen keyboard focus
hyprctl dispatch 'hl.dsp.global("quickshell:lockFocus")' >/dev/null 2>&1
