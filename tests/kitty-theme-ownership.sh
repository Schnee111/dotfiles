#!/usr/bin/env bash
# Regression tests for the kitty theme ownership model (issue #20, PR #21).
#
# The live ~/.config/kitty/kitty.conf is a generated wrapper, and the per-rice
# theme reaches it through the `rice-theme.conf` indirection. These are the
# invariants that make that safe; every one of them has a failure case from a
# real review (see PR #21 review) behind it.
set -uo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOTFILES_DIR="$REPO_DIR"
DRY_RUN=0
CONFIG_DIR=""
print_msg() { printf '[INFO] %s\n' "$*"; }
print_succ() { printf '[OK] %s\n' "$*"; }
print_warn() { printf '[WARN] %s\n' "$*"; }

# Pull the two functions out of install.sh instead of running the installer: a
# real run also clones shells, folds live state and stops services.
eval "$(awk '/^kitty_theme_source\(\)/{f=1} /^# 2\. SPECIFIC RICE LINKER/{f=0} f' "$REPO_DIR/install.sh")"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

fail=0
pass() { printf 'PASS  %s\n' "$1"; }
fail() {
    printf 'FAIL  %s\n' "$1"
    fail=1
}
expect() { # name, condition...
    local name="$1"
    shift
    if "$@"; then pass "$name"; else fail "$name"; fi
}

# --- 1. the wrapper is a generated file, never a symlink into the repo -------
CONFIG_DIR="$TMP/wrapper"
mkdir -p "$CONFIG_DIR/kitty"
generate_kitty_conf "$DOTFILES_DIR/common/kitty/default-theme.conf" >/dev/null
expect "wrapper is a regular file" test ! -L "$CONFIG_DIR/kitty/kitty.conf"
expect "wrapper includes the tracked base" \
    grep -qx "include $DOTFILES_DIR/common/kitty/kitty.conf" "$CONFIG_DIR/kitty/kitty.conf"

# --- 2. rices without a generator get the tracked fallback palette -----------
CONFIG_DIR="$TMP/fallback"
generate_kitty_conf "$(kitty_theme_source vitreus)" >/dev/null
expect "fallback palette is linked" test -L "$CONFIG_DIR/kitty/rice-theme.conf"
expect "fallback palette resolves" test -f "$CONFIG_DIR/kitty/rice-theme.conf"

# --- 3. a theme that does not exist yet must still be linked (PR #21 review) -
CONFIG_DIR="$TMP/pending"
mkdir -p "$CONFIG_DIR/kitty" "$TMP/pending-theme"
pending="$TMP/pending-theme/kitty-theme.conf"
generate_kitty_conf "$pending" >/dev/null
expect "pending theme linked while dangling" test -L "$CONFIG_DIR/kitty/rice-theme.conf"
printf 'background #131C1B\n' >"$pending"
expect "pending theme picked up once generated" \
    grep -qx 'background #131C1B' "$CONFIG_DIR/kitty/rice-theme.conf"

# --- 4. migrating an old symlinked install must not write through the link --
CONFIG_DIR="$TMP/migrate"
mkdir -p "$CONFIG_DIR/kitty"
tracked="$TMP/migrate/tracked.conf"
printf '# original tracked content\n' >"$tracked"
ln -s "$tracked" "$CONFIG_DIR/kitty/kitty.conf"
generate_kitty_conf "$(kitty_theme_source iris)" >/dev/null
expect "old symlink replaced by a generated file" test ! -L "$CONFIG_DIR/kitty/kitty.conf"
expect "old symlink target untouched" grep -qx '# original tracked content' "$tracked"

# --- 5. an empty theme source must never truncate through the link ----------
# The merged first version used `: >"$theme_link"`, which followed a symlink to
# the tracked palette and zeroed it (review finding).
CONFIG_DIR="$TMP/truncate"
mkdir -p "$CONFIG_DIR/kitty"
victim="$TMP/truncate/tracked-default-theme.conf"
printf 'background #131C1B\nforeground #D1DBCB\n' >"$victim"
ln -s "$victim" "$CONFIG_DIR/kitty/rice-theme.conf"
generate_kitty_conf "" >/dev/null
expect "tracked palette not truncated" test -s "$victim"
expect "link became an empty regular file" test ! -L "$CONFIG_DIR/kitty/rice-theme.conf"

# --- 6. a rice generator appending at EOF cannot reach the tracked base -----
CONFIG_DIR="$TMP/append"
mkdir -p "$CONFIG_DIR/kitty"
printf 'background #131C1B\n' >"$CONFIG_DIR/kitty/theme.conf"
generate_kitty_conf "$(kitty_theme_source iris)" >/dev/null
base_before="$(md5sum "$DOTFILES_DIR/common/kitty/kitty.conf" | cut -d' ' -f1)"
printf 'include current-theme.conf\n' >>"$CONFIG_DIR/kitty/kitty.conf" # what iNiR does
base_after="$(md5sum "$DOTFILES_DIR/common/kitty/kitty.conf" | cut -d' ' -f1)"
expect "append landed in the wrapper" grep -q current-theme "$CONFIG_DIR/kitty/kitty.conf"
expect "tracked base byte-identical" test "$base_before" = "$base_after"
generate_kitty_conf "$(kitty_theme_source vitreus)" >/dev/null
expect "foreign include gone after a rice switch" \
    bash -c "! grep -q current-theme '$CONFIG_DIR/kitty/kitty.conf'"

# --- 7. dry-run must describe what the real run does ------------------------
CONFIG_DIR="$TMP/dryrun"
DRY_RUN=1
out="$(generate_kitty_conf "$TMP/dryrun/not-there-yet.conf")"
DRY_RUN=0
expect "dry-run mentions the pending target" \
    grep -q "not generated yet" <<<"$out"
expect "dry-run created nothing" test ! -e "$CONFIG_DIR/kitty/kitty.conf"

if [[ $fail -eq 0 ]]; then
    echo
    echo "all kitty theme ownership checks passed"
else
    echo
    echo "FAILURES PRESENT"
fi
exit "$fail"
