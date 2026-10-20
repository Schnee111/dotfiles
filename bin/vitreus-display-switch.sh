#!/usr/bin/env bash
# ==============================================================================
# Vitreus display switcher
# Bound to: SUPER + P and XF86Display (hyprland/keybinds.lua)
#
#   vitreus-display-switch.sh              rofi menu: external / laptop / extend
#   vitreus-display-switch.sh --set MODE   apply MODE and remember it
#   vitreus-display-switch.sh --reapply    apply the remembered mode (for hotplug)
#   vitreus-display-switch.sh --watch      follow Hyprland's socket2 and re-apply
#                                          the mode when the HDMI panel comes or goes
#
# Unlike the old caelestia script this one writes ~/.config/hypr/vitreus_monitors.lua,
# which hyprland.lua dofiles after its static monitor block. That is the same file
# Settings > Display keeps, so a choice survives `hyprctl reload` and a restart.
# ==============================================================================
set -uo pipefail

CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
HYPR_DIR="$CONFIG_HOME/hypr"
VITREUS_DIR="$CONFIG_HOME/vitreus"
MODE_FILE="$VITREUS_DIR/display-mode"
MON_FILE="$HYPR_DIR/vitreus_monitors.lua"
STAMP="${XDG_RUNTIME_DIR:-/tmp}/vitreus-display-switch.stamp"

# The panels this rice is set up for.
LAPTOP_MODE="2880x1800@90"
LAPTOP_SCALE="1.6"
LAPTOP_WIDTH=1800          # logical width at scale 1.6, for placing the HDMI panel beside it
HDMI_MODE="1920x1080@200"

notify() { notify-send -a "Display" "$@" >/dev/null 2>&1 || true; }

play() { play_sound.sh "$1" >/dev/null 2>&1 || true; }

hdmi_connected() {
    # On hybrid-GPU laptops the external port can sit on card1 while card0 says
    # disconnected, so any HDMI-A-1 connector counts.
    grep -qx 'connected' /sys/class/drm/card*-HDMI-A-1/status 2>/dev/null
}

monitor_on() {
    local state
    state=$(hyprctl monitors all -j 2>/dev/null \
        | jq -r --arg n "$1" '.[] | select(.name == $n) | if .disabled then "off" else "on" end' 2>/dev/null)
    printf '%s' "${state:-off}"
}

effective_mode() {
    case "$(monitor_on eDP-1)$(monitor_on HDMI-A-1)" in
        onon)  echo extend   ;;
        offon) echo external ;;
        onoff) echo laptop   ;;
    esac
}

hypr_eval() { hyprctl eval "$1" >/dev/null 2>&1; }

write_monitors_file() {
    local body=$1
    mkdir -p "$HYPR_DIR"
    {
        printf '%s\n' '-- Written by the Vitreus display switcher; edits here are overwritten.'
        printf '%s\n' '-- hyprland.lua loads it after its static monitor block, so it wins for the monitors it names.'
        printf '%s\n' "$body"
    } > "$MON_FILE.tmp" && mv -f "$MON_FILE.tmp" "$MON_FILE"
}

# apply_mode MODE [remember]
# Runs in a subshell so the lock is released as soon as it returns.
apply_mode() (
    local mode=$1 remember=${2:-yes} body

    mkdir -p "${STAMP%/*}"
    exec 9>"${STAMP}.lock"
    flock -n 9 || exit 0
    date +%s > "$STAMP"

    case "$mode" in
        external)
            # Bring the destination up first, then drop the laptop panel:
            # disabling the source before the target exists loses the workspaces.
            hypr_eval 'hl.monitor({ output = "HDMI-A-1", mode = "'"$HDMI_MODE"'", position = "0x0", scale = 1, transform = 0, disabled = false })'
            sleep 0.5
            hypr_eval 'hl.monitor({ output = "eDP-1", disabled = true })'
            body=$(printf '%s\n%s' \
                'hl.monitor({ output = "HDMI-A-1", mode = "'"$HDMI_MODE"'", position = "0x0", scale = 1, transform = 0, disabled = false })' \
                'hl.monitor({ output = "eDP-1", disabled = true })')
            ;;
        laptop)
            hypr_eval 'hl.monitor({ output = "eDP-1", mode = "'"$LAPTOP_MODE"'", position = "0x0", scale = '"$LAPTOP_SCALE"', transform = 0, disabled = false })'
            sleep 0.5
            hypr_eval 'hl.monitor({ output = "HDMI-A-1", disabled = true })'
            body=$(printf '%s\n%s' \
                'hl.monitor({ output = "eDP-1", mode = "'"$LAPTOP_MODE"'", position = "0x0", scale = '"$LAPTOP_SCALE"', transform = 0, disabled = false })' \
                'hl.monitor({ output = "HDMI-A-1", disabled = true })')
            ;;
        extend)
            hypr_eval 'hl.monitor({ output = "eDP-1", mode = "'"$LAPTOP_MODE"'", position = "0x0", scale = '"$LAPTOP_SCALE"', transform = 0, disabled = false })
hl.monitor({ output = "HDMI-A-1", mode = "'"$HDMI_MODE"'", position = "'"$LAPTOP_WIDTH"'x0", scale = 1, transform = 0, disabled = false })'
            body=$(printf '%s\n%s' \
                'hl.monitor({ output = "eDP-1", mode = "'"$LAPTOP_MODE"'", position = "0x0", scale = '"$LAPTOP_SCALE"', transform = 0, disabled = false })' \
                'hl.monitor({ output = "HDMI-A-1", mode = "'"$HDMI_MODE"'", position = "'"$LAPTOP_WIDTH"'x0", scale = 1, transform = 0, disabled = false })')
            ;;
        *)
            exit 1
            ;;
    esac

    write_monitors_file "$body"
    if [ "$remember" = yes ]; then
        mkdir -p "$VITREUS_DIR"
        printf '%s\n' "$mode" > "$MODE_FILE"
    fi

    case "$mode" in
        external) notify -i desktop_windows "Display Output" "External Monitor Only (1080p @ 200Hz)"; play Chord.mp3 ;;
        laptop)   notify -i laptop_chromebook "Display Output" "Laptop Screen Only (2.8K @ 90Hz, scale 1.6)"; play Swish.mp3 ;;
        extend)   notify -i devices "Display Output" "Extended Displays (both panels)"; play Chord.mp3 ;;
    esac
)

# The mode to fall back on when the remembered one needs a panel that is not here.
reapply() {
    local mode
    if [ -f "$MODE_FILE" ]; then
        mode=$(tr -d '[:space:]' < "$MODE_FILE")
    elif hdmi_connected; then
        mode=external
    else
        mode=laptop
    fi

    if [ "$mode" != laptop ] && ! hdmi_connected; then
        mode=laptop
    fi
    case "$mode" in
        external|laptop|extend) ;;
        *) mode=laptop ;;
    esac

    # Nothing to do when the screens already are that way.
    [ "$(effective_mode)" = "$mode" ] && exit 0
    apply_mode "$mode" no
}

watch() {
    local socket="$XDG_RUNTIME_DIR/hypr/${HYPRLAND_INSTANCE_SIGNATURE:-}/.socket2.sock" line
    [ -S "$socket" ] || { echo "vitreus-display-switch: no Hyprland socket at $socket" >&2; exit 1; }

    socat -u UNIX-CONNECT:"$socket" - | while IFS= read -r line; do
        case "$line" in
            monitoradded\>\>*HDMI-A-1*|monitoraddedv2\>\>*HDMI-A-1*|\
            monitorremoved\>\>*HDMI-A-1*|monitorremovedv2\>\>*HDMI-A-1*)
                # Our own apply disables/enables the port and wakes the same events:
                # ignore anything that lands within a few seconds of a change.
                local last now
                last=$(cat "$STAMP" 2>/dev/null || echo 0)
                now=$(date +%s)
                (( now - last < 4 )) && continue
                sleep 1
                "$0" --reapply
                ;;
        esac
    done
}

choose() {
    local options chosen
    options=$'󰍹  External Monitor Only\n󰌢  Laptop Screen Only\n󰍺  Extend Displays'

    local args=(-dmenu -i -no-custom -p "󰍹 ")
    [ -f "$HOME/.config/rofi/display.rasi" ] && args+=(-theme "$HOME/.config/rofi/display.rasi")

    chosen=$(printf '%s\n' "$options" | rofi "${args[@]}") || exit 0
    [ -z "$chosen" ] && exit 0

    local mode
    case "$chosen" in
        *External*) mode=external ;;
        *Laptop*)   mode=laptop   ;;
        *Extend*)   mode=extend   ;;
        *) exit 0 ;;
    esac

    if [ "$mode" != laptop ] && ! hdmi_connected; then
        notify -u critical -i error "Display Error" "HDMI monitor not detected. Switch cancelled."
        exit 1
    fi

    if [ "$(effective_mode)" = "$mode" ]; then
        notify -i dialog-information "Display Output" "Already on this layout"
        exit 0
    fi

    apply_mode "$mode" yes
}

case "${1:-}" in
    --set)
        [ $# -ge 2 ] || { echo "usage: $0 --set external|laptop|extend" >&2; exit 2; }
        apply_mode "$2" yes
        ;;
    --reapply) reapply ;;
    --watch)   watch ;;
    ""|--menu) choose ;;
    *) echo "usage: $0 [--set external|laptop|extend] [--reapply] [--watch]" >&2; exit 2 ;;
esac
