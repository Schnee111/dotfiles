#!/bin/bash
set -o pipefail
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

# 2. Guarantee a usable Wayland output BEFORE turning physical displays off.
# A successful create request is not enough: the output can appear late, remain
# disabled, or fail to appear altogether. Keep displays on in all those cases.
anchor_ready() {
    hyprctl monitors -j 2>/dev/null | jq -e '
        .[] | select(.name == "HEADLESS-1" and .disabled != true and .dpmsStatus == true)
    ' >/dev/null 2>&1
}

if ! anchor_ready; then
    hyprctl output create headless HEADLESS-1 >/dev/null 2>&1 || true
    for _ in {1..20}; do
        if anchor_ready; then
            break
        fi
        sleep 0.05
    done
fi

if ! anchor_ready; then
    rm -f /tmp/hypr-dpms-sleeping
    echo "sleep_dpms: HEADLESS-1 is not ready; keeping physical displays powered on" >&2
    exit 1
fi

# 3. Power off active physical displays only, keeping HEADLESS-1 alive as anchor
for mon in $(hyprctl monitors -j 2>/dev/null | jq -r '.[] | select(.name != "HEADLESS-1") | .name'); do
    hyprctl dispatch "hl.dsp.dpms({ action = \"disable\", monitor = \"$mon\" })" >/dev/null 2>&1
done
