#!/usr/bin/env bash
# ==============================================================================
# Dotfiles Installer & Multi-Rice Manager
# ==============================================================================
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
BACKUP_DIR="$HOME/.config/dotfiles_backup_$(date +%Y%m%d_%H%M%S)"
CURRENT_RICE_FILE="$CONFIG_DIR/.current_rice"
DRY_RUN=0
TARGET_RICE=""

print_msg() { echo -e "\033[1;34m[INFO]\033[0m $1"; }
print_succ() { echo -e "\033[1;32m[OK]\033[0m $1"; }
print_warn() { echo -e "\033[1;33m[WARN]\033[0m $1"; }

show_help() {
    cat << EOF
Usage: ./install.sh [OPTIONS] [RICE_NAME]

Options:
  -n, --dry-run        Show what would be linked without making changes
  -r, --rice <NAME>    Specify rice to link (default: active rice or 'end4')
  -h, --help           Show this help message

Available Rices:
$(for d in "$DOTFILES_DIR"/rices/*/; do [[ -d "$d" ]] && echo "  - $(basename "$d")"; done)

Description:
  Creates symbolic links for common configs and the active desktop rice.
  Existing files will be safely backed up to:
  $BACKUP_DIR
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -n|--dry-run) DRY_RUN=1; shift ;;
        -r|--rice) TARGET_RICE="$2"; shift 2 ;;
        -h|--help) show_help; exit 0 ;;
        *)
            if [[ -z "$TARGET_RICE" && -d "$DOTFILES_DIR/rices/$1" ]]; then
                TARGET_RICE="$1"; shift
            else
                echo "Unknown option or invalid rice: $1"; show_help; exit 1
            fi
            ;;
    esac
done

if [[ -z "$TARGET_RICE" ]]; then
    if [[ -f "$CURRENT_RICE_FILE" ]]; then
        TARGET_RICE="$(cat "$CURRENT_RICE_FILE" | tr -d '[:space:]')"
    fi
    TARGET_RICE="${TARGET_RICE:-end4}"
fi

link_file() {
    local src="$1"
    local dest="$2"

    local dest_dir
    dest_dir="$(dirname "$dest")"

    if [[ ! -d "$dest_dir" ]]; then
        if [[ $DRY_RUN -eq 1 ]]; then
            print_msg "[Dry-Run] Would create directory: $dest_dir"
        else
            mkdir -p "$dest_dir"
        fi
    fi

    if [[ -e "$dest" || -L "$dest" ]]; then
        if [[ -L "$dest" && "$(readlink -f "$dest")" == "$(readlink -f "$src")" ]]; then
            print_succ "Already linked: $dest -> $src"
            return 0
        fi

        if [[ $DRY_RUN -eq 1 ]]; then
            print_warn "[Dry-Run] Would backup: $dest -> $BACKUP_DIR"
        else
            mkdir -p "$BACKUP_DIR"
            mv "$dest" "$BACKUP_DIR/"
            print_warn "Backed up existing: $dest -> $BACKUP_DIR/"
        fi
    fi

    if [[ $DRY_RUN -eq 1 ]]; then
        print_succ "[Dry-Run] Would link: $dest -> $src"
    else
        ln -sf "$src" "$dest"
        print_succ "Linked: $dest -> $src"
    fi
}

# ==============================================================================
# 1. COMMON SYSTEM CONFIGS (Shared across all rices)
# ==============================================================================
install_common() {
    print_msg "Installing common configurations..."

    # Terminal & Shell
    link_file "$DOTFILES_DIR/common/kitty/kitty.conf" "$CONFIG_DIR/kitty/kitty.conf"
    link_file "$DOTFILES_DIR/common/fish/config.fish" "$CONFIG_DIR/fish/config.fish"
    link_file "$DOTFILES_DIR/common/starship/starship.toml" "$CONFIG_DIR/starship.toml"

    # Rofi Launchpad
    link_file "$DOTFILES_DIR/common/rofi/colors.rasi" "$CONFIG_DIR/rofi/colors.rasi"
    link_file "$DOTFILES_DIR/common/rofi/launchpad.rasi" "$CONFIG_DIR/rofi/launchpad.rasi"
    link_file "$DOTFILES_DIR/common/rofi/display.rasi" "$CONFIG_DIR/rofi/display.rasi"
    link_file "$DOTFILES_DIR/common/rofi/launcher.sh" "$CONFIG_DIR/rofi/launcher.sh"
    chmod +x "$DOTFILES_DIR/common/rofi/launcher.sh" 2>/dev/null || true

    # Audio DSP PipeWire
    link_file "$DOTFILES_DIR/common/pipewire/10-headphone-balance.conf" "$CONFIG_DIR/pipewire/pipewire.conf.d/10-headphone-balance.conf"

    # Swappy Screenshot
    link_file "$DOTFILES_DIR/common/swappy/config" "$CONFIG_DIR/swappy/config"

    # Fontconfig
    link_file "$DOTFILES_DIR/common/fontconfig/fonts.conf" "$CONFIG_DIR/fontconfig/fonts.conf"

    # Fastfetch
    link_file "$DOTFILES_DIR/common/fastfetch/config.jsonc" "$CONFIG_DIR/fastfetch/config.jsonc"
    link_file "$DOTFILES_DIR/common/fastfetch/set-logo.sh" "$CONFIG_DIR/fastfetch/set-logo.sh"
    chmod +x "$DOTFILES_DIR/common/fastfetch/set-logo.sh" 2>/dev/null || true
    if [[ -d "$DOTFILES_DIR/common/fastfetch/logos" ]]; then
        mkdir -p "$CONFIG_DIR/fastfetch/logos"
        for f in "$DOTFILES_DIR/common/fastfetch/logos/"*; do
            [[ -e "$f" || -L "$f" ]] && link_file "$f" "$CONFIG_DIR/fastfetch/logos/$(basename "$f")"
        done
    fi

    # Chrome Native Messaging Host
    if [[ -f "$DOTFILES_DIR/common/chrome/com.schnee.wallpaper_color.json" ]]; then
        mkdir -p "$CONFIG_DIR/google-chrome/NativeMessagingHosts"
        link_file "$DOTFILES_DIR/common/chrome/com.schnee.wallpaper_color.json" "$CONFIG_DIR/google-chrome/NativeMessagingHosts/com.schnee.wallpaper_color.json"
    fi

    # Systemd User Services
    if [[ -d "$DOTFILES_DIR/common/systemd/user" ]]; then
        for f in "$DOTFILES_DIR/common/systemd/user/"*.service "$DOTFILES_DIR/common/systemd/user/"*.timer; do
            [[ -f "$f" ]] && link_file "$f" "$CONFIG_DIR/systemd/user/$(basename "$f")"
        done
    fi

    # User Binaries
    if [[ -d "$DOTFILES_DIR/bin" ]]; then
        mkdir -p "$HOME/.local/bin"
        for b in "$DOTFILES_DIR/bin/"*; do
            if [[ -f "$b" ]]; then
                chmod +x "$b" 2>/dev/null || true
                link_file "$b" "$HOME/.local/bin/$(basename "$b")"
            fi
        done
    fi
}

# ==============================================================================
# 2. SPECIFIC RICE LINKER
# ==============================================================================
install_rice() {
    local rice="$1"
    local rice_dir="$DOTFILES_DIR/rices/$rice"

    if [[ ! -d "$rice_dir" ]]; then
        print_warn "Rice directory not found: $rice_dir"
        return 1
    fi

    print_msg "Activating rice: $rice ($rice_dir)"

    case "$rice" in
        end4)
            # Hyprland configs
            link_file "$rice_dir/hypr/monitors.lua" "$CONFIG_DIR/hypr/monitors.lua"
            link_file "$rice_dir/hypr/hypridle.conf" "$CONFIG_DIR/hypr/hypridle.conf"
            link_file "$rice_dir/hypr/hyprlock.conf" "$CONFIG_DIR/hypr/hyprlock.conf"

            if [[ -f "$rice_dir/hypr/hyprland/keybinds.lua" ]]; then
                link_file "$rice_dir/hypr/hyprland/keybinds.lua" "$CONFIG_DIR/hypr/hyprland/keybinds.lua"
            fi

            for f in "$rice_dir/hypr/custom/"*.lua; do
                [[ -f "$f" ]] && link_file "$f" "$CONFIG_DIR/hypr/custom/$(basename "$f")"
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
            ;;

        iris)
            # Niri config
            if [[ -f "$rice_dir/niri/config.kdl" ]]; then
                link_file "$rice_dir/niri/config.kdl" "$CONFIG_DIR/niri/config.kdl"
            fi
            # iNiR config
            if [[ -f "$rice_dir/inir/config.json" ]]; then
                link_file "$rice_dir/inir/config.json" "$CONFIG_DIR/inir/config.json"
            fi
            ;;

        *)
            # Generic rice layout convention
            print_msg "Linking generic rice files for $rice..."
            for component_dir in "$rice_dir"/*/; do
                if [[ -d "$component_dir" ]]; then
                    local cname="$(basename "$component_dir")"
                    # If component matches a .config dir (e.g. hypr, waybar, niri, dunst, ags)
                    for item in "$component_dir"*; do
                        if [[ -f "$item" ]]; then
                            link_file "$item" "$CONFIG_DIR/$cname/$(basename "$item")"
                        fi
                    done
                fi
            done
            ;;
    esac

    if [[ $DRY_RUN -eq 0 ]]; then
        echo "$rice" > "$CURRENT_RICE_FILE"
    fi
    print_succ "Rice '$rice' linked successfully!"
}

# ==============================================================================
# MAIN EXECUTION
# ==============================================================================
print_msg "Running dotfiles installer..."
install_common
install_rice "$TARGET_RICE"
print_succ "All operations completed successfully!"
