#!/usr/bin/env bash
# ==============================================================================
# Power Profile Toggle (Quiet / Balanced / Performance)
# ==============================================================================
set -euo pipefail

SYSFS_PROFILE="/sys/firmware/acpi/platform_profile"

if [[ ! -f "$SYSFS_PROFILE" ]]; then
    notify-send -a "Power Profile" -n "error" "Power Profile Error" "Platform profile is not supported on this device." -t 3000
    exit 1
fi

CURRENT_PROFILE=$(cat "$SYSFS_PROFILE" 2>/dev/null || echo "balanced")

case "$CURRENT_PROFILE" in
    "quiet")
        NEW_PROFILE="balanced"
        MSG_TITLE="Power Mode: Balanced"
        MSG_DESC="Standard dynamic fan & performance scaling."
        ICON="power"
        SOUND="/usr/share/sounds/gnome/default/alerts/click.ogg"
        ;;
    "balanced")
        NEW_PROFILE="performance"
        MSG_TITLE="Power Mode: Performance"
        MSG_DESC="Turbo cooling & maximum performance active."
        ICON="power"
        SOUND="/usr/share/sounds/gnome/default/alerts/swing.ogg"
        ;;
    "performance"|*)
        NEW_PROFILE="quiet"
        MSG_TITLE="Power Mode: Quiet"
        MSG_DESC="Whisper silent fans & power saving active."
        ICON="power"
        SOUND="/usr/share/sounds/gnome/default/alerts/hum.ogg"
        ;;
esac

apply_profile() {
    local prof="$1"
    if [[ -w "$SYSFS_PROFILE" ]] && echo "$prof" > "$SYSFS_PROFILE" 2>/dev/null; then
        return 0
    fi
    if command -v pkexec >/dev/null 2>&1; then
        pkexec /usr/bin/bash -c "echo $prof > $SYSFS_PROFILE" 2>/dev/null && return 0
    fi
    return 1
}

if apply_profile "$NEW_PROFILE"; then
    # If watcher is not running, play sound and send notification directly
    if ! pgrep -f "monitor_watcher.py" >/dev/null 2>&1; then
        pw-play "$SOUND" 2>/dev/null &
        notify-send -a "Power Profile" -n "speed" "$MSG_TITLE" "$MSG_DESC" -t 2500
    fi
else
    notify-send -a "Power Profile" -n "error" "Power Profile Failed" "Permission denied. Run ~/Projects/dotfiles/setup_power_permissions.sh" -t 3500
    exit 1
fi
