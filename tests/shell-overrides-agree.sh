#!/usr/bin/env bash
# The end-4 shell's Hyprland settings page writes its stored options into
# hyprland/shellOverrides/main.lua, which loads after custom/*.lua. A value the
# rice sets in custom/general.lua must therefore be the same in the rice's
# illogical-impulse/config.json, or the shell silently overrides it with its
# default once that page is opened.
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
failed=0

for general in "$REPO"/rices/*/hypr/custom/general.lua; do
    rice_dir="${general%/hypr/custom/general.lua}"
    config="$rice_dir/illogical-impulse/config.json"
    [[ -f "$config" ]] || continue
    rice="${rice_dir##*/}"

    # misc:focus_on_activate <-> hyprland.misc.focusOnActivate (shell default: false)
    lua="$(grep -oE '^\s*focus_on_activate\s*=\s*(true|false)' "$general" | grep -oE 'true|false' | tail -n1 || true)"
    [[ -n "$lua" ]] || continue
    json="$(jq -r '.hyprland.misc.focusOnActivate // false' "$config")"
    if [[ "$lua" != "$json" ]]; then
        echo "FAIL: $rice: custom/general.lua focus_on_activate = $lua, config.json hyprland.misc.focusOnActivate = $json" >&2
        failed=1
    else
        echo "ok: $rice: focus_on_activate = $lua in both"
    fi
done

exit "$failed"
