# shellcheck shell=bash
# Rice: end4 — extracted from the original install.sh case arm.
# Called by install_rice() with (rice_dir, rice).
install_rice_end4() {
    local rice_dir="$1"
    local rice="$2"

    # Hyprland configs
    link_file "$rice_dir/hypr/monitors.lua" "$CONFIG_DIR/hypr/monitors.lua"
    link_file "$rice_dir/hypr/hypridle.conf" "$CONFIG_DIR/hypr/hypridle.conf"
    link_file "$rice_dir/hypr/hyprlock.conf" "$CONFIG_DIR/hypr/hyprlock.conf"

    # Drop caelestia-only, vitreus-only, and minflair-only leftovers from a previous rice so a stale
    # entry-point can never shadow this rice's modules.
    for stale in "$CONFIG_DIR/hypr/scheme/default.lua" \
                 "$CONFIG_DIR/hypr/utils/functions.lua" \
                 "$CONFIG_DIR/hypr/utils/json.lua" \
                 "$CONFIG_DIR/hypr/variables.lua" \
                 "$CONFIG_DIR/hypr/hypr_vitreus.lua" \
                 "$CONFIG_DIR/hypr/vitreus_hypr.lua" \
                 "$CONFIG_DIR/hypr/vitreus_colors.lua" \
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

    # Hyprland Lua entry-point
    if [[ -f "$rice_dir/hypr/hyprland.lua" ]]; then
        link_file "$rice_dir/hypr/hyprland.lua" "$CONFIG_DIR/hypr/hyprland.lua"
    fi

    # Hyprland modules (keybinds + upstream defaults tracked per-rice)
    for f in "$rice_dir/hypr/hyprland/"*.lua; do
        if [[ -f "$f" ]]; then
            link_file "$f" "$CONFIG_DIR/hypr/hyprland/$(basename "$f")"
        fi
    done

    # Hyprland module subdirs (lib, services, scripts)
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
    # (e.g. caelestia's animations/decoration/gestures/group/input/misc)
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

    for f in "$rice_dir/hypr/custom/"*.lua "$rice_dir/hypr/custom/"*.json; do
        if [[ -f "$f" ]]; then
            link_file "$f" "$CONFIG_DIR/hypr/custom/$(basename "$f")"
        fi
    done

    if [[ -f "$rice_dir/hypr/custom/scripts/__restore_video_wallpaper.sh" ]]; then
        link_file "$rice_dir/hypr/custom/scripts/__restore_video_wallpaper.sh" "$CONFIG_DIR/hypr/custom/scripts/__restore_video_wallpaper.sh"
    fi

    for f in "$rice_dir/hypr/scripts/"*.sh "$rice_dir/hypr/scripts/"*.py; do
        if [[ -f "$f" ]]; then
            chmod +x "$f" 2>/dev/null || true
            link_file "$f" "$CONFIG_DIR/hypr/scripts/$(basename "$f")"
        fi
    done

    # Drop per-file links left by the previous rice. The switch relinks
    # what this rice ships but never deletes what it doesn't (e.g.
    # custom/input.lua, hyprland/scripts/zoom.sh,
    # shellOverrides/repo-defaults.lua from ii-p3drovfx), and a stale
    # link there wins over this rice's defaults.
    prune_foreign_links "$rice" \
        "$CONFIG_DIR/hypr" \
        "$CONFIG_DIR/hypr/custom" \
        "$CONFIG_DIR/hypr/scripts" \
        "$CONFIG_DIR/hypr/hyprland" \
        "$CONFIG_DIR/hypr/hyprland/shellOverrides" \
        "$CONFIG_DIR"/hypr/hyprland/*/

    # Illogical-impulse config
    if [[ -f "$rice_dir/illogical-impulse/config.json" ]]; then
        link_file "$rice_dir/illogical-impulse/config.json" "$CONFIG_DIR/illogical-impulse/config.json"
    fi

    # Ensure quickshell end4-pC fork is cloned
    if [[ ! -d "$CONFIG_DIR/quickshell/end4-pC" ]]; then
        if [[ $DRY_RUN -eq 1 ]]; then
            print_succ "[Dry-Run] Would clone Schnee111/end4-pC to $CONFIG_DIR/quickshell/end4-pC"
        else
            print_msg "Cloning Quickshell end4-pC fork..."
            git clone https://github.com/Schnee111/end4-pC.git "$CONFIG_DIR/quickshell/end4-pC"
        fi
    fi
}
