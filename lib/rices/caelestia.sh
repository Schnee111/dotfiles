# shellcheck shell=bash
# Rice: caelestia — extracted from the original install.sh case arm.
# Called by install_rice() with (rice_dir, rice).
install_rice_caelestia() {
    local rice_dir="$1"

    # Caelestia Hyprland config
    # Entry-point requires ~/.config/caelestia/hypr-vars.lua on first
    # run (package.path points there); pre-create so --verify-config
    # does not fail on a fresh switch.
    mkdir -p "$CONFIG_DIR/caelestia"
    if [[ ! -f "$CONFIG_DIR/caelestia/hypr-vars.lua" ]]; then
        if [[ $DRY_RUN -eq 1 ]]; then
            print_msg "[Dry-Run] Would create stub: $CONFIG_DIR/caelestia/hypr-vars.lua"
        else
            echo 'return {}' > "$CONFIG_DIR/caelestia/hypr-vars.lua"
        fi
    fi
    # Drop end4-only and vitreus-only leftovers (mirror of the end4 branch cleanup):
    # shared entry files end4 owns, plus end4-specific modules and
    # scripts the caelestia entry-point never requires.
    for stale in "$CONFIG_DIR/hypr/monitors.lua" \
                 "$CONFIG_DIR/hypr/hypridle.conf" \
                 "$CONFIG_DIR/hypr/hyprlock.conf" \
                 "$CONFIG_DIR/hypr/hyprland/colors.lua" \
                 "$CONFIG_DIR/hypr/hyprland/variables.lua" \
                 "$CONFIG_DIR/hypr/hypr_vitreus.lua" \
                 "$CONFIG_DIR/hypr/colors.conf" \
                 "$CONFIG_DIR/hypr/colors.lua"; do
        if [[ -L "$stale" || -e "$stale" ]]; then
            if [[ $DRY_RUN -eq 1 ]]; then
                print_msg "[Dry-Run] Would remove stale: $stale"
            else
                remove_path "$stale"
            fi
        fi
    done
    for stale_dir in "$CONFIG_DIR/hypr/custom" \
                     "$CONFIG_DIR/hypr/scripts" \
                     "$CONFIG_DIR/hypr/hyprland/lib" \
                     "$CONFIG_DIR/hypr/hyprland/services" \
                     "$CONFIG_DIR/hypr/hyprland/scripts" \
                     "$CONFIG_DIR/hypr/hyprland/shellOverrides"; do
        if [[ -e "$stale_dir" ]]; then
            if [[ $DRY_RUN -eq 1 ]]; then
                print_msg "[Dry-Run] Would remove stale dir: $stale_dir"
            else
                remove_path "$stale_dir"
            fi
        fi
    done
    if [[ -d "$rice_dir/hypr" ]]; then
        for f in "$rice_dir/hypr/"*.lua; do
            [[ -f "$f" ]] && link_file "$f" "$CONFIG_DIR/hypr/$(basename "$f")"
        done
        for d in "$rice_dir/hypr"/*/; do
            if [[ -d "$d" ]]; then
                local subname
                subname="$(basename "$d")"
                mkdir -p "$CONFIG_DIR/hypr/$subname"
                for sf in "$d"*; do
                    [[ -f "$sf" ]] && link_file "$sf" "$CONFIG_DIR/hypr/$subname/$(basename "$sf")"
                done
            fi
        done
    fi
    # Drop stale hyprland/*.lua modules left by another rice
    for sf in "$CONFIG_DIR/hypr/hyprland/"*.lua; do
        [[ -L "$sf" || -e "$sf" ]] || continue
        if [[ ! -e "$rice_dir/hypr/hyprland/$(basename "$sf")" ]]; then
            if [[ $DRY_RUN -eq 1 ]]; then
                print_msg "[Dry-Run] Would remove stale: $sf"
            else
                remove_path "$sf"
                print_warn "Removed stale: $sf"
            fi
        fi
    done
    # Caelestia manages monitors inline in hyprland.lua and runs no
    # monitor watcher: stop the end4 watcher so it cannot rewrite
    # monitors.lua or respawn qs -c end4-pC mid-session.
    # Also stop the vitreus brightness mirror, which is vitreus-only.
    if [[ $DRY_RUN -eq 1 ]]; then
        print_msg "[Dry-Run] Would stop hyprland-monitor-watcher.service vitreus-brightness-mirror.service"
    else
        systemctl --user stop hyprland-monitor-watcher.service vitreus-brightness-mirror.service 2>/dev/null || true
    fi
}
