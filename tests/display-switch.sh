#!/usr/bin/env bash
# Tests for bin/caelestia-display-switch.sh:
# 1. Colors guard: ~/.config/rofi/colors.rasi regenerated only when colors.json
#    is newer or colors.rasi is missing.
# 2. Timing check: play_sound.sh does not block caller when audio backend sleeps.
# 3. Rofi input: options stream is newline-terminated via printf '%b\n'.
# 4. Display switch actions: toggle, cancel, HDMI guard, mode transitions.
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

export HOME="$TMP/home"
mkdir -p "$HOME"

LOG_DIR="$TMP/logs"
mkdir -p "$LOG_DIR"

STUBS="$TMP/bin"
mkdir -p "$STUBS"

REAL_GREP="$(command -v grep)"
REAL_PYTHON="$(command -v python3)"
REAL_SLEEP="$(command -v sleep)"
fail() {
    echo "FAIL: $*" >&2
    exit 1
}

# --- Create stubs -------------------------------------------------------------

cat << EOF > "$STUBS/pgrep"
#!/usr/bin/env bash
if [[ "\${MOCK_ROFI_RUNNING:-0}" == "1" ]]; then
    exit 0
fi
exit 1
EOF
chmod +x "$STUBS/pgrep"

cat << EOF > "$STUBS/pkill"
#!/usr/bin/env bash
echo "\$@" >> "$LOG_DIR/pkill.log"
exit 0
EOF
chmod +x "$STUBS/pkill"

ROFI_CHOICE_FILE="$TMP/rofi_choice"
cat << EOF > "$STUBS/rofi"
#!/usr/bin/env bash
cat > "$LOG_DIR/rofi_stdin.log"
echo "\$@" >> "$LOG_DIR/rofi_args.log"
if [[ -f "$ROFI_CHOICE_FILE" ]]; then
    cat "$ROFI_CHOICE_FILE"
fi
exit 0
EOF
chmod +x "$STUBS/rofi"

MONITORS_FILE="$TMP/monitors.json"
cat << EOF > "$STUBS/hyprctl"
#!/usr/bin/env bash
echo "\$@" >> "$LOG_DIR/hyprctl.log"
if [[ "\${1:-}" == "reload" ]]; then
    exit 0
fi
if [[ "\${1:-}" == "monitors" ]]; then
    cat "$MONITORS_FILE"
    exit 0
fi
exit 0
EOF
chmod +x "$STUBS/hyprctl"

cat << EOF > "$STUBS/notify-send"
#!/usr/bin/env bash
echo "\$@" >> "$LOG_DIR/notify.log"
exit 0
EOF
chmod +x "$STUBS/notify-send"

cat << EOF > "$STUBS/play_sound.sh"
#!/usr/bin/env bash
echo "\$@" >> "$LOG_DIR/play_sound.log"
exit 0
EOF
chmod +x "$STUBS/play_sound.sh"

cat << EOF > "$STUBS/sleep"
#!/usr/bin/env bash
echo "\$@" >> "$LOG_DIR/sleep.log"
exit 0
EOF
chmod +x "$STUBS/sleep"

cat << EOF > "$STUBS/grep"
#!/usr/bin/env bash
for arg in "\$@"; do
    if [[ "\$arg" == *"/sys/class/drm/"* ]]; then
        if [[ "\${MOCK_HDMI_CONNECTED:-0}" == "1" ]]; then
            exit 0
        else
            exit 1
        fi
    fi
done
exec "$REAL_GREP" "\$@"
EOF
chmod +x "$STUBS/grep"

cat << EOF > "$STUBS/python3"
#!/usr/bin/env bash
printf 'call\n' >> "$LOG_DIR/python3.log"
exec "$REAL_PYTHON" "\$@"
EOF
chmod +x "$STUBS/python3"

export PATH="$STUBS:$PATH"

# Setup monitor JSON states
JSON_LAPTOP='[{"name": "eDP-1", "disabled": false, "width": 2880}, {"name": "HDMI-A-1", "disabled": true, "width": 0}]'
JSON_EXTERNAL='[{"name": "eDP-1", "disabled": true, "width": 0}, {"name": "HDMI-A-1", "disabled": false, "width": 1920}]'
JSON_EXTEND='[{"name": "eDP-1", "disabled": false, "width": 2880}, {"name": "HDMI-A-1", "disabled": false, "width": 1920}]'

reset_logs() {
    rm -rf "$LOG_DIR"
    mkdir -p "$LOG_DIR"
    touch "$LOG_DIR/notify.log" "$LOG_DIR/hyprctl.log" "$LOG_DIR/play_sound.log"
}

assert_notify() {
    local pattern="$1"
    local tries=0
    while ! grep -q "$pattern" "$LOG_DIR/notify.log" 2>/dev/null && [[ $tries -lt 30 ]]; do
        sleep 0.02
        tries=$((tries + 1))
    done
    grep -q "$pattern" "$LOG_DIR/notify.log" 2>/dev/null || fail "notification missing: $pattern"
}

set_monitors() {
    printf '%s\n' "$1" > "$MONITORS_FILE"
}

set_choice() {
    printf '%s\n' "$1" > "$ROFI_CHOICE_FILE"
}
run_switcher() {
    local rc=0
    bash "$SWITCHER" || rc=$?
    sleep 0.05
    return "$rc"
}

export MOCK_ROFI_RUNNING=0
export MOCK_HDMI_CONNECTED=1

SWITCHER="$REPO/bin/caelestia-display-switch.sh"
COLORS_JSON="$HOME/.local/state/quickshell/user/generated/colors.json"
ROFI_COLORS="$HOME/.config/rofi/colors.rasi"
MODE_FILE="$HOME/.config/caelestia/display-mode"
# --- Test 1: Colors guard (-nt) -----------------------------------------------
echo "=== Testing colors.rasi regeneration guard ==="

reset_logs
rm -f "$COLORS_JSON" "$ROFI_COLORS"
set_choice ""
set_monitors "$JSON_LAPTOP"

# Case 1a: colors.json does not exist -> python3 not run, colors.rasi not created
run_switcher
[[ ! -f "$ROFI_COLORS" ]] || fail "colors.rasi created when colors.json is missing"
[[ ! -f "$LOG_DIR/python3.log" ]] || fail "python3 called when colors.json is missing"
echo "ok: colors.json missing -> no regeneration"

# Case 1b: colors.json exists, colors.rasi missing -> generated
mkdir -p "$(dirname "$COLORS_JSON")"
cat << 'EOF' > "$COLORS_JSON"
{
    "surface_container": "#1a1a1a",
    "surface_container_high": "#2a2a2a",
    "on_surface": "#f0f0f0",
    "outline": "#888888",
    "primary_container": "#334455",
    "on_primary_container": "#ffffff",
    "primary": "#ffffff"
}
EOF

reset_logs
run_switcher
[[ -f "$ROFI_COLORS" ]] || fail "colors.rasi not generated when colors.json is present"
grep -q "Auto-generated from Quickshell Material You palette" "$ROFI_COLORS" || fail "colors.rasi content incorrect"
grep -q "#1a1a1aeb" "$ROFI_COLORS" || fail "colors.rasi missing expected color value"
[[ -f "$LOG_DIR/python3.log" ]] || fail "python3 was not logged on initial generation"
count1="$(wc -l < "$LOG_DIR/python3.log")"
[[ "$count1" -eq 1 ]] || fail "expected 1 python3 call, got $count1"
echo "ok: colors.rasi generated when missing"

# Case 1c: colors.json unchanged -> python3 not called again
reset_logs
run_switcher
[[ ! -f "$LOG_DIR/python3.log" ]] || fail "python3 called when colors.rasi is already up to date"
echo "ok: unchanged colors.json -> skipped"

# Case 1d: colors.json modified (newer) -> regenerated
sleep 0.05
cat << 'EOF' > "$COLORS_JSON"
{
    "surface_container": "#222222",
    "surface_container_high": "#333333",
    "on_surface": "#ffffff",
    "outline": "#999999",
    "primary_container": "#445566",
    "on_primary_container": "#ffffff",
    "primary": "#ffffff"
}
EOF

reset_logs
run_switcher
[[ -f "$LOG_DIR/python3.log" ]] || fail "python3 not called when colors.json is newer"
grep -q "#222222eb" "$ROFI_COLORS" || fail "colors.rasi did not update with new palette"
echo "ok: newer colors.json -> regenerated"

# Case 1e: colors.rasi deleted -> regenerated
rm -f "$ROFI_COLORS"
reset_logs
run_switcher
[[ -f "$ROFI_COLORS" ]] || fail "colors.rasi not regenerated after deletion"
[[ -f "$LOG_DIR/python3.log" ]] || fail "python3 not called when colors.rasi was deleted"
echo "ok: deleted colors.rasi -> regenerated"

# --- Test 2: Rofi input formatting (printf '%b\n') ----------------------------
echo "=== Testing rofi input formatting ==="

reset_logs
set_choice ""
run_switcher

[[ -f "$LOG_DIR/rofi_stdin.log" ]] || fail "rofi stdin not captured"
line_count="$(wc -l < "$LOG_DIR/rofi_stdin.log")"
[[ "$line_count" -eq 3 ]] || fail "expected 3 lines in rofi input, got $line_count"

has_newline="$(tail -c 1 "$LOG_DIR/rofi_stdin.log" | wc -l)"
[[ "$has_newline" -eq 1 ]] || fail "rofi input does not end with a newline"

grep -q "External Monitor Only" "$LOG_DIR/rofi_stdin.log" || fail "missing External Monitor option"
grep -q "Laptop Screen Only" "$LOG_DIR/rofi_stdin.log" || fail "missing Laptop Screen option"
grep -q "Extend Displays" "$LOG_DIR/rofi_stdin.log" || fail "missing Extend Displays option"
echo "ok: rofi input has 3 newline-terminated entries"

# --- Test 3: play_sound.sh non-blocking measurement ---------------------------
echo "=== Measuring play_sound.sh timing ==="

TIMING_TMP="$TMP/sound_timing"
mkdir -p "$TIMING_TMP/bin" "$TIMING_TMP/sounds"
touch "$TIMING_TMP/sounds/Chord.mp3"

cat << EOF > "$TIMING_TMP/bin/ffmpeg"
#!/bin/sh
exec "$REAL_SLEEP" 2
EOF
chmod +x "$TIMING_TMP/bin/ffmpeg"

cat << EOF > "$TIMING_TMP/bin/pw-play"
#!/bin/sh
exec "$REAL_SLEEP" 2
EOF
chmod +x "$TIMING_TMP/bin/pw-play"

# Measure with stub ffmpeg/pw-play placed first on PATH
t_start="$(date +%s%N)"
PATH="$TIMING_TMP/bin:$PATH" MACOS_SOUND_DIR="$TIMING_TMP/sounds" \
    "$REPO/common/sounds/play_sound.sh" Chord.mp3
t_status=$?
t_end="$(date +%s%N)"

t_elapsed_ms=$(( (t_end - t_start) / 1000000 ))
echo "play_sound.sh exited with code $t_status in ${t_elapsed_ms}ms"

[[ $t_status -eq 0 ]] || fail "play_sound.sh exited with failure $t_status"
# Non-blocking threshold: must complete well under the 2s (2000ms) sleep
[[ $t_elapsed_ms -lt 1000 ]] || fail "play_sound.sh blocked caller: ${t_elapsed_ms}ms >= 1000ms"
echo "ok: play_sound.sh does not block caller (${t_elapsed_ms}ms < 1000ms threshold)"

# --- Test 4: Display switcher actions -----------------------------------------
echo "=== Testing display switch logic ==="

# 4a: Toggle behavior (rofi already running)
reset_logs
MOCK_ROFI_RUNNING=1 run_switcher
[[ -f "$LOG_DIR/pkill.log" ]] || fail "pkill not called when rofi already running"
grep -q -- "-x rofi" "$LOG_DIR/pkill.log" || fail "pkill did not target rofi"
[[ ! -f "$LOG_DIR/rofi_stdin.log" ]] || fail "rofi launched when already running"
echo "ok: toggle kills existing rofi and exits immediately"

# 4b: User cancel (Escape)
reset_logs
MOCK_ROFI_RUNNING=0
set_choice ""
rm -f "$MODE_FILE"
run_switcher
[[ ! -f "$MODE_FILE" ]] || fail "mode file written on cancel"
echo "ok: cancel exits cleanly without action"

# 4c: External - HDMI disconnected -> notify error, exit 1
reset_logs
set_choice "󰍹  External Monitor Only"
set_monitors "$JSON_LAPTOP"
MOCK_HDMI_CONNECTED=0
status=0
run_switcher || status=$?
[[ $status -eq 1 ]] || fail "expected exit 1 when HDMI disconnected, got $status"
assert_notify "HDMI monitor not detected"
echo "ok: external switch rejected when HDMI disconnected"

# 4d: External - Already on external -> notify already on, exit 0
reset_logs
set_choice "󰍹  External Monitor Only"
set_monitors "$JSON_EXTERNAL"
MOCK_HDMI_CONNECTED=1
run_switcher
assert_notify "Already on External Monitor Only"
! grep -q "reload" "$LOG_DIR/hyprctl.log" 2>/dev/null || fail "hyprctl reload triggered when already on external"
echo "ok: external switch early-exits when already on external"

# 4e: External - Transition from laptop
reset_logs
set_choice "󰍹  External Monitor Only"
set_monitors "$JSON_LAPTOP"
MOCK_HDMI_CONNECTED=1
run_switcher
[[ "$(cat "$MODE_FILE")" == "external" ]] || fail "mode file not set to external"
grep -q "Chord.mp3" "$LOG_DIR/play_sound.log" || fail "Chord.mp3 sound not played"
assert_notify "External Monitor Only (1080p @ 200Hz)"
reloads="$(grep -c "reload" "$LOG_DIR/hyprctl.log" || true)"
[[ "$reloads" -eq 2 ]] || fail "expected 2 hyprctl reloads (extend + external), got $reloads"
echo "ok: laptop -> external transition (2-step reload, sound, notification)"

# 4f: Laptop - Already on laptop -> notify already on, exit 0
reset_logs
set_choice "󰌢  Laptop Screen Only"
set_monitors "$JSON_LAPTOP"
MOCK_HDMI_CONNECTED=1
run_switcher
assert_notify "Already on Laptop Screen Only"
! grep -q "reload" "$LOG_DIR/hyprctl.log" 2>/dev/null || fail "hyprctl reload triggered when already on laptop"
echo "ok: laptop switch early-exits when already on laptop"

# 4g: Laptop - Transition from external
reset_logs
set_choice "󰌢  Laptop Screen Only"
set_monitors "$JSON_EXTERNAL"
MOCK_HDMI_CONNECTED=1
run_switcher
[[ "$(cat "$MODE_FILE")" == "laptop" ]] || fail "mode file not set to laptop"
grep -q "Swish.mp3" "$LOG_DIR/play_sound.log" || fail "Swish.mp3 sound not played"
assert_notify "Laptop Screen Only"
reloads="$(grep -c "reload" "$LOG_DIR/hyprctl.log" || true)"
[[ "$reloads" -eq 2 ]] || fail "expected 2 hyprctl reloads (extend + laptop), got $reloads"
echo "ok: external -> laptop transition (2-step reload, sound, notification)"

# 4h: Extend - Already on extend -> notify already on, exit 0
reset_logs
set_choice "󰍺  Extend Displays"
set_monitors "$JSON_EXTEND"
MOCK_HDMI_CONNECTED=1
run_switcher
assert_notify "Already on Extended Displays"
! grep -q "reload" "$LOG_DIR/hyprctl.log" 2>/dev/null || fail "hyprctl reload triggered when already on extend"
echo "ok: extend switch early-exits when already on extend"

# 4i: Extend - Transition from laptop
reset_logs
set_choice "󰍺  Extend Displays"
set_monitors "$JSON_LAPTOP"
MOCK_HDMI_CONNECTED=1
run_switcher
[[ "$(cat "$MODE_FILE")" == "extend" ]] || fail "mode file not set to extend"
grep -q "Chord.mp3" "$LOG_DIR/play_sound.log" || fail "Chord.mp3 sound not played"
assert_notify "Extended Displays (Dual Screen)"
reloads="$(grep -c "reload" "$LOG_DIR/hyprctl.log" || true)"
[[ "$reloads" -eq 1 ]] || fail "expected 1 hyprctl reload (extend), got $reloads"
echo "ok: laptop -> extend transition (1 reload, sound, notification)"

echo "PASS: display-switch"
