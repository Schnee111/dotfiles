# shellcheck shell=bash
# Backup retention: the installer creates one backup tree per run. Without a
# prune step they accumulate forever (23 directories before this existed).

BACKUP_KEEP_DEFAULT=5

prune_backups() {
    local keep="${1:-$BACKUP_KEEP_DEFAULT}" dirs=()
    mapfile -t dirs < <(ls -1dt "$CONFIG_DIR"/dotfiles_backup_* 2>/dev/null || true)
    (( ${#dirs[@]} > keep )) || return 0

    local d
    for d in "${dirs[@]:keep}"; do
        [[ -d "$d" ]] || continue
        if [[ $DRY_RUN -eq 1 ]]; then
            print_msg "[Dry-Run] Would prune old backup: $d"
        else
            rm -rf "$d"
            print_msg "Pruned old backup: $d"
        fi
    done
}
