#!/usr/bin/env bash

TARGET_DIR="$(xdg-user-dir PICTURES 2>/dev/null || echo "$HOME/Pictures")/Screenshots"
mkdir -p "$TARGET_DIR"

FILENAME="Screenshot_$(date '+%Y-%m-%d_%H.%M.%S').png"
FILEPATH="$TARGET_DIR/$FILENAME"

# Capture active monitor or fallback to entire screen
ACTIVE_MON="$(hyprctl activeworkspace -j 2>/dev/null | jq -r '.monitor // empty')"
if [ -n "$ACTIVE_MON" ]; then
    grim -o "$ACTIVE_MON" "$FILEPATH"
else
    grim "$FILEPATH"
fi

if [ -f "$FILEPATH" ]; then
    # Copy to clipboard
    wl-copy --type image/png < "$FILEPATH"

    # Play shutter sound in background if available
    canberra-gtk-play -i camera-shutter >/dev/null 2>&1 &

    # Send desktop notification with preview thumbnail
    notify-send -a "Screenshot" \
        -i "$FILEPATH" \
        "Screenshot Captured" \
        "$FILENAME\nSaved to Screenshots and copied to clipboard."
fi
