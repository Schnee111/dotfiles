# shellcheck shell=bash
# Shared (rice-independent) config linking + generated kitty wrapper.

install_common() {
    print_msg "Installing common configurations..."

    # Terminal & Shell
    # kitty.conf is generated per rice by generate_kitty_conf (install_rice):
    # a rice's theme generator appends includes to the live file, so that file
    # must not be a symlink into the repo.
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
            if [[ -e "$f" || -L "$f" ]]; then
                link_file "$f" "$CONFIG_DIR/fastfetch/logos/$(basename "$f")"
            fi
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
            if [[ -f "$f" ]]; then
                link_file "$f" "$CONFIG_DIR/systemd/user/$(basename "$f")"
            fi
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

# Which rice ships a terminal theme, and where its generator writes it.
# Rices without a generator fall back to the tracked default palette, so the
# include always resolves to something readable.
kitty_theme_source() {
    case "$1" in
        end4 | ii-p3drovfx) echo "$HOME/.local/state/quickshell/user/generated/terminal/kitty-theme.conf" ;;
        iris) echo "$CONFIG_DIR/kitty/theme.conf" ;;
        *) echo "$DOTFILES_DIR/common/kitty/default-theme.conf" ;;
    esac
}

# The live ~/.config/kitty/kitty.conf must NOT be a symlink into the repo:
# per-rice generators (inir's generate_terminal_configs.py, end4/ii's
# applycolor.sh) append `include` lines to it at runtime, which would write
# straight into the tracked file and dirty the tree on every iris session.
# Generate a thin wrapper instead and point the stable `rice-theme.conf`
# indirection at whatever theme the active rice produces. The wrapper is
# rewritten on every switch, so a foreign rice's appended include disappears
# by itself.
generate_kitty_conf() {
    local theme_src="${1:-}"
    local live="$CONFIG_DIR/kitty/kitty.conf"
    local theme_link="$CONFIG_DIR/kitty/rice-theme.conf"

    if [[ $DRY_RUN -eq 1 ]]; then
        print_msg "[Dry-Run] Would generate kitty wrapper: $live"
        if [[ -n "$theme_src" && -f "$theme_src" ]]; then
            print_msg "[Dry-Run] Would point rice-theme.conf -> $theme_src"
        elif [[ -n "$theme_src" ]]; then
            print_msg "[Dry-Run] Would point rice-theme.conf -> $theme_src (not generated yet; include stays dangling until the rice's generator writes it)"
        else
            print_msg "[Dry-Run] Would write an empty rice-theme.conf (no theme source)"
        fi
        return 0
    fi

    mkdir -p "$CONFIG_DIR/kitty"
    {
        echo "# Generated by dotfiles install.sh -- edit common/kitty/kitty.conf instead."
        echo "# Rice theme generators append includes here; this file is not tracked."
        echo "include $DOTFILES_DIR/common/kitty/kitty.conf"
    } >"$live.tmp" && mv -f "$live.tmp" "$live"

    if [[ -n "$theme_src" ]]; then
        # Link even when the generator has not written the theme yet: a dangling
        # include is harmless (kitty logs "Could not find included config file"
        # and ignores it), and the very same symlink starts working the moment
        # the rice's generator produces the file. Testing -f here would leave a
        # detached empty regular file that never picks the theme up.
        ln -sfn "$theme_src" "$theme_link.tmp" && mv -T -f "$theme_link.tmp" "$theme_link"
    else
        # Never redirect into $theme_link: it can be a symlink to a tracked file,
        # and `> $link` would open that target with O_TRUNC and wipe it (this
        # reset common/kitty/default-theme.conf to zero bytes).
        : >"$theme_link.tmp" && mv -T -f "$theme_link.tmp" "$theme_link"
    fi

    print_succ "Generated kitty wrapper (theme: ${theme_src:-none})"
}
