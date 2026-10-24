# shellcheck shell=bash
# shellcheck disable=SC2034  # URL/REV variables are read by lib/rices/*.sh
# Third-party shell checkouts. The installer used to clone HEAD and `git pull`
# on every run, so upstream changes were fetched and then executed from the
# Hyprland autostart without review. Each shell is now pinned to a commit:
# bump the rev here (and review the diff) to move to a newer upstream.
#
#   * a fresh install checks out exactly the pinned commit;
#   * an existing checkout is never touched, only reported when it differs;
#   * DOTFILES_UPDATE_SHELLS=1 moves existing checkouts to the pinned commit.

VITREUS_URL="https://github.com/natepayn3/Vitreus.git"
VITREUS_REV="${VITREUS_REV:-aff648cbd6405305093d0de4ad5719c711e09800}"
END4PC_URL="https://github.com/Schnee111/end4-pC.git"
END4PC_REV="${END4PC_REV:-d85bd931e36bb3fdf9087ddca88ccc791e5f2b7a}"

# sync_pinned_repo <url> <dest> <rev> <label>
sync_pinned_repo() {
    local url="$1" dest="$2" rev="$3" label="$4" head=""

    if [[ -d "$dest/.git" ]]; then
        head="$(git -C "$dest" rev-parse --verify -q HEAD 2>/dev/null || true)"
        if [[ "$head" == "$rev" ]]; then
            return 0
        fi
        # A checkout with commits is the user's: keep it unless they opt in.
        # One without (a `git init` whose fetch failed earlier) falls through
        # so the next run retries instead of reporting success.
        if [[ -n "$head" && "${DOTFILES_UPDATE_SHELLS:-0}" != "1" ]]; then
            print_warn "$label is at ${head:0:7}, pinned ${rev:0:7}; kept as-is (DOTFILES_UPDATE_SHELLS=1 to move it)"
            return 0
        fi
        # Never rewrite an existing origin, only supply a missing one.
        if ! git -C "$dest" remote get-url origin >/dev/null 2>&1; then
            git -C "$dest" remote add origin "$url" || return 1
        fi
    elif [[ -e "$dest" ]]; then
        print_warn "$label: $dest exists and is not a git checkout, left as-is"
        return 0
    else
        git init -q "$dest" && git -C "$dest" remote add origin "$url" || {
            print_warn "$label: could not initialise $dest"
            return 1
        }
    fi

    print_msg "Fetching $label at ${rev:0:7}..."
    if git -C "$dest" fetch -q --depth 1 origin "$rev" 2>/dev/null &&
        git -C "$dest" checkout -q --detach FETCH_HEAD 2>/dev/null; then
        return 0
    fi
    print_warn "$label: could not check out ${rev:0:7} (network, or local changes in $dest)"
    return 1
}
