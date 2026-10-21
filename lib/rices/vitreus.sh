# shellcheck shell=bash
# Rice: vitreus — extracted from the original install.sh case arm.
# Called by install_rice() with (rice_dir, rice).
install_rice_vitreus() {
    local rice_dir="$1"

    # Vitreus Hyprland config + pleamar shell
    # Entry-point requires ~/.config/vitreus/hypr-vars.lua on first
    # run (package.path points there); pre-create so --verify-config
    # does not fail on a fresh switch.
    if [[ ! -f "$CONFIG_DIR/vitreus/hypr-vars.lua" ]]; then
        write_stub "$CONFIG_DIR/vitreus/hypr-vars.lua" 'return {}'
    fi
    # Drop end4-only leftovers (mirror of the caelestia branch cleanup):
    # shared entry files end4 owns, plus end4-specific modules and
    # scripts the vitreus entry-point never requires.
    for stale in "$CONFIG_DIR/hypr/monitors.lua" \
                 "$CONFIG_DIR/hypr/hyprlock.conf" \
                 "$CONFIG_DIR/hypr/hyprland/colors.lua" \
                 "$CONFIG_DIR/hypr/hyprland/variables.lua" \
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
            if [[ -f "$f" ]]; then
                link_file "$f" "$CONFIG_DIR/hypr/$(basename "$f")"
            fi
        done
        for d in "$rice_dir/hypr"/*/; do
            if [[ -d "$d" ]]; then
                local subname
                subname="$(basename "$d")"
                mkdir -p "$CONFIG_DIR/hypr/$subname"
                for sf in "$d"*; do
                    if [[ -f "$sf" ]]; then
                        link_file "$sf" "$CONFIG_DIR/hypr/$subname/$(basename "$sf")"
                    fi
                done
            fi
        done
        # Vitreus idle config (pleamar lockscreen, not quickshell)
        if [[ -f "$rice_dir/hypr/hypridle.conf" ]]; then
            link_file "$rice_dir/hypr/hypridle.conf" "$CONFIG_DIR/hypr/hypridle.conf"
        fi
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
    # Vitreus manages monitors inline in hyprland.lua and runs no
    # monitor watcher: stop the end4 watcher so it cannot rewrite
    # monitors.lua or respawn qs -c end4-pC mid-session.
    if [[ $DRY_RUN -eq 1 ]]; then
        print_msg "[Dry-Run] Would stop hyprland-monitor-watcher.service vitreus-brightness-mirror.service"
    else
        systemctl --user stop hyprland-monitor-watcher.service vitreus-brightness-mirror.service 2>/dev/null || true
    fi
    # Clone/update Vitreus shell into ~/.config/pleamar/shells/vitreus
    # (upstream repo; rice dir only carries our hypr side + rice.conf)
    if [[ $DRY_RUN -eq 1 ]]; then
        print_msg "[Dry-Run] Would clone/update Vitreus to $CONFIG_DIR/pleamar/shells/vitreus"
    else
        mkdir -p "$CONFIG_DIR/pleamar/shells"
        if [[ -d "$CONFIG_DIR/pleamar/shells/vitreus/.git" ]]; then
            print_msg "Updating Vitreus shell..."
            git -C "$CONFIG_DIR/pleamar/shells/vitreus" pull --ff-only --quiet 2>/dev/null || print_warn "Vitreus update failed, kept as-is"
        elif [[ ! -e "$CONFIG_DIR/pleamar/shells/vitreus" ]]; then
            print_msg "Cloning Vitreus shell..."
            git clone --depth 1 https://github.com/natepayn3/Vitreus.git "$CONFIG_DIR/pleamar/shells/vitreus" 2>/dev/null || print_warn "Vitreus clone failed (network?)"
        fi
        # Helper binaries (clipimg, polkit-agent, sysmon, term, keep, fonts)
        for hb in vitreus-clipimg vitreus-polkit-agent vitreus-sysmon vitreus-term vitreus-keep vitreus-fonts; do
            if [[ -x "$CONFIG_DIR/pleamar/shells/vitreus/bin/$hb" ]]; then
                ln -sf "$CONFIG_DIR/pleamar/shells/vitreus/bin/$hb" "$HOME/.local/bin/$hb"
            fi
        done
        # Vitreus palettes (rewritten from wallpaper by the shell; create stock copies on first install)
        for pal in palette wm-palette; do
            if [[ ! -f "$CONFIG_DIR/pleamar/shells/vitreus/$pal.plm" && -f "$CONFIG_DIR/pleamar/shells/vitreus/$pal.default.plm" ]]; then
                cp "$CONFIG_DIR/pleamar/shells/vitreus/$pal.default.plm" "$CONFIG_DIR/pleamar/shells/vitreus/$pal.plm"
            fi
        done
        # Shell binds loader for our entry-point
        if [[ -f "$CONFIG_DIR/pleamar/shells/vitreus/hypr_vitreus.lua" ]]; then
            link_file "$CONFIG_DIR/pleamar/shells/vitreus/hypr_vitreus.lua" "$CONFIG_DIR/hypr/hypr_vitreus.lua"
        fi
    fi
}
