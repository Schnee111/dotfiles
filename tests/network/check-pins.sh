#!/usr/bin/env bash
# Check every pinned third-party revision in lib/shells.sh:
#   1. it can be fetched the way sync_pinned_repo fetches it (shallow fetch by SHA);
#   2. it is part of the history of the remote's default branch.
# The second check is the one that notices a rewritten history: GitHub keeps serving
# an orphaned commit by SHA for a while, so check 1 alone still passes, but the pin is
# no longer on the branch and will eventually be garbage-collected.
#
# Needs the network, so it is not part of tests/run.sh or the pre-commit hook; CI
# runs it directly, on every push and weekly.
set -euo pipefail

# Same reason as tests/pinned-shells.sh: never let hook-exported GIT_* variables in.
unset "${!GIT_@}"

REPO="$(cd "$(dirname "$0")/../.." && pwd)"
# shellcheck source=lib/shells.sh
source "$REPO/lib/shells.sh"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
export HOME="$TMP/home"
export GIT_CONFIG_GLOBAL="$TMP/gitconfig"
mkdir -p "$HOME"

# retry <command...>: run it, retrying twice with a pause, so a network blip does not
# fail the check.
retry() {
    local delay
    for delay in 0 2 4; do
        sleep "$delay"
        "$@" && return 0
    done
    return 1
}

checked=0
failed=0
for url_var in $(compgen -v | grep -E '_URL$'); do
    name="${url_var%_URL}"
    rev_var="${name}_REV"
    [[ -n "${!rev_var:-}" ]] || continue
    url="${!url_var}"
    rev="${!rev_var}"
    checked=$((checked + 1))

    git init -q "$TMP/$name"
    if ! retry git -C "$TMP/$name" fetch -q --depth 1 "$url" "$rev" 2>/dev/null; then
        echo "FAIL: $name ${rev:0:7} cannot be fetched from $url" >&2
        failed=$((failed + 1))
        continue
    fi

    # History only (no trees or blobs) of the default branch, in a repository of its own
    # because the one above is shallow.
    git init -q "$TMP/$name-history"
    if retry git -C "$TMP/$name-history" fetch -q --filter=tree:0 "$url" HEAD 2>/dev/null &&
        git -C "$TMP/$name-history" merge-base --is-ancestor "$rev" FETCH_HEAD 2>/dev/null; then
        echo "ok:   $name ${rev:0:7} is on the default branch of $url"
    else
        echo "FAIL: $name ${rev:0:7} is not part of the default branch history of $url (rewritten or unmerged?)" >&2
        failed=$((failed + 1))
    fi
done

((checked > 0)) || { echo "FAIL: no pinned revisions found in lib/shells.sh" >&2; exit 1; }
((failed == 0)) || { echo "$failed of $checked pinned revisions are unreachable" >&2; exit 1; }
echo "all $checked pinned revisions are fetchable and on their default branch"
