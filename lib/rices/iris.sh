# shellcheck shell=bash
# Rice: iris — extracted from the original install.sh case arm.
# Called by install_rice() with (rice_dir, rice).
install_rice_iris() {
    local rice_dir="$1"

    # Niri config
    if [[ -f "$rice_dir/niri/config.kdl" ]]; then
        link_file "$rice_dir/niri/config.kdl" "$CONFIG_DIR/niri/config.kdl"
    fi
    # iNiR config
    if [[ -f "$rice_dir/inir/config.json" ]]; then
        link_file "$rice_dir/inir/config.json" "$CONFIG_DIR/inir/config.json"
    fi
}
