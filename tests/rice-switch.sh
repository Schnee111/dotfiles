#!/usr/bin/env bash
# Tests for bin/rice-switch menu handling (always with --dry-run):
# 1. Esc in the menu (rofi exits 1) does nothing and exits 0.
# 2. Closing the menu without a row (rofi exits 0, prints nothing) does the same.
# 3. A chosen row still reaches the switch.
# 4. Empty or path-like rice names are rejected.
# 5. Menu content: one two-line row per rice (DISPLAY_NAME, then COMPOSITOR ·
#    SHELL_NAME), a dot and the active mark on the current rice, an
#    out-of-range index ignored, theme fallback.
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

export HOME="$TMP/home"
mkdir -p "$HOME/.config/rofi"
: >"$HOME/.config/rofi/rice-switch.rasi"
: >"$HOME/.config/rofi/display.rasi"
echo end4 >"$HOME/.config/.current_rice"

STUBS="$TMP/bin"
mkdir -p "$STUBS"
# rofi: MOCK_ROFI_EXIT is its status, MOCK_ROFI_OUT what it prints
cat >"$STUBS/rofi" <<EOF
#!/usr/bin/env bash
cat >"$TMP/rofi.stdin"
printf '%s\n' "\$@" >"$TMP/rofi.args"
printf '%s' "\${MOCK_ROFI_OUT:-}"
exit "\${MOCK_ROFI_EXIT:-0}"
EOF
for cmd in notify-send hyprland niri; do
    printf '#!/usr/bin/env bash\nexit 0\n' >"$STUBS/$cmd"
done
chmod +x "$STUBS"/*
export PATH="$STUBS:$PATH"

run() {
    set +e
    out="$(bash "$REPO/bin/rice-switch" -n "$@" 2>&1)"
    status=$?
    set -e
}

# --- 1 + 2: cancelled menu -----------------------------------------------------

for case in "esc:1:" "empty:0:"; do
    IFS=: read -r name code printed <<<"$case"
    MOCK_ROFI_EXIT="$code" MOCK_ROFI_OUT="$printed" run
    [[ $status -eq 0 ]] || fail "$name: exit $status, expected 0: $out"
    [[ -z "$out" ]] || fail "$name: expected no output, the switch ran: $out"
done
echo "ok: Esc and an empty choice cancel without switching"

# --- 3: a chosen row -----------------------------------------------------------

# rofi prints the chosen row's index (-format i)
index="$(find "$REPO/rices" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | LC_ALL=C sort | grep -nx iris | cut -d: -f1)"
MOCK_ROFI_EXIT=0 MOCK_ROFI_OUT="$((index - 1))" run
# CI has no niri session file; reaching that check still proves iris was chosen
[[ "$out" == *"dry run for 'iris'"* || "$out" == *"'niri.desktop' not found"* ]] \
    || fail "choosing iris did not reach the switch: $out"
echo "ok: a chosen row reaches the switch"

# --- 4: invalid names ------------------------------------------------------------

for bad in "../end4" "." "end4/../iris" "-x"; do
    run "$bad"
    [[ $status -ne 0 && "$out" == *"Invalid rice name"* ]] || fail "'$bad' not rejected: $out"
done
echo "ok: path-like rice names are rejected"

# --- 5: menu content ----------------------------------------------------------------

MOCK_ROFI_EXIT=1 run
rows="$(tr -cd '\037' <"$TMP/rofi.stdin" | wc -c)"
rices="$(find "$REPO/rices" -mindepth 1 -maxdepth 1 -type d | wc -l)"
[[ "$rows" -eq "$rices" ]] || fail "expected $rices rows, got $rows"
grep -qF '<span weight="600">end4</span>' "$TMP/rofi.stdin" || fail "end4 row has no plain title: $(cat "$TMP/rofi.stdin")"
grep -qF '>Hyprland · end4-pC Material 3</span>' "$TMP/rofi.stdin" || fail "end4 row has no subtitle"
[[ "$(grep -o 'alpha="80%">●' "$TMP/rofi.stdin" | wc -l)" == 1 ]] || fail "expected one visible dot, for the current rice"
grep -qF 'alpha="80%">●  </span><span weight="600">end4</span>' "$TMP/rofi.stdin" || fail "the dot is not on the end4 row"
end4_index="$(find "$REPO/rices" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | LC_ALL=C sort | grep -nx end4 | cut -d: -f1)"
grep -A1 -x -- '-a' "$TMP/rofi.args" | tail -n1 | grep -qx "$((end4_index - 1))" || fail "current rice not marked active: $(cat "$TMP/rofi.args")"
grep -A1 -x -- '-theme' "$TMP/rofi.args" | tail -n1 | grep -q 'rice-switch.rasi$' || fail "rice-switch.rasi not used"
echo "ok: one two-line row per rice, current rice active"

MOCK_ROFI_EXIT=0 MOCK_ROFI_OUT=99 run
[[ $status -eq 0 && -z "$out" ]] || fail "out-of-range index switched: $out"
echo "ok: out-of-range index ignored"

rm "$HOME/.config/rofi/rice-switch.rasi"
MOCK_ROFI_EXIT=1 run
grep -A1 -x -- '-theme' "$TMP/rofi.args" | tail -n1 | grep -q 'display.rasi$' || fail "no fallback to display.rasi"
echo "ok: falls back to display.rasi before the next install links the theme"
