# shellcheck shell=bash
# Rice: prism-shell — extracted from the original install.sh case arm.
# Called by install_rice() with (rice_dir, rice).
install_rice_prism_shell() {
    local rice_dir="$1"
    local rice="$2"

    # prism-shell Hyprland config + Quickshell Prism
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
        [[ -f "$f" ]] && link_file "$f" "$CONFIG_DIR/hypr/hyprland/$(basename "$f")"
    done

    # Hyprland module subdirs (lib, services, scripts, shellOverrides)
    for d in "$rice_dir/hypr/hyprland/"*/; do
        if [[ -d "$d" ]]; then
            local subname
            subname="$(basename "$d")"
            mkdir -p "$CONFIG_DIR/hypr/hyprland/$subname"
            for sf in "$d"*; do
                [[ -f "$sf" ]] && link_file "$sf" "$CONFIG_DIR/hypr/hyprland/$subname/$(basename "$sf")"
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
    if [[ -d "$rice_dir/hypr/custom" ]]; then
        for f in "$rice_dir/hypr/custom/"*.lua "$rice_dir/hypr/custom/"*.json; do
            [[ -f "$f" ]] && link_file "$f" "$CONFIG_DIR/hypr/custom/$(basename "$f")"
        done
    fi

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

    # Ensure quickshell prism profile is linked from rice-sources
    if [[ $DRY_RUN -eq 1 ]]; then
        print_msg "[Dry-Run] Would link quickshell prism to $CONFIG_DIR/quickshell/prism"
    else
        mkdir -p "$CONFIG_DIR/quickshell"
        if [[ -d "$HOME/Projects/rice-sources/prism-shell" ]]; then
            link_file "$HOME/Projects/rice-sources/prism-shell" "$CONFIG_DIR/quickshell/prism"
        fi
    fi
}
