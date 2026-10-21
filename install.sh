#!/usr/bin/env bash
# ==============================================================================
# Dotfiles Installer & Multi-Rice Manager
#
# Entry point only: argument parsing, library loading, run order.
#   lib/core.sh     logging, atomic linking, backup layout, manifest
#   lib/snapshot.sh rollback snapshots (restore on failure)
#   lib/backup.sh   backup retention
#   lib/common.sh   rice-independent configs + generated kitty wrapper
#   lib/rice.sh     dispatcher, foreign-link pruning, live-state folding
#   lib/rices/*.sh  one linker per rice
# ==============================================================================
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
BACKUP_DIR="$CONFIG_DIR/dotfiles_backup_$(date +%Y%m%d_%H%M%S)"
CURRENT_RICE_FILE="$CONFIG_DIR/.current_rice"
DRY_RUN=0
TARGET_RICE=""
SET_CURRENT=1
ACTION="install"

show_help() {
    cat <<EOF
Usage: ./install.sh [OPTIONS] [RICE_NAME]

Options:
  -n, --dry-run        Show what would be linked without making changes
  -r, --rice <NAME>    Specify rice to link (default: active rice or 'end4')
      --no-set-current Do not write ~/.config/.current_rice (rice-switch does it
                       itself once the new config passed verification)
      --rollback       Restore the paths recorded by the last run and exit
  -h, --help           Show this help message

Available Rices:
$(for d in "$DOTFILES_DIR"/rices/*/; do [[ -d "$d" ]] && echo "  - $(basename "$d")"; done)

Description:
  Creates symbolic links for common configs and the active desktop rice.
  Existing files are moved (never deleted) into a per-run backup tree:
  $BACKUP_DIR
  Every touched path is recorded first, so a failed run rolls itself back.
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -n | --dry-run) DRY_RUN=1; shift ;;
        -r | --rice)
            TARGET_RICE="$2"
            shift 2
            ;;
        --no-set-current) SET_CURRENT=0; shift ;;
        --rollback) ACTION="rollback"; shift ;;
        -h | --help)
            show_help
            exit 0
            ;;
        *)
            if [[ -z "$TARGET_RICE" && -d "$DOTFILES_DIR/rices/$1" ]]; then
                TARGET_RICE="$1"
                shift
            else
                echo "Unknown option or invalid rice: $1"
                show_help
                exit 1
            fi
            ;;
    esac
done

# shellcheck source=lib/core.sh
source "$DOTFILES_DIR/lib/core.sh"
# shellcheck source=lib/snapshot.sh
source "$DOTFILES_DIR/lib/snapshot.sh"
# shellcheck source=lib/backup.sh
source "$DOTFILES_DIR/lib/backup.sh"
# shellcheck source=lib/common.sh
source "$DOTFILES_DIR/lib/common.sh"
# shellcheck source=lib/rice.sh
source "$DOTFILES_DIR/lib/rice.sh"
for _rice_lib in "$DOTFILES_DIR"/lib/rices/*.sh; do
    # shellcheck disable=SC1090
    source "$_rice_lib"
done
unset _rice_lib

if [[ "$ACTION" == "rollback" ]]; then
    snapshot_restore "$(snapshot_latest)"
    exit 0
fi

if [[ -z "$TARGET_RICE" ]]; then
    if [[ -f "$CURRENT_RICE_FILE" ]]; then
        TARGET_RICE="$(tr -d '[:space:]' <"$CURRENT_RICE_FILE")"
    fi
    TARGET_RICE="${TARGET_RICE:-end4}"
fi

install_on_error() {
    local status=$?
    trap - ERR
    set +e
    print_err "Installer failed; rolling back the paths this run touched."
    if [[ -n "$SNAPSHOT_FILE" && -f "$SNAPSHOT_FILE" ]]; then
        snapshot_restore "$SNAPSHOT_FILE"
    fi
    exit "$status"
}

snapshot_begin
[[ $DRY_RUN -eq 0 ]] && MANIFEST_ACTIVE=1
trap install_on_error ERR

print_msg "Running dotfiles installer..."
install_common
install_rice "$TARGET_RICE"

if [[ $DRY_RUN -eq 0 ]]; then
    manifest_commit
    prune_backups "$BACKUP_KEEP_DEFAULT"
    snapshot_finish ok
fi
trap - ERR
print_succ "All operations completed successfully!"
