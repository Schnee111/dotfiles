#!/usr/bin/env bash
# Tests for bin/rice-switch menu handling (always with --dry-run):
# 1. Esc in the menu (rofi exits 1) does nothing and exits 0.
# 2. Closing the menu without a row (rofi exits 0, prints nothing) does the same.
# 3. A chosen row still reaches the switch.
# 4. Empty or path-like rice names are rejected.
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
cat >"$STUBS/rofi" <<'EOF'
#!/usr/bin/env bash
cat >/dev/null
printf '%s' "${MOCK_ROFI_OUT:-}"
exit "${MOCK_ROFI_EXIT:-0}"
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

# rofi prints the chosen row, which is the rice's DISPLAY_NAME
iris_row="$(grep -m1 '^DISPLAY_NAME=' "$REPO/rices/iris/rice.conf" | cut -d= -f2- | tr -d '"')"
MOCK_ROFI_EXIT=0 MOCK_ROFI_OUT="$iris_row" run
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
