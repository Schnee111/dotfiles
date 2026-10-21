-- Ensure monitors hardware safeguard is loaded
pcall(require, "custom.monitors_safeguard")

-- Autostart is executed by Quickshell upon session unlock.
-- If Quickshell is not running, fallback executes after 10 seconds.
hl.on("hyprland.start", function ()
    hl.exec_cmd("systemctl --user start hyprland-monitor-watcher.service")
    hl.exec_cmd("bash -c 'sleep 10 && ! pgrep -x qs >/dev/null && test ! -f /tmp/hypr-autostart-${HYPRLAND_INSTANCE_SIGNATURE:-default}.lock && test -x $HOME/.config/hypr/scripts/autostart.sh && $HOME/.config/hypr/scripts/autostart.sh'")
end)
