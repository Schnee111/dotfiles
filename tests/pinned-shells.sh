#!/usr/bin/env bash
# Third-party shells are pinned: fresh installs get the pinned commit, existing
# checkouts are never moved unless DOTFILES_UPDATE_SHELLS=1.
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

export HOME="$TMP/home"
export GIT_CONFIG_GLOBAL="$TMP/gitconfig"
git config --global user.name test
git config --global user.email test@example.invalid
git config --global protocol.file.allow always
git config --global uploadpack.allowAnySHA1InWant true
mkdir -p "$HOME"

# shellcheck source=lib/core.sh
source "$REPO/lib/core.sh"
# shellcheck source=lib/shells.sh
source "$REPO/lib/shells.sh"

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

up="$TMP/upstream"
git init -q "$up"
git -C "$up" commit -q --allow-empty -m pinned
pinned="$(git -C "$up" rev-parse HEAD)"
git -C "$up" commit -q --allow-empty -m newer
newer="$(git -C "$up" rev-parse HEAD)"
url="file://$up"

dest="$TMP/fresh"
sync_pinned_repo "$url" "$dest" "$pinned" fresh >/dev/null
[[ "$(git -C "$dest" rev-parse HEAD)" == "$pinned" ]] || fail "fresh install is not at the pinned commit"

git -C "$dest" fetch -q origin "$newer" && git -C "$dest" checkout -q --detach "$newer"
sync_pinned_repo "$url" "$dest" "$pinned" existing >/dev/null
[[ "$(git -C "$dest" rev-parse HEAD)" == "$newer" ]] || fail "an existing checkout was moved without opt-in"

DOTFILES_UPDATE_SHELLS=1 sync_pinned_repo "$url" "$dest" "$pinned" existing >/dev/null
[[ "$(git -C "$dest" rev-parse HEAD)" == "$pinned" ]] || fail "DOTFILES_UPDATE_SHELLS=1 did not move to the pinned commit"

mkdir -p "$TMP/plain"
echo keep >"$TMP/plain/file"
sync_pinned_repo "$url" "$TMP/plain" "$pinned" plain >/dev/null
[[ "$(cat "$TMP/plain/file")" == keep && ! -d "$TMP/plain/.git" ]] || fail "a non-git directory was modified"

if sync_pinned_repo "$url" "$TMP/missing" "0000000000000000000000000000000000000000" bad >/dev/null 2>&1; then
    fail "an unknown commit was reported as success"
fi

echo "ok: pinned shells (fresh, existing kept, opt-in update, non-git, bad rev)"
