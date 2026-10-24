#!/usr/bin/env bash
# Syntax-check and lint every shell script tracked in the repository.
#
# Scripts under rices/*/hypr/hyprland/scripts/ are vendored from other projects and
# kept identical to their source (some carry data after `exit`, which `bash -n`
# rejects), so they are skipped.
set -euo pipefail

cd "$(dirname "$0")/.."

files=()
while IFS= read -r f; do
    case "$f" in
        rices/*/hypr/hyprland/scripts/*) continue ;;
        *.sh | bin/* | .githooks/*) files+=("$f") ;;
    esac
done < <(git ls-files)

for f in "${files[@]}"; do
    bash -n "$f"
done

if command -v shellcheck >/dev/null 2>&1; then
    shellcheck -S warning "${files[@]}"
elif [[ -n "${CI:-}" ]]; then
    echo "shell-lint: shellcheck is required in CI" >&2
    exit 1
else
    echo "shell-lint: shellcheck not installed, skipping lint"
fi

echo "ok: ${#files[@]} scripts checked"
