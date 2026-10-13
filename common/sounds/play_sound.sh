#!/usr/bin/env bash
# ==============================================================================
# macOS UI Feedback Sound Player
# Boosts quiet macOS alert sounds on-the-fly and plays via PipeWire.
# Usage: play_sound.sh <filename>  (e.g. play_sound.sh Sosumi.aiff)
# ==============================================================================
set -euo pipefail

# +5 dB: quietest packed file (Hero.aiff) peaks at -5.4 dB, so this stays
# just under clipping for every sound in the pack.
GAIN_DB="${MACOS_SOUND_GAIN_DB:-5}"

SOUND_DIR="${MACOS_SOUND_DIR:-$HOME/.local/share/sounds/macos}"
FILE="$SOUND_DIR/${1:?missing sound filename}"

if [[ ! -f "$FILE" ]]; then
    exit 1
fi

if command -v ffmpeg >/dev/null 2>&1 && command -v pw-play >/dev/null 2>&1; then
    ffmpeg -v error -i "$FILE" -af "volume=${GAIN_DB}dB,aformat=sample_rates=48000:channel_layouts=stereo" -f wav - 2>/dev/null \
        | pw-play --format=s16 --rate=48000 --channels=2 - 2>/dev/null &
else
    pw-play "$FILE" 2>/dev/null &
fi
