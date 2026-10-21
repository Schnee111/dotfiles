# shellcheck shell=bash
# Rice: ii-p3drovfx — extracted from the original install.sh case arm.
# Called by install_rice() with (rice_dir, rice).
install_rice_ii_p3drovfx() {
    local rice_dir="$1"
    local rice="$2"

    # ii-p3drovfx Hyprland config + Quickshell II VFX
    # Drop leftovers from previous rices:
    for stale in "$CONFIG_DIR/hypr/scheme/default.lua" \
                 "$CONFIG_DIR/hypr/utils/functions.lua" \
                 "$CONFIG_DIR/hypr/utils/json.lua" \
                 "$CONFIG_DIR/hypr/variables.lua" \
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
    for stale_dir in "$CONFIG_DIR/hypr/scheme" \
                     "$CONFIG_DIR/hypr/utils"; do
        if [[ -e "$stale_dir" ]]; then
            if [[ $DRY_RUN -eq 1 ]]; then
                print_msg "[Dry-Run] Would remove stale dir: $stale_dir"
            else
                remove_path "$stale_dir"
            fi
        fi
    done

    # Link hyprland.lua entry-point FIRST
    if [[ -f "$rice_dir/hypr/hyprland.lua" ]]; then
        link_file "$rice_dir/hypr/hyprland.lua" "$CONFIG_DIR/hypr/hyprland.lua"
    fi

    # Shared configs
    if [[ -f "$rice_dir/hypr/monitors.lua" ]]; then
        link_file "$rice_dir/hypr/monitors.lua" "$CONFIG_DIR/hypr/monitors.lua"
    fi
    if [[ -f "$rice_dir/hypr/hypridle.conf" ]]; then
        link_file "$rice_dir/hypr/hypridle.conf" "$CONFIG_DIR/hypr/hypridle.conf"
    fi
    if [[ -f "$rice_dir/hypr/hyprlock.conf" ]]; then
        link_file "$rice_dir/hypr/hyprlock.conf" "$CONFIG_DIR/hypr/hyprlock.conf"
    fi

    # Hyprland modules (keybinds + upstream defaults tracked per-rice)
    for f in "$rice_dir/hypr/hyprland/"*.lua; do
        if [[ -f "$f" ]]; then
            link_file "$f" "$CONFIG_DIR/hypr/hyprland/$(basename "$f")"
        fi
    done

    # Hyprland module subdirs (lib, services, scripts, shellOverrides)
    for d in "$rice_dir/hypr/hyprland/"*/; do
        if [[ -d "$d" ]]; then
            local subname
            subname="$(basename "$d")"
            mkdir -p "$CONFIG_DIR/hypr/hyprland/$subname"
            for sf in "$d"*; do
                if [[ -f "$sf" ]]; then
                    link_file "$sf" "$CONFIG_DIR/hypr/hyprland/$subname/$(basename "$sf")"
                fi
            done
        fi
    done

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

    # Custom user configs (keybinds, rules, session layout)
    for f in "$rice_dir/hypr/custom/"*.lua "$rice_dir/hypr/custom/"*.json; do
        if [[ -f "$f" ]]; then
            link_file "$f" "$CONFIG_DIR/hypr/custom/$(basename "$f")"
        fi
    done

    # Drop per-file links left by the previous rice (see end4 branch).
    prune_foreign_links "$rice" \
        "$CONFIG_DIR/hypr" \
        "$CONFIG_DIR/hypr/custom" \
        "$CONFIG_DIR/hypr/scripts" \
        "$CONFIG_DIR/hypr/hyprland" \
        "$CONFIG_DIR/hypr/hyprland/shellOverrides" \
        "$CONFIG_DIR"/hypr/hyprland/*/

    # Stop end4 monitor watcher so it doesn't conflict
    if [[ $DRY_RUN -eq 1 ]]; then
        print_msg "[Dry-Run] Would stop hyprland-monitor-watcher.service vitreus-brightness-mirror.service"
    else
        systemctl --user stop hyprland-monitor-watcher.service vitreus-brightness-mirror.service 2>/dev/null || true
    fi

    # ii is an end-4 derivative: it reads AND writes its shell state in
    # the shared ~/.config/illogical-impulse/config.json. Link this
    # rice's own copy, otherwise an ii session overwrites end4's
    # bar/dock/settings with ii's schema and the bar comes back broken.
    if [[ -f "$rice_dir/illogical-impulse/config.json" ]]; then
        link_file "$rice_dir/illogical-impulse/config.json" "$CONFIG_DIR/illogical-impulse/config.json"
    fi

    # Ensure quickshell ii fork is linked from rice-sources
    if [[ $DRY_RUN -eq 1 ]]; then
        print_msg "[Dry-Run] Would link quickshell ii to $CONFIG_DIR/quickshell/ii"
    else
        mkdir -p "$CONFIG_DIR/quickshell"
        if [[ -d "$HOME/Projects/rice-sources/ii-p3drovfx/dots/.config/quickshell/ii" ]]; then
            link_file "$HOME/Projects/rice-sources/ii-p3drovfx/dots/.config/quickshell/ii" "$CONFIG_DIR/quickshell/ii"
        fi
    fi
}
