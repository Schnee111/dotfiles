#!/usr/bin/env bash
# Rollback contract: after a failed run, every path the run touched is back to
# its exact pre-run state (real file restored from the backup tree, relinked
# symlink restored, newly created path removed, active-rice marker untouched).
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

export HOME="$TMP/home"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_STATE_HOME="$HOME/.local/state"
mkdir -p "$XDG_CONFIG_HOME"
CONFIG_DIR="$XDG_CONFIG_HOME"
# shellcheck disable=SC2034  # consumed by the sourced lib/
BACKUP_DIR="$CONFIG_DIR/dotfiles_backup_test"
CURRENT_RICE_FILE="$CONFIG_DIR/.current_rice"
# shellcheck disable=SC2034  # consumed by the sourced lib/
DRY_RUN=0

# shellcheck source=../lib/core.sh
source "$REPO/lib/core.sh"
# shellcheck source=../lib/snapshot.sh
source "$REPO/lib/snapshot.sh"
# shellcheck source=../lib/backup.sh
source "$REPO/lib/backup.sh"

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

# --- fixture: one real file, one symlink, one absent path, active rice ---------
printf 'original\n' >"$CONFIG_DIR/real.conf"
ln -s /nonexistent/original-target "$CONFIG_DIR/link.conf"
printf 'end4\n' >"$CURRENT_RICE_FILE"
mkdir -p "$DOTFILES_STATE_DIR"
printf '%s\t%s\n' "$CONFIG_DIR/real.conf" "$REPO/common/kitty/kitty.conf" >"$MANIFEST_FILE"

snapshot_begin
# shellcheck disable=SC2034  # consumed by the sourced lib/
MANIFEST_ACTIVE=1
link_file "$REPO/common/kitty/kitty.conf" "$CONFIG_DIR/real.conf"
link_file "$REPO/common/fish/config.fish" "$CONFIG_DIR/link.conf"
link_file "$REPO/common/starship/starship.toml" "$CONFIG_DIR/created.conf"
manifest_commit

[[ -L "$CONFIG_DIR/real.conf" ]] || fail "real.conf should have become a symlink"
[[ "$(readlink "$CONFIG_DIR/link.conf")" == "$REPO/common/fish/config.fish" ]] || fail "link.conf was not relinked"
[[ -L "$CONFIG_DIR/created.conf" ]] || fail "created.conf was not linked"
[[ "$(wc -l <"$MANIFEST_FILE")" -eq 3 ]] || fail "manifest should list 3 paths, got $(wc -l <"$MANIFEST_FILE")"
echo "ok: run applied (3 links, manifest written)"

# --- rollback -----------------------------------------------------------------
snapshot_restore "$SNAPSHOT_FILE"

[[ -f "$CONFIG_DIR/real.conf" && ! -L "$CONFIG_DIR/real.conf" ]] || fail "real.conf is not a real file again"
[[ "$(cat "$CONFIG_DIR/real.conf")" == "original" ]] || fail "real.conf content was not restored"
[[ -L "$CONFIG_DIR/link.conf" ]] || fail "link.conf is no longer a symlink"
[[ "$(readlink "$CONFIG_DIR/link.conf")" == "/nonexistent/original-target" ]] || fail "link.conf target was not restored"
[[ ! -e "$CONFIG_DIR/created.conf" && ! -L "$CONFIG_DIR/created.conf" ]] || fail "created.conf should be gone"
[[ "$(tr -d '[:space:]' <"$CURRENT_RICE_FILE")" == "end4" ]] || fail "active-rice marker changed"
[[ "$(wc -l <"$MANIFEST_FILE")" -eq 1 ]] || fail "manifest was not restored"
echo "ok: rollback restored file, symlink, removed created path, kept marker"

# --- backup retention ---------------------------------------------------------
for i in 1 2 3 4 5 6 7; do mkdir -p "$CONFIG_DIR/dotfiles_backup_2026010${i}_000000"; done
prune_backups 5
kept="$(find "$CONFIG_DIR" -maxdepth 1 -type d -name 'dotfiles_backup_*' | wc -l)"
[[ "$kept" -eq 5 ]] || fail "expected 5 backup trees after prune, found $kept"
echo "ok: backup retention kept 5 of 8"

echo "PASS: rollback + retention"