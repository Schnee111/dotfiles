#!/usr/bin/env bash
# ==============================================================================
# Dotfiles Installer & Symlinker
# ==============================================================================
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
BACKUP_DIR="$HOME/.config/dotfiles_backup_$(date +%Y%m%d_%H%M%S)"
DRY_RUN=0

print_msg() { echo -e "\033[1;34m[INFO]\033[0m $1"; }
print_succ() { echo -e "\033[1;32m[OK]\033[0m $1"; }
print_warn() { echo -e "\033[1;33m[WARN]\033[0m $1"; }

show_help() {
    cat << EOF
Usage: ./install.sh [OPTIONS]

Options:
  -n, --dry-run    Show what would be linked without making changes
  -h, --help       Show this help message

Description:
  Creates symbolic links from this dotfiles repository into ~/.config/
  Existing files will be safely backed up to:
  $BACKUP_DIR
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -n|--dry-run) DRY_RUN=1; shift ;;
        -h|--help) show_help; exit 0 ;;
        *) echo "Unknown option: $1"; show_help; exit 1 ;;
    esac
done

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

print_msg "Installing dotfiles from: $DOTFILES_DIR"

# 1. Hyprland
link_file "$DOTFILES_DIR/hypr/monitors.lua" "$CONFIG_DIR/hypr/monitors.lua"
if [[ -f "$DOTFILES_DIR/hypr/hyprland/keybinds.lua" ]]; then
    link_file "$DOTFILES_DIR/hypr/hyprland/keybinds.lua" "$CONFIG_DIR/hypr/hyprland/keybinds.lua"
fi
for f in "$DOTFILES_DIR/hypr/custom/"*.lua; do
    [[ -f "$f" ]] && link_file "$f" "$CONFIG_DIR/hypr/custom/$(basename "$f")"
done
if [[ -f "$DOTFILES_DIR/hypr/custom/scripts/__restore_video_wallpaper.sh" ]]; then
    link_file "$DOTFILES_DIR/hypr/custom/scripts/__restore_video_wallpaper.sh" "$CONFIG_DIR/hypr/custom/scripts/__restore_video_wallpaper.sh"
fi

# 2. Hypr Scripts
for f in "$DOTFILES_DIR/hypr/scripts/"*.sh; do
    if [[ -f "$f" ]]; then
        chmod +x "$f" 2>/dev/null || true
        link_file "$f" "$CONFIG_DIR/hypr/scripts/$(basename "$f")"
    fi
done

# 3. Rofi
link_file "$DOTFILES_DIR/rofi/colors.rasi" "$CONFIG_DIR/rofi/colors.rasi"
link_file "$DOTFILES_DIR/rofi/launchpad.rasi" "$CONFIG_DIR/rofi/launchpad.rasi"
link_file "$DOTFILES_DIR/rofi/display.rasi" "$CONFIG_DIR/rofi/display.rasi"
link_file "$DOTFILES_DIR/rofi/launcher.sh" "$CONFIG_DIR/rofi/launcher.sh"
chmod +x "$DOTFILES_DIR/rofi/launcher.sh" 2>/dev/null || true

# 4. Terminal & Shell
link_file "$DOTFILES_DIR/kitty/kitty.conf" "$CONFIG_DIR/kitty/kitty.conf"
link_file "$DOTFILES_DIR/fish/config.fish" "$CONFIG_DIR/fish/config.fish"
link_file "$DOTFILES_DIR/starship/starship.toml" "$CONFIG_DIR/starship.toml"

# 5. Audio DSP PipeWire
link_file "$DOTFILES_DIR/pipewire/10-headphone-balance.conf" "$CONFIG_DIR/pipewire/pipewire.conf.d/10-headphone-balance.conf"

# 6. Swappy Screenshot
link_file "$DOTFILES_DIR/swappy/config" "$CONFIG_DIR/swappy/config"

print_succ "Dotfiles installation complete!"
