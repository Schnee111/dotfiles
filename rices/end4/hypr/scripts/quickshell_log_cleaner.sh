#!/usr/bin/env bash
# ==============================================================================
# quickshell_log_cleaner.sh - Prune dead Quickshell instances and cap active logs
# ==============================================================================
# Upstream Quickshell (issues #1161, #757) writes unrotated logs to
# $XDG_RUNTIME_DIR/quickshell/by-id/<id>/ which can fill the tmpfs RAM partition
# (typically 1.6 GB) over multi-day sessions or during event loops.
#
# This script:
# 1. Removes stale by-id directories belonging to dead PIDs.
# 2. Deletes dangling symlinks in by-pid, by-shell, and by-path.
# 3. Truncates active logs in-place if they exceed 50 MB, safely reclaiming tmpfs RAM.
# ==============================================================================

set -euo pipefail

RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
QS_DIR="$RUNTIME_DIR/quickshell"
MAX_LOG_BYTES=$((50 * 1024 * 1024)) # 50 MB limit

[[ -d "$QS_DIR" ]] || exit 0

# 1. Prune dead instance directories in by-id
if [[ -d "$QS_DIR/by-id" ]]; then
    for id_dir in "$QS_DIR/by-id"/*; do
        [[ -d "$id_dir" ]] || continue
        instance_id=$(basename "$id_dir")

        is_alive=false
        if [[ -d "$QS_DIR/by-pid" ]]; then
            for pid_link in "$QS_DIR/by-pid"/*; do
                [[ -L "$pid_link" ]] || continue
                target=$(readlink "$pid_link" || true)
                if [[ "$target" == *"/$instance_id"* ]]; then
                    pid=$(basename "$pid_link")
                    if kill -0 "$pid" 2>/dev/null && grep -q -E '^(qs|quickshell)$' "/proc/$pid/comm" 2>/dev/null; then
                        is_alive=true
                        break
                    fi
                fi
            done
        fi

        if [[ "$is_alive" == false ]]; then
            rm -rf "$id_dir"
        fi
    done
fi

# 2. Prune dangling symlinks in by-pid, by-shell, and by-path
for subdir in by-pid by-shell by-path; do
    if [[ -d "$QS_DIR/$subdir" ]]; then
        find "$QS_DIR/$subdir" -xtype l -delete 2>/dev/null || true
    fi
done

# 3. Truncate active logs exceeding MAX_LOG_BYTES
if [[ -d "$QS_DIR/by-id" ]]; then
    for log_file in "$QS_DIR/by-id"/*/log.log "$QS_DIR/by-id"/*/log.qslog; do
        [[ -f "$log_file" ]] || continue
        file_size=$(stat -c%s "$log_file" 2>/dev/null || echo 0)
        if (( file_size > MAX_LOG_BYTES )); then
            truncate -s 0 "$log_file"
        fi
    done
fi
