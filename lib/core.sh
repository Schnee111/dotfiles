# shellcheck shell=bash
# Core helpers shared by every lib/: logging, atomic linking, backup layout and
# the managed-file manifest.
#
# Invariants this file owns:
#   * a dest is only ever replaced by rename(2) (ln -sf + mv -T), so a reader
#     never sees a half-written config;
#   * a real file is never deleted, only moved into the backup tree;
#   * every dest this run owns ends up in the manifest, which is what
#     `dotfiles doctor` verifies later.

DOTFILES_STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles"
MANIFEST_FILE="$DOTFILES_STATE_DIR/manifest.tsv"
MANIFEST_ACTIVE=0
declare -A MANIFEST_MAP=()

print_msg() { echo -e "\033[1;34m[INFO]\033[0m $1"; }
print_succ() { echo -e "\033[1;32m[OK]\033[0m $1"; }
print_warn() { echo -e "\033[1;33m[WARN]\033[0m $1"; }
print_err() { echo -e "\033[1;31m[FAIL]\033[0m $1" >&2; }

# Backups mirror the absolute path of what they replace. The old flat layout
# ($BACKUP_DIR/<basename>) silently clobbered two files with the same name from
# different directories, which also made rollback impossible.
backup_target() {
    local path="$1" rel
    case "$path" in
        "$HOME"/*) rel="${path#"$HOME"/}" ;;
        /*) rel="external${path}" ;;
        *) rel="$path" ;;
    esac
    printf '%s/%s' "${BACKUP_DIR:-$HOME/.config/dotfiles_backup}" "$rel"
}

backup_existing() {
    local path="$1" target
    target="$(backup_target "$path")"
    if [[ $DRY_RUN -eq 1 ]]; then
        print_warn "[Dry-Run] Would back up: $path -> $target"
        return 0
    fi
    mkdir -p "$(dirname "$target")"
    mv "$path" "$target"
    print_warn "Backed up existing: $path -> $target"
}

link_file() {
    local src="$1"
    local dest="$2"
    local dest_dir
    dest_dir="$(dirname "$dest")"

    snapshot_record "$dest"

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
            manifest_record "$dest" "$src"
            return 0
        fi

        # If it's already a symlink, replace atomically without a deletion window
        if [[ -L "$dest" ]]; then
            if [[ $DRY_RUN -eq 1 ]]; then
                print_succ "[Dry-Run] Would atomically relink: $dest -> $src"
                return 0
            fi
            ln -sf "$src" "$dest.tmp" && mv -T -f "$dest.tmp" "$dest"
            print_succ "Relinked: $dest -> $src"
            manifest_record "$dest" "$src"
            return 0
        fi

        backup_existing "$dest"
    fi

    if [[ $DRY_RUN -eq 1 ]]; then
        print_succ "[Dry-Run] Would link: $dest -> $src"
    else
        ln -sf "$src" "$dest"
        print_succ "Linked: $dest -> $src"
        manifest_record "$dest" "$src"
    fi
}

# Remove a path this installer owns. Symlinks are unlinked (nothing to keep);
# real files and directories are moved to the backup tree so that a rollback
# can put them back. Wording matches the pre-refactor dry-run output on
# purpose: it makes a before/after dry-run diff readable.
remove_path() {
    local path="$1" label="stale"
    [[ -e "$path" || -L "$path" ]] || return 0
    [[ -d "$path" && ! -L "$path" ]] && label="stale dir"

    snapshot_record "$path"

    if [[ $DRY_RUN -eq 1 ]]; then
        print_msg "[Dry-Run] Would remove $label: $path"
        return 0
    fi

    if [[ -L "$path" ]]; then
        rm -f "$path"
    else
        backup_existing "$path"
    fi
    print_warn "Removed $label: $path"
    manifest_drop "$path"
}

# Write a small generated stub (e.g. a shell's hypr-vars.lua on first run) while
# keeping it inside the rollback snapshot, so a rollback removes it again.
write_stub() {
    local path="$1"
    shift
    snapshot_record "$path"
    if [[ $DRY_RUN -eq 1 ]]; then
        print_msg "[Dry-Run] Would create stub: $path"
        return 0
    fi
    mkdir -p "$(dirname "$path")"
    printf '%s\n' "${*:-}" >"$path"
    print_msg "Created stub: $path"
}

manifest_record() {
    [[ $MANIFEST_ACTIVE -eq 1 ]] || return 0
    MANIFEST_MAP["$1"]="$2"
}

manifest_drop() {
    [[ $MANIFEST_ACTIVE -eq 1 ]] || return 0
    unset 'MANIFEST_MAP[$1]'
}

manifest_commit() {
    [[ $MANIFEST_ACTIVE -eq 1 ]] || return 0
    mkdir -p "$DOTFILES_STATE_DIR"
    local tmp="$MANIFEST_FILE.tmp.$$" dest
    : >"$tmp"
    while IFS= read -r dest; do
        [[ -n "$dest" ]] || continue
        printf '%s\t%s\n' "$dest" "${MANIFEST_MAP[$dest]}" >>"$tmp"
    done < <(printf '%s\n' "${!MANIFEST_MAP[@]}" | sort)
    mv -f "$tmp" "$MANIFEST_FILE"
    print_msg "Manifest updated: $MANIFEST_FILE (${#MANIFEST_MAP[@]} managed paths)"
}
