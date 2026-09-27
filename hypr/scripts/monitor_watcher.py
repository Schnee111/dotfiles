#!/usr/bin/env python3
import glob
import os
import select
import subprocess
import sys
import threading
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

def restore_laptop_display():
    """Switches to Laptop Only mode (eDP-1 @ 2880x1800@90, scale 1.5)."""
    global last_action_time
    if time.time() - last_action_time < 2.0:
        return
    last_action_time = time.time()

    log("Physical disconnect: Restoring laptop screen (eDP-1)...")

    # Cable is physically detached, so eDP-1 is the only valid hardware display
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
        subprocess.run(["hyprctl", "reload"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception as e:
        log(f"Failed to apply laptop display: {e}")

    time.sleep(0.5)
    ensure_quickshell()

    subprocess.Popen([
        "notify-send", "-t", "2500", "-a", "Display", "Display Output",
        "External monitor disconnected. Laptop display restored.",
        "-i", "computer"
    ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

def activate_external_display():
    """Switches to External Monitor Only (HDMI-A-1 @ 1920x1080@200, scale 1)."""
    global last_action_time
    if time.time() - last_action_time < 2.0:
        return
    last_action_time = time.time()

    log("Physical connect: Docking to External Only (HDMI-A-1)...")

    # Step 1: Enable target alongside current display so layout destination exists
    stage1 = """hl.monitor({
    output = "HDMI-A-1",
    mode = "1920x1080@200",
    position = "0x0",
    scale = 1,
})

hl.monitor({
    output = "eDP-1",
    mode = "2880x1800@90",
    position = "1920x0",
    scale = 1.5,
})
"""
    try:
        with open(MONITORS_LUA, "w") as f:
            f.write(stage1)
        subprocess.run(["hyprctl", "reload"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception as e:
        log(f"Stage 1 error: {e}")

    time.sleep(0.5)

    # Step 2: Disable laptop display. Hyprland detects monitor removal and migrates all workspaces
    stage2 = """hl.monitor({
    output = "HDMI-A-1",
    mode = "1920x1080@200",
    position = "0x0",
    scale = 1,
})

hl.monitor({
    output = "eDP-1",
    disabled = true,
})
"""
    try:
        with open(MONITORS_LUA, "w") as f:
            f.write(stage2)
        subprocess.run(["hyprctl", "reload"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception as e:
        log(f"Stage 2 error: {e}")

    time.sleep(0.5)
    ensure_quickshell()

    subprocess.Popen([
        "notify-send", "-t", "2500", "-a", "Display", "Display Output",
        "External monitor connected. Switched to External Only (1080p @ 200Hz).",
        "-i", "video-display"
    ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

def watch_platform_profile():
    """Monitors ACPI platform profile sysfs changes (Fn+F hotkey or script toggles)."""
    profile_path = "/sys/firmware/acpi/platform_profile"
    if not os.path.exists(profile_path):
        return

    try:
        fd = os.open(profile_path, os.O_RDONLY)
        poller = select.poll()
        poller.register(fd, select.POLLPRI | select.POLLERR)

        # Initial read to prime sysfs poll
        last_profile = os.read(fd, 32).decode().strip()
        log(f"Platform profile watcher active. Current mode: {last_profile}")

        icons = {
            "quiet": "power-profile-power-saver-symbolic",
            "balanced": "power-profile-balanced-symbolic",
            "performance": "power-profile-performance-symbolic",
        }
        titles = {
            "quiet": "Power Mode: Quiet",
            "balanced": "Power Mode: Balanced",
            "performance": "Power Mode: Performance",
        }
        descs = {
            "quiet": "Whisper silent fans & power saving active.",
            "balanced": "Standard dynamic fan & performance scaling.",
            "performance": "Turbo cooling & maximum performance active.",
        }

        while True:
            events = poller.poll()
            if not events:
                continue

            os.lseek(fd, 0, os.SEEK_SET)
            new_profile = os.read(fd, 32).decode().strip()

            if new_profile != last_profile and new_profile in icons:
                last_profile = new_profile
                log(f"Platform profile changed: {new_profile}")
                subprocess.Popen([
                    "notify-send", "-a", "Power Profile",
                    "-i", icons[new_profile],
                    "-t", "2500",
                    titles[new_profile],
                    descs[new_profile]
                ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception as e:
        log(f"Platform profile watcher error: {e}")

def main():
    lock_file = open("/tmp/hypr-monitor-watcher.lock", "w")
    try:
        import fcntl
        fcntl.flock(lock_file, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except IOError:
        log("Another instance of monitor_watcher is already running. Exiting.")
        sys.exit(0)

    log("Starting Hyprland Kernel Uevent Monitor Watcher...")

    # Start ACPI platform profile watcher in background thread
    profile_thread = threading.Thread(target=watch_platform_profile, daemon=True)
    profile_thread.start()

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

    # Listen to hardware kernel uevents via udevadm
    while True:
        try:
            proc = subprocess.Popen(
                ["udevadm", "monitor", "--kernel", "--subsystem-match=drm"],
                stdout=subprocess.PIPE,
                stderr=subprocess.DEVNULL,
                text=True
            )
            assert proc.stdout is not None
            for line in proc.stdout:
                if "change" in line:
                    time.sleep(0.5)
                    current = has_connected_external()
                    # Double-check: if disconnected, wait 1.2s to confirm it's not a brief modeset blip
                    if not current:
                        time.sleep(1.2)
                        current = has_connected_external()

                    if current != last_drm_connected:
                        log(f"Confirmed hardware cable event: {last_drm_connected} -> {current}")
                        last_drm_connected = current
                        if current:
                            activate_external_display()
                        else:
                            restore_laptop_display()
        except Exception as e:
            log(f"udevadm monitor error: {e}. Falling back to 2s poll...")
            time.sleep(2)
            current = has_connected_external()
            if not current:
                time.sleep(1.2)
                current = has_connected_external()
            if current != last_drm_connected:
                log(f"Polling detected state change: {last_drm_connected} -> {current}")
                last_drm_connected = current
                if current:
                    activate_external_display()
                else:
                    restore_laptop_display()

if __name__ == "__main__":
    main()
