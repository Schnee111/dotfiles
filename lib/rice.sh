# shellcheck shell=bash
# Rice dispatcher: prunes foreign links, folds live shell state, then
# calls the per-rice linker in lib/rices/.

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
    local -A seen=()
    # Canonicalise the repo root once (-m: tolerate a symlinked rices/ and a
    # trailing slash): on immutable distros ($HOME under /var/home, symlinked
    # project roots) the literal "$DOTFILES_DIR" never matches a resolved link.
    local rices_root
    rices_root="$(readlink -m "$DOTFILES_DIR/rices" 2>/dev/null || printf '%s/rices' "${DOTFILES_DIR%/}")"
    for root in "$@"; do
        [[ -d "$root" ]] || continue
        while IFS= read -r -d '' link; do
            # A caller may pass a subdir both explicitly and through the
            # hyprland/*/ glob; never handle the same link twice.
            if [[ -n "${seen[$link]:-}" ]]; then
                continue
            fi
            seen[$link]=1
            # Resolve relative targets too: a repo link such as
            # ../../../Projects/dotfiles/rices/<other>/... never matches the
            # absolute prefix below. -m canonicalises even when the target is
            # missing (dangling link), unlike -f.
            target="$(readlink -m "$link" 2>/dev/null || true)"
            [[ -n "$target" ]] || target="$(readlink -f "$link" 2>/dev/null || true)"
            [[ -n "$target" ]] || target="$(readlink "$link" 2>/dev/null || true)"
            [[ "$target" == "$rices_root/"* ]] || continue
            case "$target" in
                "$rices_root/$rice/"*) continue ;;
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

# The shell owns config.json; after an abnormal termination it can be empty or
# truncated. Never copy that over the tracked rice copy.
live_state_is_usable() {
    local f="$1" body
    [[ -s "$f" ]] || return 1
    body="$(<"$f")"
    body="${body//[[:space:]]/}"
    [[ "${body:0:1}" == "{" && "${body: -1}" == "}" ]] || return 1
    if command -v jq >/dev/null 2>&1; then
        jq -e . "$f" >/dev/null 2>&1 || return 1
    fi
    return 0
}

fold_live_state() {
    local rice_dir="$1"
    # end-4 derived shells rewrite their state with an atomic rename, which
    # replaces the installer symlink with a regular file. The live file then
    # holds the newest state while the tracked rice copy goes stale, so a
    # switch would relink the old copy and silently drop UI changes. Fold the
    # live state back into the *outgoing* rice before linking the new one --
    # including a same-rice re-run, where link_file would otherwise replace the
    # live file with the older tracked copy.
    local prev_rice="" live_config="$CONFIG_DIR/illogical-impulse/config.json"
    if [[ -f "$CURRENT_RICE_FILE" ]]; then
    prev_rice="$(tr -d '[:space:]' < "$CURRENT_RICE_FILE")"
    fi
    if [[ -n "$prev_rice" && -f "$live_config" && ! -L "$live_config" ]]; then
    local prev_dir="$DOTFILES_DIR/rices/$prev_rice/illogical-impulse"
    # Only fold into a rice that already tracks this state; otherwise a
    # rice using a different shell (vitreus, caelestia, iris, noctalia, ...)
    # would get an illogical-impulse/config.json it never reads, committed
    # into the repo by accident.
    if [[ -f "$prev_dir/config.json" ]] && ! cmp -s "$live_config" "$prev_dir/config.json" 2>/dev/null; then
    if ! live_state_is_usable "$live_config"; then
        print_warn "Skipped state sync: $live_config is empty or not valid JSON"
    elif [[ $DRY_RUN -eq 1 ]]; then
        print_msg "[Dry-Run] Would sync live shell state -> $prev_dir/config.json"
    else
        cp "$live_config" "$prev_dir/config.json"
        print_warn "Synced live shell state -> $prev_dir/config.json"
    fi
    fi
    fi
}

install_rice() {
    local rice="$1"
    local rice_dir="$DOTFILES_DIR/rices/$rice"

    if [[ ! -d "$rice_dir" ]]; then
        print_warn "Rice directory not found: $rice_dir"
        return 1
    fi

    print_msg "Activating rice: $rice ($rice_dir)"

    fold_live_state "$rice_dir"

    case "$rice" in
        end4) install_rice_end4 "$rice_dir" "$rice" ;;
        iris) install_rice_iris "$rice_dir" "$rice" ;;
        noctalia) install_rice_noctalia "$rice_dir" "$rice" ;;
        caelestia) install_rice_caelestia "$rice_dir" "$rice" ;;
        vitreus) install_rice_vitreus "$rice_dir" "$rice" ;;
        minflair) install_rice_minflair "$rice_dir" "$rice" ;;
        ii-p3drovfx) install_rice_ii_p3drovfx "$rice_dir" "$rice" ;;
        prism-shell) install_rice_prism_shell "$rice_dir" "$rice" ;;
        *) install_rice_generic "$rice_dir" "$rice" ;;
    esac

    # Terminal theme ownership: the live kitty.conf is generated per rice (see
    # generate_kitty_conf), never linked, so a rice's theme generator appending
    # `include` lines cannot write into the tracked base config.
    generate_kitty_conf "$(kitty_theme_source "$rice")"

    if [[ $DRY_RUN -eq 0 && $SET_CURRENT -eq 1 ]]; then
        echo "$rice" >"$CURRENT_RICE_FILE"
    fi
    print_succ "Rice '$rice' linked successfully!"
}
