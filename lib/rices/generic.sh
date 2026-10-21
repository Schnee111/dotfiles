# shellcheck shell=bash
# Rice: * — extracted from the original install.sh case arm.
# Called by install_rice() with (rice_dir, rice).
install_rice_generic() {
    local rice_dir="$1"
    local rice="$2"

    # Generic rice layout convention
    print_msg "Linking generic rice files for $rice..."
    for component_dir in "$rice_dir"/*/; do
        if [[ -d "$component_dir" ]]; then
            local cname
            cname="$(basename "$component_dir")"
            # If component matches a .config dir (e.g. hypr, waybar, niri, dunst, ags)
            for item in "$component_dir"*; do
                if [[ -f "$item" ]]; then
                    link_file "$item" "$CONFIG_DIR/$cname/$(basename "$item")"
                fi
            done
        fi
    done
}
