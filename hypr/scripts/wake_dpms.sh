#!/bin/bash
# ==============================================================================
# wake_dpms.sh: Restore display output and safely destroy temporary headless anchor
# ==============================================================================

# Exclusive lock to serialize sleep/wake execution and prevent race conditions
exec 200>/run/user/$UID/hypr-dpms.lock
flock -w 10 200 || exit 1

# If not sleeping and no headless anchor exists, nothing to wake
if [ ! -f /tmp/hypr-dpms-sleeping ] && ! hyprctl monitors -j | jq -e '.[] | select(.name == "HEADLESS-1")' >/dev/null 2>&1; then
    exit 0
fi

# 1. Power on physical HDMI display
hyprctl dispatch 'hl.dsp.dpms({ action = "enable", monitor = "HDMI-A-1" })' >/dev/null 2>&1
hyprctl dispatch 'hl.dsp.dpms({ action = "enable" })' >/dev/null 2>&1

# 2. Allow monitor handshake & clock signal to stabilize:
# Wait up to 8 seconds (80 x 0.1s) until HDMI-A-1 is genuinely active and reported with dpmsStatus: true
for i in {1..80}; do
    if hyprctl monitors -j | jq -e '.[] | select(.name == "HDMI-A-1" and .dpmsStatus == true)' >/dev/null 2>&1; then
        break
    fi
    sleep 0.1
done

# Small grace period for client surfaces to adapt
sleep 0.2

# Helper to clean up headless anchor and migrate any stranded workspaces
do_cleanup() {
    if hyprctl monitors -j | jq -e '.[] | select(.name == "HEADLESS-1")' >/dev/null 2>&1; then
        hyprctl output remove HEADLESS-1 >/dev/null 2>&1
    fi
    # Migrate any stranded workspaces back to HDMI-A-1
    for ws in $(hyprctl workspaces -j 2>/dev/null | jq -r '.[] | select(.monitor != "HDMI-A-1") | .name'); do
        hyprctl dispatch "hl.dsp.workspace.move({ workspace = \"$ws\", monitor = \"HDMI-A-1\" })" >/dev/null 2>&1
    done
    rm -f /tmp/hypr-dpms-sleeping
    hyprctl dispatch 'hl.dsp.global("quickshell:lockFocus")' >/dev/null 2>&1
}

# 3. Check if HDMI-A-1 is verified active
if hyprctl monitors -j | jq -e '.[] | select(.name == "HDMI-A-1" and .dpmsStatus == true)' >/dev/null 2>&1; then
    do_cleanup
else
    # 4. If HDMI-A-1 is taking longer (e.g. slow wake from suspend / power strip),
    # run a background retry watcher to clean up the moment HDMI-A-1 finishes handshake.
    (
        for retry in {1..60}; do
            sleep 0.5
            if hyprctl monitors -j | jq -e '.[] | select(.name == "HDMI-A-1" and .dpmsStatus == true)' >/dev/null 2>&1; then
                if hyprctl monitors -j | jq -e '.[] | select(.name == "HEADLESS-1")' >/dev/null 2>&1; then
                    hyprctl output remove HEADLESS-1 >/dev/null 2>&1
                fi
                for ws in $(hyprctl workspaces -j 2>/dev/null | jq -r '.[] | select(.monitor != "HDMI-A-1") | .name'); do
                    hyprctl dispatch "hl.dsp.workspace.move({ workspace = \"$ws\", monitor = \"HDMI-A-1\" })" >/dev/null 2>&1
                done
                rm -f /tmp/hypr-dpms-sleeping
                hyprctl dispatch 'hl.dsp.global("quickshell:lockFocus")' >/dev/null 2>&1
                break
            fi
        done
    ) >/dev/null 2>&1 &
fi
