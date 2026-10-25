#!/usr/bin/env bash
# Every rices/*/rice.conf has the fields rice-switch shows, as plain text:
# NAME matching the directory, DISPLAY_NAME, SHELL_NAME and COMPOSITOR, with no
# emoji or other non-ASCII symbols in the user-facing ones, and ACCENT (the
# menu tile colour) as #RRGGBB.
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
failed=0

field() {
    # a missing key is reported by the caller, so it must not trip set -e here
    { grep -m1 -E "^$2=" "$1" || true; } | cut -d= -f2- | sed -e 's/^"//' -e 's/"$//'
}

for conf in "$REPO"/rices/*/rice.conf; do
    rice="$(basename "$(dirname "$conf")")"
    [[ "$(field "$conf" NAME)" == "$rice" ]] || { echo "FAIL: $rice: NAME does not match the directory" >&2; failed=1; }
    for key in DISPLAY_NAME SHELL_NAME COMPOSITOR; do
        value="$(field "$conf" "$key")"
        if [[ -z "$value" ]]; then
            echo "FAIL: $rice: $key is missing" >&2
            failed=1
        elif LC_ALL=C grep -q '[^ -~]' <<<"$value"; then
            echo "FAIL: $rice: $key is not plain text: $value" >&2
            failed=1
        fi
    done
    accent="$(field "$conf" ACCENT)"
    [[ "$accent" =~ ^#[0-9A-Fa-f]{6}$ ]] || { echo "FAIL: $rice: ACCENT is not #RRGGBB: '$accent'" >&2; failed=1; }
done

if (( failed == 0 )); then
    echo "ok: rice metadata is complete and plain text"
fi
exit "$failed"
