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

# 1. Power on physical displays
for mon in $(hyprctl monitors -j 2>/dev/null | jq -r '.[] | select(.name != "HEADLESS-1") | .name'); do
    hyprctl dispatch "hl.dsp.dpms({ action = \"enable\", monitor = \"$mon\" })" >/dev/null 2>&1
done
hyprctl dispatch 'hl.dsp.dpms({ action = "enable" })' >/dev/null 2>&1

# 2. Allow monitor handshake & clock signal to stabilize:
# Wait up to 8 seconds (40 iterations x 0.2s) until at least 1 physical monitor is active with dpmsStatus: true
for i in {1..40}; do
    if hyprctl monitors -j | jq -e '.[] | select(.name != "HEADLESS-1" and .dpmsStatus == true)' >/dev/null 2>&1; then
        break
    fi
    sleep 0.2
done

# Small grace period for client surfaces to adapt
sleep 0.2

# Helper to safely clean up headless anchor and migrate any stranded workspaces
do_cleanup() {
    if hyprctl monitors -j | jq -e '.[] | select(.name == "HEADLESS-1")' >/dev/null 2>&1; then
        hyprctl output remove HEADLESS-1 >/dev/null 2>&1
    fi
    PHYS_MON=$(hyprctl monitors -j 2>/dev/null | jq -r '[.[] | select(.name != "HEADLESS-1")] | .[0].name // empty')
    if [ -n "$PHYS_MON" ]; then
        for ws in $(hyprctl workspaces -j 2>/dev/null | jq -r --arg pm "$PHYS_MON" '.[] | select(.monitor != $pm) | .name'); do
            hyprctl dispatch "hl.dsp.workspace.move({ workspace = \"$ws\", monitor = \"$PHYS_MON\" })" >/dev/null 2>&1
        done
    fi
    rm -f /tmp/hypr-dpms-sleeping
    hyprctl dispatch 'hl.dsp.global("quickshell:lockFocus")' >/dev/null 2>&1
}

# 3. Check if physical display is verified active
if hyprctl monitors -j | jq -e '.[] | select(.name != "HEADLESS-1" and .dpmsStatus == true)' >/dev/null 2>&1; then
    do_cleanup
else
    # 4. If physical display takes longer (e.g. slow wake from suspend / power strip),
    # run a background retry watcher to clean up the moment the display finishes handshake.
    (
        for retry in {1..40}; do
            sleep 0.5
            if hyprctl monitors -j | jq -e '.[] | select(.name != "HEADLESS-1" and .dpmsStatus == true)' >/dev/null 2>&1; then
                do_cleanup
                break
            fi
        done
    ) >/dev/null 2>&1 &
fi
