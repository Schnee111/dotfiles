#!/usr/bin/env bash
# Tests for rices/end4/hypr/scripts/apply_adaptive_glass.sh:
# 1. Blur brightness goes to hyprland/glass.lua (generated state), through the
#    symlink into the repo, for every luminance tier.
# 2. Hand-written custom/general.lua is never touched.
# 3. Without a hyprland/ directory nothing is created.
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$REPO/rices/end4/hypr/scripts/apply_adaptive_glass.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

# --- Stubs --------------------------------------------------------------------

STUBS="$TMP/bin"
mkdir -p "$STUBS"
# magick prints the luminance the test asks for
cat >"$STUBS/magick" <<'EOF'
#!/usr/bin/env bash
echo "$MOCK_LUM"
EOF
for cmd in hyprctl kitten gsettings python3 pgrep; do
    printf '#!/usr/bin/env bash\nexit 0\n' >"$STUBS/$cmd"
done
chmod +x "$STUBS"/*
export PATH="$STUBS:$PATH"

# --- Fake install: live files are symlinks into a copy of the repo files -------

export HOME="$TMP/home"
SRC="$TMP/src"
mkdir -p "$HOME/.config/hypr/hyprland" "$HOME/.config/hypr/custom" "$SRC"
cp "$REPO/rices/end4/hypr/hyprland/glass.lua" "$SRC/glass.lua"
cp "$REPO/rices/end4/hypr/custom/general.lua" "$SRC/general.lua"
ln -s "$SRC/glass.lua" "$HOME/.config/hypr/hyprland/glass.lua"
ln -s "$SRC/general.lua" "$HOME/.config/hypr/custom/general.lua"
WALLPAPER="$TMP/wall.png"
: >"$WALLPAPER"

run() {
    MOCK_LUM="$1" bash "$SCRIPT" "$WALLPAPER"
}

# --- 1 + 2: every tier ---------------------------------------------------------

for case in "80.5:0.95" "50:1.00" "30:1.08" "10:1.15"; do
    lum="${case%%:*}" want="${case#*:}"
    run "$lum"
    [[ -L "$HOME/.config/hypr/hyprland/glass.lua" ]] || fail "glass.lua symlink was replaced (lum $lum)"
    grep -qxF "hl.config({ decoration = { blur = { brightness = $want } } })" "$SRC/glass.lua" \
        || fail "lum $lum: expected brightness $want, got: $(grep hl.config "$SRC/glass.lua")"
    cmp -s "$SRC/general.lua" "$REPO/rices/end4/hypr/custom/general.lua" \
        || fail "lum $lum: custom/general.lua was modified"
done
echo "ok: brightness written to glass.lua for all tiers, general.lua untouched"

grep -qE 'brightness *=' "$REPO/rices/end4/hypr/custom/general.lua" \
    && fail "custom/general.lua still sets blur brightness"
echo "ok: custom/general.lua no longer sets blur brightness"

# --- 3: no hyprland/ directory -------------------------------------------------

rm -rf "$HOME/.config/hypr/hyprland"
run 50
[[ ! -e "$HOME/.config/hypr/hyprland" ]] || fail "hyprland/ was created"
echo "ok: nothing created without hyprland/"
