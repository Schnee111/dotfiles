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

def migrate_workspaces(target_monitor):
    """Migrates all active workspaces to the target monitor."""
    try:
        cmd = f"for _, ws in ipairs(hl.get_workspaces()) do if not ws.monitor or ws.monitor.name ~= '{target_monitor}' then hl.dispatch(hl.dsp.workspace.move({{ workspace = ws.id, monitor = '{target_monitor}' }})) end end"
        subprocess.run(["hyprctl", "repl", cmd], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=2)
    except Exception as e:
        log(f"Error migrating workspaces: {e}")

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

def restore_laptop_display():
    """Switches to Laptop Only mode (eDP-1 @ 2880x1800@90, scale 1.5)."""
    global last_action_time
    if time.time() - last_action_time < 1.5:
        return
    last_action_time = time.time()

    log("Physical disconnect: Restoring laptop screen (eDP-1)...")

    # 1. Enable eDP-1 first
    subprocess.run([
        "hyprctl", "eval",
        'hl.monitor({ output = "eDP-1", mode = "2880x1800@90", position = "0x0", scale = 1.5, disabled = false })'
    ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    time.sleep(0.2)

    # 2. Migrate workspaces to eDP-1
    migrate_workspaces("eDP-1")

    # 3. Disable HDMI-A-1
    subprocess.run([
        "hyprctl", "eval",
        'hl.monitor({ output = "HDMI-A-1", disabled = true })'
    ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    # 4. Update monitors.lua
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
    if time.time() - last_action_time < 1.5:
        return
    last_action_time = time.time()

    log("Physical connect: Docking to External Only (HDMI-A-1)...")

    # 1. Enable HDMI-A-1 first
    subprocess.run([
        "hyprctl", "eval",
        'hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@200", position = "0x0", scale = 1, disabled = false })'
    ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    time.sleep(0.2)

    # 2. Migrate workspaces to HDMI-A-1
    migrate_workspaces("HDMI-A-1")

    # 3. Disable eDP-1
    subprocess.run([
        "hyprctl", "eval",
        'hl.monitor({ output = "eDP-1", disabled = true })'
    ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    # 4. Update monitors.lua
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
    lock_file = open("/tmp/hypr-monitor-watcher.lock", "w")
    try:
        import fcntl
        fcntl.flock(lock_file, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except IOError:
        log("Another instance of monitor_watcher is already running. Exiting.")
        sys.exit(0)

    log("Starting Hyprland Monitor Hotplug Watcher...")

    # Initialize physical DRM connection state
    last_drm_connected = has_connected_external()
    log(f"Initial physical DRM external connected: {last_drm_connected}")

    # Initial safety check: if no external monitor physically connected,
    # make sure eDP-1 is never left disabled
    if not last_drm_connected:
        try:
            if os.path.exists(MONITORS_LUA):
                with open(MONITORS_LUA, "r") as f:
                    c = f.read()
                if 'output = "eDP-1"' in c and "disabled = true" in c.split('output = "eDP-1"')[1].split("hl.monitor")[0]:
                    log("Safety check: eDP-1 disabled without external monitor! Restoring...")
                    restore_laptop_display()
        except Exception as e:
            log(f"Initial safety check error: {e}")

    while True:
        sock_path = get_socket_path()
        if not sock_path or not os.path.exists(sock_path):
            current = has_connected_external()
            if current != last_drm_connected:
                log(f"DRM state change detected via poll: {last_drm_connected} -> {current}")
                if current:
                    activate_external_display()
                else:
                    restore_laptop_display()
                last_drm_connected = current
            time.sleep(1)
            continue

        try:
            client = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
            client.connect(sock_path)
            log(f"Connected to Hyprland event socket: {sock_path}")
            client.settimeout(2.0)

            buffer = ""
            while True:
                try:
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

                        # Monitor event in Hyprland
                        if line.startswith("monitoradded") or line.startswith("monitorremoved"):
                            time.sleep(0.3) # Debounce sysfs update
                            current = has_connected_external()
                            if current != last_drm_connected:
                                log(f"Hardware hotplug event ({line}): {last_drm_connected} -> {current}")
                                if current:
                                    activate_external_display()
                                else:
                                    restore_laptop_display()
                                last_drm_connected = current
                            else:
                                log(f"Monitor event ({line}) received, but physical DRM state unchanged ({current}). Ignoring software switch.")

                except socket.timeout:
                    current = has_connected_external()
                    if current != last_drm_connected:
                        log(f"Hardware hotplug detected via heartbeat: {last_drm_connected} -> {current}")
                        if current:
                            activate_external_display()
                        else:
                            restore_laptop_display()
                        last_drm_connected = current

        except Exception as e:
            log(f"Socket error: {e}. Retrying in 2 seconds...")
            time.sleep(2)

if __name__ == "__main__":
    main()
