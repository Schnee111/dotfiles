#!/usr/bin/env python3
"""
Hyprland Session Layout Engine
Executes, captures, and manages deterministic window tiling layouts across Hyprland workspaces.
"""

import sys
import os
import json
import time
import subprocess
import argparse
from pathlib import Path

CONFIG_FILE = Path(os.environ.get("HOME", "/home/schnee")) / ".config/hypr/custom/session_layout.json"


def dispatch(lua_expr: str):
    """Send Lua expression to Hyprland dispatcher."""
    try:
        subprocess.run(
            ["hyprctl", "dispatch", lua_expr],
            check=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL
        )
    except Exception as e:
        print(f"[layout_engine] Dispatch error ({lua_expr}): {e}", file=sys.stderr)


def get_clients():
    """Retrieve all current Hyprland clients."""
    try:
        out = subprocess.check_output(["hyprctl", "clients", "-j"], stderr=subprocess.DEVNULL)
        return json.loads(out.decode())
    except Exception:
        return []


def wait_for_window(pattern: str, timeout: float = 15.0) -> bool:
    """Poll compositor until a window matching pattern (case-insensitive) appears."""
    pattern_lower = pattern.lower()
    start = time.time()
    while time.time() - start < timeout:
        clients = get_clients()
        for c in clients:
            c_class = c.get("class", "").lower()
            c_title = c.get("title", "").lower()
            if pattern_lower in c_class or pattern_lower in c_title:
                return True
        time.sleep(0.25)
    return False


def wait_for_window_count(pattern: str, expected: int, timeout: float = 15.0) -> bool:
    """Poll compositor until at least expected count of windows matching pattern appear."""
    pattern_lower = pattern.lower()
    start = time.time()
    while time.time() - start < timeout:
        clients = get_clients()
        count = sum(1 for c in clients if pattern_lower in c.get("class", "").lower() or pattern_lower in c.get("title", "").lower())
        if count >= expected:
            return True
        time.sleep(0.25)
    return False


def run_layout(config_path: Path = CONFIG_FILE):
    """Execute the full layout sequence defined in JSON."""
    if not config_path.exists():
        print(f"[layout_engine] Config file not found: {config_path}", file=sys.stderr)
        return

    with open(config_path, "r", encoding="utf-8") as f:
        entries = json.load(f)

    # Clean quickshell logs
    cleaner = Path.home() / ".config/hypr/scripts/quickshell_log_cleaner.sh"
    if cleaner.exists():
        subprocess.Popen([str(cleaner)], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    # Group entries by workspace so trees are built before resizing
    ws_dict = {}
    for entry in entries:
        ws = entry.get("workspace", 1)
        ws_dict.setdefault(ws, []).append(entry)

    for ws, group in ws_dict.items():
        for entry in group:
            cmd = entry.get("cmd", "").strip()
            match_pattern = entry.get("match", "").strip()
            split = entry.get("split", "root")
            target = entry.get("target", "").strip()
            timeout = entry.get("timeout", 15)
            shortcut = entry.get("shortcut", "")

            if not cmd:
                continue

            # Set directional preselection if attached to parent window
            if split in ("right", "down") and target:
                dispatch(f'hl.dsp.focus({{ window = "class:{target}" }})')
                time.sleep(0.2)
                if split == "right":
                    dispatch('hl.dsp.layout("preselect r")')
                else:
                    dispatch('hl.dsp.layout("preselect d")')
                time.sleep(0.1)

            # Spawn application into workspace
            dispatch(f'hl.dsp.exec_cmd("{cmd}", {{ workspace = "{ws} silent" }})')

            # Active polling for window mapping
            if match_pattern:
                wait_for_window(match_pattern, timeout=timeout)
                time.sleep(0.2)

            # Handle secondary clone / shortcut (e.g. Hermes Ctrl+Shift+N)
            if shortcut and match_pattern:
                dispatch(f'hl.dsp.focus({{ window = "class:{match_pattern}" }})')
                time.sleep(0.3)
                dispatch('hl.dsp.layout("preselect r")')
                dispatch(f'hl.dsp.send_shortcut({{mods="CTRL SHIFT", key="N", window="class:{match_pattern}"}})')
                wait_for_window_count(match_pattern, 2, timeout=timeout)
                time.sleep(0.3)

        # AFTER all windows in this workspace are spawned, apply pixel-exact resizing
        time.sleep(0.3)
        for entry in group:
            match_pattern = entry.get("match", "").strip()
            width = entry.get("width", 0)
            height = entry.get("height", 0)
            if width > 0 and height > 0 and match_pattern:
                dispatch(f'hl.dsp.window.resize({{ window = "class:{match_pattern}", x = {width}, y = {height}, relative = false }})')
                time.sleep(0.2)

    # Focus back to workspace 2 main window
    time.sleep(0.5)
    dispatch('hl.dsp.focus({ workspace = 2 })')
    time.sleep(0.2)
    dispatch('hl.dsp.focus({ window = "class:kitty-main" })')

    # Apply adaptive glass
    glass = Path.home() / ".config/hypr/scripts/apply_adaptive_glass.sh"
    if glass.exists():
        subprocess.Popen([str(glass)], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def capture_current_layout(config_path: Path = CONFIG_FILE):
    """Capture currently open windows and update session_layout.json."""
    clients = get_clients()
    if not clients:
        print("[layout_engine] No clients found to capture.", file=sys.stderr)
        return

    # Load existing entries to preserve custom commands where possible
    existing_cmds = {}
    if config_path.exists():
        try:
            with open(config_path, "r", encoding="utf-8") as f:
                old_entries = json.load(f)
                for e in old_entries:
                    m = e.get("match", "")
                    if m and e.get("cmd"):
                        existing_cmds[m] = e
        except Exception:
            pass

    # Filter out floating, pinned, or negative workspaces
    valid_clients = []
    for c in clients:
        ws_id = c.get("workspace", {}).get("id", -1)
        if ws_id <= 0 or c.get("floating", False):
            continue
        valid_clients.append(c)

    # Group by workspace and sort by position (top-left to bottom-right)
    ws_groups = {}
    for c in valid_clients:
        ws_id = c["workspace"]["id"]
        ws_groups.setdefault(ws_id, []).append(c)

    new_entries = []
    for ws_id in sorted(ws_groups.keys()):
        # Sort by x coordinate, then y coordinate
        group = sorted(ws_groups[ws_id], key=lambda item: (item["at"][0], item["at"][1]))
        first_window = group[0]

        for idx, win in enumerate(group):
            cls = win.get("class", "")
            title = win.get("title", "")
            w, h = win.get("size", [0, 0])
            x, y = win.get("at", [0, 0])

            # Try to resolve command line from /proc/pid/cmdline
            cmd = ""
            pid = win.get("pid")
            if pid:
                try:
                    with open(f"/proc/{pid}/cmdline", "rb") as pf:
                        raw = pf.read().replace(b"\x00", b" ").decode().strip()
                        if raw:
                            cmd = raw
                except Exception:
                    pass

            # Precedence: existing curated command > resolved command > class
            old_item = existing_cmds.get(cls, {})
            final_cmd = old_item.get("cmd") or cmd or cls

            # Determine split relationship
            if idx == 0:
                split = "root"
                target = ""
            else:
                prev_win = group[idx - 1]
                prev_cls = prev_win.get("class", "")
                prev_x, prev_y = prev_win.get("at", [0, 0])
                if x > prev_x and abs(y - prev_y) < 100:
                    split = "right"
                    target = prev_cls
                else:
                    split = "down"
                    target = prev_cls

            new_entries.append({
                "workspace": ws_id,
                "name": title[:24] if title else cls,
                "cmd": final_cmd,
                "match": cls,
                "split": split,
                "target": target,
                "width": w,
                "height": h,
                "timeout": old_item.get("timeout", 15)
            })

    # Save to config file
    with open(config_path, "w", encoding="utf-8") as f:
        json.dump(new_entries, f, indent=2)

    print(f"[layout_engine] Successfully captured {len(new_entries)} windows to {config_path}")


def main():
    parser = argparse.ArgumentParser(description="Hyprland Session Layout Engine")
    parser.add_argument("--run", action="store_true", help="Execute startup window layout")
    parser.add_argument("--capture", action="store_true", help="Capture current desktop windows into config")
    parser.add_argument("--config", type=str, default=str(CONFIG_FILE), help="Custom config path")
    args = parser.parse_args()

    cfg = Path(args.config)
    if args.capture:
        capture_current_layout(cfg)
    elif args.run:
        run_layout(cfg)
    else:
        parser.print_help()


if __name__ == "__main__":
    main()
