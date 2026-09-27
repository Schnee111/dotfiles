#!/usr/bin/env python3
import glob
import os
import re
import socket
import subprocess
import sys
import time

HOME = os.path.expanduser("~")
MONITORS_LUA = os.path.join(HOME, ".config/hypr/monitors.lua")

def log(msg):
    print(f"[monitor-watcher] {msg}", flush=True)

def has_connected_external():
    """Returns True if any physical external DRM connector is connected."""
    for path in glob.glob("/sys/class/drm/card*-*/status"):
        name = os.path.basename(os.path.dirname(path))
        # Skip internal panels
        if any(int_name in name for int_name in ["eDP", "LVDS", "DSI"]):
            continue
        try:
            with open(path, "r") as f:
                if f.read().strip() == "connected":
                    return True
        except Exception:
            pass
    return False

def ensure_quickshell():
    """Verify Quickshell is running, respawn if died."""
    try:
        res = subprocess.run(["pgrep", "-x", "qs"], stdout=subprocess.DEVNULL)
        if res.returncode != 0:
            log("Quickshell is not running, respawning...")
            subprocess.Popen(
                ["qs", "-c", "end4-pC"],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                start_new_session=True,
            )
    except Exception as e:
        log(f"Error checking quickshell: {e}")

last_action_time = 0.0

def is_laptop_only_active():
    try:
        if os.path.exists(MONITORS_LUA):
            with open(MONITORS_LUA, "r") as f:
                c = f.read()
            if 'output = "eDP-1"' in c and 'output = "HDMI-A-1"' in c:
                edp_part = c.split('output = "eDP-1"')[1].split("hl.monitor")[0]
                hdmi_part = c.split('output = "HDMI-A-1"')[1]
                if "disabled = true" not in edp_part and "disabled = true" in hdmi_part:
                    return True
    except Exception:
        pass
    return False

def is_external_only_active():
    try:
        if os.path.exists(MONITORS_LUA):
            with open(MONITORS_LUA, "r") as f:
                c = f.read()
            if 'output = "eDP-1"' in c and 'output = "HDMI-A-1"' in c:
                edp_part = c.split('output = "eDP-1"')[1].split("hl.monitor")[0]
                hdmi_part = c.split('output = "HDMI-A-1"')[1]
                if "disabled = true" in edp_part and "disabled = true" not in hdmi_part:
                    return True
    except Exception:
        pass
    return False

def restore_laptop_display():
    """Switches to Laptop Only mode (eDP-1 @ 2880x1800@90, scale 1.5)."""
    global last_action_time
    if time.time() - last_action_time < 2.0 or is_laptop_only_active():
        return
    last_action_time = time.time()

    log("Restoring laptop screen (eDP-1)...")

    # Update monitors.lua
    content = """hl.monitor({
    output = "eDP-1",
    mode = "2880x1800@90",
    position = "0x0",
    scale = 1.5,
})

hl.monitor({
    output = "HDMI-A-1",
    disabled = true,
})
"""
    try:
        with open(MONITORS_LUA, "w") as f:
            f.write(content)
    except Exception as e:
        log(f"Failed to write {MONITORS_LUA}: {e}")

    # Hyprctl eval & reload
    subprocess.run([
        "hyprctl", "eval",
        'hl.monitor({ output = "eDP-1", mode = "2880x1800@90", position = "0x0", scale = 1.5, disabled = false }); hl.monitor({ output = "HDMI-A-1", disabled = true })'
    ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    subprocess.run(["hyprctl", "reload"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    time.sleep(0.3)
    ensure_quickshell()

    subprocess.Popen([
        "notify-send", "-t", "2500", "-a", "Display", "Display Output",
        "External monitor disconnected. Laptop display restored.",
        "-i", "computer"
    ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

def activate_external_display():
    """Switches to External Monitor Only (HDMI-A-1 @ 1920x1080@200, scale 1)."""
    global last_action_time
    if time.time() - last_action_time < 2.0 or is_external_only_active():
        return
    last_action_time = time.time()

    log("External display detected. Docking to External Only (HDMI-A-1)...")

    # Update monitors.lua
    content = """hl.monitor({
    output = "eDP-1",
    disabled = true,
})

hl.monitor({
    output = "HDMI-A-1",
    mode = "1920x1080@200",
    position = "0x0",
    scale = 1,
})
"""
    try:
        with open(MONITORS_LUA, "w") as f:
            f.write(content)
    except Exception as e:
        log(f"Failed to write {MONITORS_LUA}: {e}")

    # Always enable target first, then disable internal to avoid zero outputs
    subprocess.run([
        "hyprctl", "eval",
        'hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@200", position = "0x0", scale = 1, disabled = false }); hl.monitor({ output = "eDP-1", disabled = true })'
    ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    subprocess.run(["hyprctl", "reload"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    time.sleep(0.3)
    ensure_quickshell()

    subprocess.Popen([
        "notify-send", "-t", "2500", "-a", "Display", "Display Output",
        "External monitor connected. Switched to External Only (1080p @ 200Hz).",
        "-i", "video-display"
    ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

def get_socket_path():
    xdg = os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}")
    sig = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE")
    if not sig:
        try:
            hypr_dir = os.path.join(xdg, "hypr")
            entries = [e for e in os.listdir(hypr_dir) if os.path.isdir(os.path.join(hypr_dir, e))]
            if entries:
                sig = sorted(entries, key=lambda e: os.path.getmtime(os.path.join(hypr_dir, e)), reverse=True)[0]
        except Exception:
            pass
    if sig:
        return os.path.join(xdg, "hypr", sig, ".socket2.sock")
    return None

def main():
    # Enforce single instance via non-blocking flock
    lock_file = open("/tmp/hypr-monitor-watcher.lock", "w")
    try:
        import fcntl
        fcntl.flock(lock_file, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except IOError:
        log("Another instance of monitor_watcher is already running. Exiting.")
        sys.exit(0)

    log("Starting Hyprland Monitor Hotplug Watcher...")

    # Initial safety check on daemon launch
    if not has_connected_external():
        log("No external monitor connected at launch.")
        try:
            if not is_laptop_only_active():
                log("Warning: monitors.lua has eDP-1 not active without external monitor! Restoring...")
                restore_laptop_display()
        except Exception as e:
            log(f"Initial check error: {e}")

    while True:
        sock_path = get_socket_path()
        if not sock_path or not os.path.exists(sock_path):
            time.sleep(1)
            continue

        try:
            client = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
            client.connect(sock_path)
            log(f"Connected to Hyprland event socket: {sock_path}")

            buffer = ""
            while True:
                data = client.recv(4096)
                if not data:
                    log("Socket closed by Hyprland, reconnecting...")
                    break
                buffer += data.decode("utf-8", errors="ignore")
                lines = buffer.split("\n")
                buffer = lines.pop()

                for line in lines:
                    line = line.strip()
                    if not line:
                        continue

                    if line.startswith("monitorremoved>>") or line.startswith("monitorremovedv2>>"):
                        mon_name = line.split(">>", 1)[1].split(",")[0].strip()
                        log(f"Event: monitor removed ({mon_name})")
                        time.sleep(0.3)
                        if not has_connected_external():
                            restore_laptop_display()

                    elif line.startswith("monitoradded>>") or line.startswith("monitoraddedv2>>"):
                        mon_name = line.split(">>", 1)[1].split(",")[0].strip()
                        log(f"Event: monitor added ({mon_name})")
                        time.sleep(0.8)
                        if "HDMI" in mon_name or has_connected_external():
                            activate_external_display()

        except Exception as e:
            log(f"Socket error: {e}. Retrying in 2 seconds...")
            time.sleep(2)

if __name__ == "__main__":
    main()
