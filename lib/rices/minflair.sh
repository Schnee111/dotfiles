# shellcheck shell=bash
# Rice: minflair — extracted from the original install.sh case arm.
# Called by install_rice() with (rice_dir, rice).
install_rice_minflair() {
    local rice_dir="$1"

    # Minflair Hyprland config + Quickshell Minflair
    # Drop leftovers from previous rices:
    for stale in "$CONFIG_DIR/hypr/monitors.lua" \
                 "$CONFIG_DIR/hypr/hyprlock.conf" \
                 "$CONFIG_DIR/hypr/scheme/default.lua" \
                 "$CONFIG_DIR/hypr/utils/functions.lua" \
                 "$CONFIG_DIR/hypr/utils/json.lua" \
                 "$CONFIG_DIR/hypr/variables.lua" \
                 "$CONFIG_DIR/hypr/hypr_vitreus.lua"; do
        if [[ -L "$stale" || -e "$stale" ]]; then
            if [[ $DRY_RUN -eq 1 ]]; then
                print_msg "[Dry-Run] Would remove stale: $stale"
            else
                remove_path "$stale"
            fi
        fi
    done
    for stale_dir in "$CONFIG_DIR/hypr/custom" \
                     "$CONFIG_DIR/hypr/scheme" \
                     "$CONFIG_DIR/hypr/utils" \
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

    # Link hyprland.lua entry-point FIRST
    if [[ -f "$rice_dir/hypr/hyprland.lua" ]]; then
        link_file "$rice_dir/hypr/hyprland.lua" "$CONFIG_DIR/hypr/hyprland.lua"
    fi

    # Link submodules in hyprland/
    if [[ -d "$rice_dir/hypr/hyprland" ]]; then
        mkdir -p "$CONFIG_DIR/hypr/hyprland"
        for sf in "$rice_dir/hypr/hyprland/"*.lua; do
            if [[ -f "$sf" ]]; then
                link_file "$sf" "$CONFIG_DIR/hypr/hyprland/$(basename "$sf")"
            fi
        done
    fi

    # Link scripts in scripts/
    if [[ -d "$rice_dir/hypr/scripts" ]]; then
        mkdir -p "$CONFIG_DIR/hypr/scripts"
        for sf in "$rice_dir/hypr/scripts/"*.sh; do
            if [[ -f "$sf" ]]; then
                link_file "$sf" "$CONFIG_DIR/hypr/scripts/$(basename "$sf")"
            fi
        done
    fi

    # Link hypridle.conf & colors.conf
    if [[ -f "$rice_dir/hypr/hypridle.conf" ]]; then
        link_file "$rice_dir/hypr/hypridle.conf" "$CONFIG_DIR/hypr/hypridle.conf"
    fi
    if [[ -f "$rice_dir/hypr/colors.conf" ]]; then
        link_file "$rice_dir/hypr/colors.conf" "$CONFIG_DIR/hypr/colors.conf"
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

    # Minflair manages monitors inline with physical DRM checks: stop monitor watcher
    if [[ $DRY_RUN -eq 1 ]]; then
        print_msg "[Dry-Run] Would stop hyprland-monitor-watcher.service vitreus-brightness-mirror.service"
    else
        systemctl --user stop hyprland-monitor-watcher.service vitreus-brightness-mirror.service 2>/dev/null || true
    fi

    # Link quickshell minflair profile
    if [[ $DRY_RUN -eq 1 ]]; then
        print_msg "[Dry-Run] Would link minflair quickshell to $CONFIG_DIR/quickshell/minflair"
    else
        mkdir -p "$CONFIG_DIR/quickshell"
        if [[ -d "$HOME/Projects/rice-sources/minflair/config/quickshell" ]]; then
            link_file "$HOME/Projects/rice-sources/minflair/config/quickshell" "$CONFIG_DIR/quickshell/minflair"
        fi
        # Pre-generate default wallpaper cache if not present
        mkdir -p "$HOME/.cache/quickshell"
        if [[ ! -f "$HOME/.cache/quickshell/current_wallpaper" && -f "$HOME/Pictures/Wallpapers/naive-girl_raven_wood.png" ]]; then
            echo "naive-girl_raven_wood.png" > "$HOME/.cache/quickshell/current_wallpaper"
        fi
    fi
}
