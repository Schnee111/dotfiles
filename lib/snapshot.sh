# shellcheck shell=bash
# Rollback snapshots.
#
# Before a run mutates anything, the pre-state of every path the run touches is
# recorded once (kind + symlink target, or "real file/dir" for the backup
# tree). If the run fails -- most importantly when the new rice's config fails
# `hyprland --verify-config` after the symlinks already moved -- the snapshot
# puts every path back, so the promise "you stay on the working rice" is true
# instead of aspirational.

SNAPSHOT_ACTIVE=0
SNAPSHOT_FILE=""
SNAPSHOT_KEEP=10
declare -A SNAPSHOT_SEEN=()

prune_snapshots() {
    local keep="${1:-$SNAPSHOT_KEEP}" snaps=()
    mapfile -t snaps < <(ls -1dt "$DOTFILES_STATE_DIR"/rollback-*.tsv 2>/dev/null || true)
    (( ${#snaps[@]} > keep )) || return 0
    local s
    for s in "${snaps[@]:keep}"; do
        rm -f "$s" "$s.manifest"
    done
}

snapshot_begin() {
    SNAPSHOT_ACTIVE=1
    SNAPSHOT_SEEN=()
    if [[ $DRY_RUN -eq 1 ]]; then
        return 0
    fi

    mkdir -p "$DOTFILES_STATE_DIR"
    SNAPSHOT_FILE="$DOTFILES_STATE_DIR/rollback-$(date +%Y%m%d_%H%M%S)-$$.tsv"
    local prev_rice=""
    if [[ -f "$CURRENT_RICE_FILE" ]]; then
        prev_rice="$(tr -d '[:space:]' <"$CURRENT_RICE_FILE")"
    fi
    {
        printf 'meta\tbackup_dir\t%s\n' "$BACKUP_DIR"
        printf 'meta\tcurrent_rice\t%s\n' "$prev_rice"
    } >"$SNAPSHOT_FILE"

    # The manifest is part of the state being replaced: keep a copy so a
    # rollback also restores what `doctor` is supposed to compare against.
    if [[ -f "$MANIFEST_FILE" ]]; then
        cp "$MANIFEST_FILE" "$SNAPSHOT_FILE.manifest"
    fi
    prune_snapshots "$SNAPSHOT_KEEP"
}

snapshot_record() {
    local path="$1" kind data
    [[ $SNAPSHOT_ACTIVE -eq 1 && $DRY_RUN -eq 0 && -n "$SNAPSHOT_FILE" ]] || return 0
    if [[ -n "${SNAPSHOT_SEEN[$path]:-}" ]]; then
        return 0
    fi
    SNAPSHOT_SEEN["$path"]=1

    if [[ -L "$path" ]]; then
        kind="link"
        data="$(readlink "$path")"
    elif [[ -d "$path" ]]; then
        kind="dir"
        data=""
    elif [[ -e "$path" ]]; then
        kind="file"
        data=""
    else
        kind="absent"
        data=""
    fi
    printf '%s\t%s\t%s\n' "$kind" "$path" "$data" >>"$SNAPSHOT_FILE"
}

snapshot_latest() {
    ls -1dt "$DOTFILES_STATE_DIR"/rollback-*.tsv 2>/dev/null | head -n1 || true
}

snapshot_finish() {
    local status="${1:-ok}"
    [[ -n "$SNAPSHOT_FILE" && -f "$SNAPSHOT_FILE" ]] || return 0
    printf 'meta\tstatus\t%s\n' "$status" >>"$SNAPSHOT_FILE"
}

snapshot_restore() {
    local file="${1:-}"
    [[ -n "$file" ]] || file="$(snapshot_latest)"
    if [[ -z "$file" || ! -f "$file" ]]; then
        print_err "No rollback snapshot available"
        return 1
    fi

    local -a kinds=() paths=() datas=()
    local kind path data backup_dir="" prev_rice="" seen_prev=0
    while IFS=$'\t' read -r kind path data; do
        case "$kind" in
            meta)
                case "$path" in
                    backup_dir) backup_dir="$data" ;;
                    current_rice) prev_rice="$data"; seen_prev=1 ;;
                esac
                ;;
            *) kinds+=("$kind"); paths+=("$path"); datas+=("$data") ;;
        esac
    done <"$file"

    local i restored=0
    for (( i=${#paths[@]}-1; i>=0; i-- )); do
        kind="${kinds[$i]}"
        path="${paths[$i]}"
        data="${datas[$i]}"
        case "$kind" in
            link)
                if [[ -d "$path" && ! -L "$path" ]]; then
                    rm -rf "$path"
                fi
                mkdir -p "$(dirname "$path")"
                if ln -sfn "$data" "$path" 2>/dev/null; then
                    restored=$((restored + 1))
                else
                    print_warn "Could not restore link: $path -> $data"
                fi
                ;;
            file | dir)
                local saved="${backup_dir}/${path#"$HOME"/}"
                if [[ -e "$saved" ]]; then
                    rm -rf "$path"
                    mkdir -p "$(dirname "$path")"
                    mv "$saved" "$path"
                    restored=$((restored + 1))
                else
                    print_warn "Backup missing, left as-is: $path"
                fi
                ;;
            absent)
                if [[ -e "$path" || -L "$path" ]]; then
                    rm -rf "$path"
                    restored=$((restored + 1))
                fi
                ;;
        esac
    done

    # Restore the manifest and the active-rice marker last: they describe the
    # state the rest of the restore just rebuilt.
    if [[ -f "$file.manifest" ]]; then
        mkdir -p "$DOTFILES_STATE_DIR"
        cp -f "$file.manifest" "$MANIFEST_FILE"
    fi
    if [[ $seen_prev -eq 1 ]]; then
        if [[ -n "$prev_rice" ]]; then
            printf '%s\n' "$prev_rice" >"$CURRENT_RICE_FILE"
        else
            rm -f "$CURRENT_RICE_FILE"
        fi
    fi

    printf 'meta\trolled_back\t%s\n' "$(date -Iseconds)" >>"$file"
    print_succ "Rolled back ${restored} path(s) from $(basename "$file")"
}
