# shellcheck shell=bash
# Rice: noctalia — extracted from the original install.sh case arm.
# Called by install_rice() with (rice_dir, rice).
install_rice_noctalia() {
    local rice_dir="$1"

    # Umbriel compositor config
    if [[ -f "$rice_dir/umbriel/config.toml" ]]; then
        link_file "$rice_dir/umbriel/config.toml" "$CONFIG_DIR/umbriel/config.toml"
    fi
    # Noctalia desktop shell config
    if [[ -f "$rice_dir/noctalia/config.toml" ]]; then
        link_file "$rice_dir/noctalia/config.toml" "$CONFIG_DIR/noctalia/config.toml"
    fi
}
