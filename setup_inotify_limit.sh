#!/usr/bin/env bash
# ==============================================================================
# Raise the per-user inotify instance limit
# Run with: sudo ./setup_inotify_limit.sh
# Optional, one-time. Installs common/sysctl/90-inotify.conf and applies it.
# ==============================================================================
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Error: This script must be run with sudo: sudo $0" >&2
    exit 1
fi

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "1. Installing sysctl config (/etc/sysctl.d/90-inotify.conf)..."
install -m 0644 "$DOTFILES_DIR/common/sysctl/90-inotify.conf" /etc/sysctl.d/90-inotify.conf

echo "2. Applying it..."
sysctl -p /etc/sysctl.d/90-inotify.conf

echo "Done: fs.inotify.max_user_instances is now $(sysctl -n fs.inotify.max_user_instances)."
