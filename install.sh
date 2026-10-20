#!/usr/bin/env bash
# ==============================================================================
# Dotfiles Installer & Multi-Rice Manager
# ==============================================================================
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
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

        # If it's already a symlink, replace atomically without a deletion window
        if [[ -L "$dest" ]]; then
            if [[ $DRY_RUN -eq 1 ]]; then
                print_succ "[Dry-Run] Would atomically relink: $dest -> $src"
                return 0
            else
                ln -sf "$src" "$dest.tmp" && mv -T -f "$dest.tmp" "$dest"
                print_succ "Relinked: $dest -> $src"
                return 0
            fi
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

# Remove symlinks under the given directories that point into a *different*
# rice's dotfiles. A switch only relinks and prunes top-level *.lua modules, so
# per-file links that exist only in the previous rice (custom/input.lua, extra
# hyprland/scripts entries, shellOverrides/repo-defaults.lua) survive and load
# foreign values. Real files are left alone on purpose: shellOverrides/main.lua
# is written by the shell itself.
prune_foreign_links() {
    local rice="$1"
    shift
    local root link target
    for root in "$@"; do
        [[ -d "$root" ]] || continue
        while IFS= read -r -d '' link; do
            target="$(readlink "$link" 2>/dev/null || true)"
            [[ "$target" == "$DOTFILES_DIR/rices/"* ]] || continue
            case "$target" in
                "$DOTFILES_DIR/rices/$rice/"*) continue ;;
            esac
            if [[ $DRY_RUN -eq 1 ]]; then
                print_msg "[Dry-Run] Would remove foreign link: $link -> $target"
            else
                rm -f "$link"
                print_warn "Removed foreign link: $link (was $target)"
            fi
        done < <(find "$root" -maxdepth 1 -type l -print0 2>/dev/null)
    done
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

    # macOS UI Feedback Sounds (toggle scripts use play_sound.sh on these)
    if [[ -d "$DOTFILES_DIR/common/sounds/macos" ]]; then
        link_file "$DOTFILES_DIR/common/sounds/macos" "$HOME/.local/share/sounds/macos"
    fi
    if [[ -f "$DOTFILES_DIR/common/sounds/play_sound.sh" ]]; then
        link_file "$DOTFILES_DIR/common/sounds/play_sound.sh" "$HOME/.local/bin/play_sound.sh"
    fi

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
        if [[ $DRY_RUN -eq 1 ]]; then
            print_msg "[Dry-Run] Would reload user systemd daemon"
        else
            systemctl --user daemon-reload 2>/dev/null || true
        fi
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

    # end-4 derived shells rewrite their state with an atomic rename, which
    # replaces the installer symlink with a regular file. The live file then
    # holds the newest state while the tracked rice copy goes stale, so a
    # switch would relink the old copy and silently drop UI changes. Fold the
    # live state back into the *outgoing* rice before linking the new one.
    local prev_rice="" live_config="$CONFIG_DIR/illogical-impulse/config.json"
    if [[ -f "$CURRENT_RICE_FILE" ]]; then
        prev_rice="$(tr -d '[:space:]' < "$CURRENT_RICE_FILE")"
    fi
    if [[ -n "$prev_rice" && "$prev_rice" != "$rice" && -f "$live_config" && ! -L "$live_config" ]]; then
        local prev_dir="$DOTFILES_DIR/rices/$prev_rice/illogical-impulse"
        if ! cmp -s "$live_config" "$prev_dir/config.json" 2>/dev/null; then
            if [[ $DRY_RUN -eq 1 ]]; then
                print_msg "[Dry-Run] Would sync live shell state -> $prev_dir/config.json"
            else
                mkdir -p "$prev_dir"
                cp "$live_config" "$prev_dir/config.json"
                print_warn "Synced live shell state -> $prev_dir/config.json"
            fi
        fi
    fi

    case "$rice" in
        end4)
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
                        rm -f "$stale"
                    fi
                fi
            done

            # Hyprland Lua entry-point
            if [[ -f "$rice_dir/hypr/hyprland.lua" ]]; then
                link_file "$rice_dir/hypr/hyprland.lua" "$CONFIG_DIR/hypr/hyprland.lua"
            fi

            # Hyprland modules (keybinds + upstream defaults tracked per-rice)
            for f in "$rice_dir/hypr/hyprland/"*.lua; do
                [[ -f "$f" ]] && link_file "$f" "$CONFIG_DIR/hypr/hyprland/$(basename "$f")"
            done

            # Hyprland module subdirs (lib, services, scripts)
            for d in "$rice_dir/hypr/hyprland/"*/; do
                if [[ -d "$d" ]]; then
                    local subname="$(basename "$d")"
                    mkdir -p "$CONFIG_DIR/hypr/hyprland/$subname"
                    for sf in "$d"*; do
                        [[ -f "$sf" ]] && link_file "$sf" "$CONFIG_DIR/hypr/hyprland/$subname/$(basename "$sf")"
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
                        rm -f "$sf"
                        print_warn "Removed stale: $sf"
                    fi
                fi
            done

            for f in "$rice_dir/hypr/custom/"*.lua "$rice_dir/hypr/custom/"*.json; do
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

            # Drop per-file links left by the previous rice. The switch relinks
            # what this rice ships but never deletes what it doesn't (e.g.
            # custom/input.lua, hyprland/scripts/zoom.sh,
            # shellOverrides/repo-defaults.lua from ii-p3drovfx), and a stale
            # link there wins over this rice's defaults.
            prune_foreign_links "$rice" \
                "$CONFIG_DIR/hypr" \
                "$CONFIG_DIR/hypr/custom" \
                "$CONFIG_DIR/hypr/scripts" \
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

        noctalia)
            # Umbriel compositor config
            if [[ -f "$rice_dir/umbriel/config.toml" ]]; then
                link_file "$rice_dir/umbriel/config.toml" "$CONFIG_DIR/umbriel/config.toml"
            fi
            # Noctalia desktop shell config
            if [[ -f "$rice_dir/noctalia/config.toml" ]]; then
                link_file "$rice_dir/noctalia/config.toml" "$CONFIG_DIR/noctalia/config.toml"
            fi
            ;;

        caelestia)
            # Caelestia Hyprland config
            # Entry-point requires ~/.config/caelestia/hypr-vars.lua on first
            # run (package.path points there); pre-create so --verify-config
            # does not fail on a fresh switch.
            mkdir -p "$CONFIG_DIR/caelestia"
            if [[ ! -f "$CONFIG_DIR/caelestia/hypr-vars.lua" ]]; then
                if [[ $DRY_RUN -eq 1 ]]; then
                    print_msg "[Dry-Run] Would create stub: $CONFIG_DIR/caelestia/hypr-vars.lua"
                else
                    echo 'return {}' > "$CONFIG_DIR/caelestia/hypr-vars.lua"
                fi
            fi
            # Drop end4-only and vitreus-only leftovers (mirror of the end4 branch cleanup):
            # shared entry files end4 owns, plus end4-specific modules and
            # scripts the caelestia entry-point never requires.
            for stale in "$CONFIG_DIR/hypr/monitors.lua" \
                         "$CONFIG_DIR/hypr/hypridle.conf" \
                         "$CONFIG_DIR/hypr/hyprlock.conf" \
                         "$CONFIG_DIR/hypr/hyprland/colors.lua" \
                         "$CONFIG_DIR/hypr/hyprland/variables.lua" \
                         "$CONFIG_DIR/hypr/hypr_vitreus.lua" \
                         "$CONFIG_DIR/hypr/colors.conf" \
                         "$CONFIG_DIR/hypr/colors.lua"; do
                if [[ -L "$stale" || -e "$stale" ]]; then
                    if [[ $DRY_RUN -eq 1 ]]; then
                        print_msg "[Dry-Run] Would remove stale: $stale"
                    else
                        rm -f "$stale"
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
                        rm -rf "$stale_dir"
                    fi
                fi
            done
            if [[ -d "$rice_dir/hypr" ]]; then
                for f in "$rice_dir/hypr/"*.lua; do
                    [[ -f "$f" ]] && link_file "$f" "$CONFIG_DIR/hypr/$(basename "$f")"
                done
                for d in "$rice_dir/hypr"/*/; do
                    if [[ -d "$d" ]]; then
                        local subname="$(basename "$d")"
                        mkdir -p "$CONFIG_DIR/hypr/$subname"
                        for sf in "$d"*; do
                            [[ -f "$sf" ]] && link_file "$sf" "$CONFIG_DIR/hypr/$subname/$(basename "$sf")"
                        done
                    fi
                done
            fi
            # Drop stale hyprland/*.lua modules left by another rice
            for sf in "$CONFIG_DIR/hypr/hyprland/"*.lua; do
                [[ -L "$sf" || -e "$sf" ]] || continue
                if [[ ! -e "$rice_dir/hypr/hyprland/$(basename "$sf")" ]]; then
                    if [[ $DRY_RUN -eq 1 ]]; then
                        print_msg "[Dry-Run] Would remove stale: $sf"
                    else
                        rm -f "$sf"
                        print_warn "Removed stale: $sf"
                    fi
                fi
            done
            # Caelestia manages monitors inline in hyprland.lua and runs no
            # monitor watcher: stop the end4 watcher so it cannot rewrite
            # monitors.lua or respawn qs -c end4-pC mid-session.
            # Also stop the vitreus brightness mirror, which is vitreus-only.
            if [[ $DRY_RUN -eq 1 ]]; then
                print_msg "[Dry-Run] Would stop hyprland-monitor-watcher.service vitreus-brightness-mirror.service"
            else
                systemctl --user stop hyprland-monitor-watcher.service vitreus-brightness-mirror.service 2>/dev/null || true
            fi
            ;;

        vitreus)
            # Vitreus Hyprland config + pleamar shell
            # Entry-point requires ~/.config/vitreus/hypr-vars.lua on first
            # run (package.path points there); pre-create so --verify-config
            # does not fail on a fresh switch.
            mkdir -p "$CONFIG_DIR/vitreus"
            if [[ ! -f "$CONFIG_DIR/vitreus/hypr-vars.lua" ]]; then
                if [[ $DRY_RUN -eq 1 ]]; then
                    print_msg "[Dry-Run] Would create stub: $CONFIG_DIR/vitreus/hypr-vars.lua"
                else
                    echo 'return {}' > "$CONFIG_DIR/vitreus/hypr-vars.lua"
                fi
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
                        rm -f "$stale"
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
                        rm -rf "$stale_dir"
                    fi
                fi
            done
            if [[ -d "$rice_dir/hypr" ]]; then
                for f in "$rice_dir/hypr/"*.lua; do
                    [[ -f "$f" ]] && link_file "$f" "$CONFIG_DIR/hypr/$(basename "$f")"
                done
                for d in "$rice_dir/hypr"/*/; do
                    if [[ -d "$d" ]]; then
                        local subname="$(basename "$d")"
                        mkdir -p "$CONFIG_DIR/hypr/$subname"
                        for sf in "$d"*; do
                            [[ -f "$sf" ]] && link_file "$sf" "$CONFIG_DIR/hypr/$subname/$(basename "$sf")"
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
                        rm -f "$sf"
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
            ;;

        minflair)
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
                        rm -f "$stale"
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
                        rm -rf "$stale_dir"
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
                    [[ -f "$sf" ]] && link_file "$sf" "$CONFIG_DIR/hypr/hyprland/$(basename "$sf")"
                done
            fi

            # Link scripts in scripts/
            if [[ -d "$rice_dir/hypr/scripts" ]]; then
                mkdir -p "$CONFIG_DIR/hypr/scripts"
                for sf in "$rice_dir/hypr/scripts/"*.sh; do
                    [[ -f "$sf" ]] && link_file "$sf" "$CONFIG_DIR/hypr/scripts/$(basename "$sf")"
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
                        rm -f "$sf"
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
            ;;

        ii-p3drovfx)
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
                        rm -f "$stale"
                    fi
                fi
            done
            for stale_dir in "$CONFIG_DIR/hypr/scheme" \
                             "$CONFIG_DIR/hypr/utils"; do
                if [[ -e "$stale_dir" ]]; then
                    if [[ $DRY_RUN -eq 1 ]]; then
                        print_msg "[Dry-Run] Would remove stale dir: $stale_dir"
                    else
                        rm -rf "$stale_dir"
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
                    local subname="$(basename "$d")"
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
                        rm -f "$sf"
                        print_warn "Removed stale: $sf"
                    fi
                fi
            done

            # Custom user configs (keybinds, rules, session layout)
            for f in "$rice_dir/hypr/custom/"*.lua "$rice_dir/hypr/custom/"*.json; do
                [[ -f "$f" ]] && link_file "$f" "$CONFIG_DIR/hypr/custom/$(basename "$f")"
            done

            # Drop per-file links left by the previous rice (see end4 branch).
            prune_foreign_links "$rice" \
                "$CONFIG_DIR/hypr" \
                "$CONFIG_DIR/hypr/custom" \
                "$CONFIG_DIR/hypr/scripts" \
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
            ;;

        prism-shell)
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
                        rm -f "$stale"
                    fi
                fi
            done
            for stale_dir in "$CONFIG_DIR/hypr/scheme" \
                             "$CONFIG_DIR/hypr/utils"; do
                if [[ -e "$stale_dir" ]]; then
                    if [[ $DRY_RUN -eq 1 ]]; then
                        print_msg "[Dry-Run] Would remove stale dir: $stale_dir"
                    else
                        rm -rf "$stale_dir"
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
                    local subname="$(basename "$d")"
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
                        rm -f "$sf"
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
