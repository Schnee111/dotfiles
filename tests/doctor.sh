#!/usr/bin/env bash
# Doctor contract: drift is detected per path kind, exit status is 1 when any
# path needs relinking, and the "leftover from another rice" case is a note
# (exit 0) so it cannot mask real drift.
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

export HOME="$TMP/home"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_STATE_HOME="$HOME/.local/state"
mkdir -p "$XDG_CONFIG_HOME" "$XDG_STATE_HOME/dotfiles"
CONFIG_DIR="$XDG_CONFIG_HOME"
MANIFEST="$XDG_STATE_HOME/dotfiles/manifest.tsv"

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

src_ok="$REPO/common/kitty/kitty.conf"
src_drift="$REPO/common/fish/config.fish"
src_replaced="$REPO/common/starship/starship.toml"
src_missing="$REPO/common/swappy/config"

ln -s "$src_ok" "$CONFIG_DIR/ok.conf"
ln -s "$REPO/common/rofi/colors.rasi" "$CONFIG_DIR/drift.conf"
printf 'shell rewrote this\n' >"$CONFIG_DIR/replaced.conf"
mkdir -p "$CONFIG_DIR/hypr"
ln -s "$REPO/rices/vitreus/hypr/scheme/current.lua" "$CONFIG_DIR/hypr/leftover.lua"
printf 'end4\n' >"$CONFIG_DIR/.current_rice"

{
    printf '%s\t%s\n' "$CONFIG_DIR/ok.conf" "$src_ok"
    printf '%s\t%s\n' "$CONFIG_DIR/drift.conf" "$src_drift"
    printf '%s\t%s\n' "$CONFIG_DIR/replaced.conf" "$src_replaced"
    printf '%s\t%s\n' "$CONFIG_DIR/missing.conf" "$src_missing"
} >"$MANIFEST"

out="$("$REPO/bin/dotfiles" doctor 2>&1)" && status=0 || status=$?
echo "$out"
[[ $status -eq 1 ]] || fail "doctor should exit 1 on drift, got $status"
grep -q "drift      $CONFIG_DIR/drift.conf" <<<"$out" || fail "drift not reported"
grep -q "replaced   $CONFIG_DIR/replaced.conf" <<<"$out" || fail "replaced file not reported"
grep -q "missing    $CONFIG_DIR/missing.conf" <<<"$out" || fail "missing link not reported"
grep -q "leftover   $CONFIG_DIR/hypr/leftover.lua" <<<"$out" || fail "leftover link not reported"
grep -q "ok  " <<<"$out" && fail "clean path should not be printed as an issue" || true
grep -q "3 issue(s)" <<<"$out" || fail "expected 3 issues, output: $out"
echo "ok: drift, replaced, missing detected; leftover reported separately"

# No manifest at all must fail closed, not silently pass.
rm -f "$MANIFEST"
out="$("$REPO/bin/dotfiles" doctor 2>&1)" && status=0 || status=$?
[[ $status -eq 1 ]] || fail "doctor without manifest should exit 1, got $status"
echo "ok: missing manifest fails closed"

echo "PASS: doctor"
