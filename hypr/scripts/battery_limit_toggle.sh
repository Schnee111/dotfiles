#!/usr/bin/env bash
# ==============================================================================
# Battery Charge Limit Toggle (80% / 100%)
# ==============================================================================
set -euo pipefail

SYSFS_BAT="/sys/class/power_supply/BAT0/charge_control_end_threshold"

if [[ ! -f "$SYSFS_BAT" ]]; then
    notify-send -a "Battery Care" -i "dialog-error" "Battery Limit Error" "Hardware charge threshold is not supported on this device." -t 3000
    exit 1
fi

CURRENT_VAL=$(cat "$SYSFS_BAT" 2>/dev/null || echo "100")

if [[ "$CURRENT_VAL" -le 80 ]]; then
    NEW_VAL=100
    MSG_TITLE="Battery Limit: 100%"
    MSG_DESC="Full capacity charging active. Ideal for travel."
    ICON="battery-full-charging-symbolic"
else
    NEW_VAL=80
    MSG_TITLE="Battery Limit: 80%"
    MSG_DESC="Battery health protection active. Ideal for AC plug."
    ICON="battery-charging-symbolic"
fi

apply_limit() {
    local val="$1"
    if [[ -w "$SYSFS_BAT" ]] && echo "$val" > "$SYSFS_BAT" 2>/dev/null; then
        return 0
    fi
    if command -v pkexec >/dev/null 2>&1; then
        pkexec /usr/bin/bash -c "echo $val > $SYSFS_BAT" 2>/dev/null && return 0
    fi
    return 1
}

if apply_limit "$NEW_VAL"; then
    notify-send -a "Battery Care" -i "$ICON" "$MSG_TITLE" "$MSG_DESC" -t 2500
else
    notify-send -a "Battery Care" -i "dialog-error" "Battery Limit Failed" "Permission denied. Run ~/Projects/dotfiles/setup_power_permissions.sh" -t 3500
    exit 1
fi
