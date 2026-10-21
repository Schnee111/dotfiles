local vars = require("variables")
local home = os.getenv("HOME")

hl.on("hyprland.start", function()
    -- Keyring and auth
    hl.exec_cmd("gnome-keyring-daemon --start --components=secrets")
    hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")

    -- Clipboard history
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")

    -- Auto delete trash 30 days old
    hl.exec_cmd("trash-empty 30")

    -- Cursors
    hl.exec_cmd("hyprctl setcursor " .. vars.cursorTheme .. " " .. vars.cursorSize)
    hl.exec_cmd("gsettings set org.gnome.desktop.interface cursor-theme " .. vars.cursorTheme)
    hl.exec_cmd("gsettings set org.gnome.desktop.interface cursor-size " .. vars.cursorSize)

    -- Location provider and night light
    hl.exec_cmd("/usr/lib/geoclue-2.0/demos/agent")
    hl.exec_cmd("sleep 1 && gammastep")

    -- Forward bluetooth media commands to MPRIS
    hl.exec_cmd("mpris-proxy")

    -- Idle daemon (Vitreus Caffeine talks to it; guarded so no double-run)
    hl.exec_cmd("pgrep -x hypridle > /dev/null || hypridle")

    -- Brightness slider to DDC mirror: Vitreus writes the laptop backlight,
    -- this forwards it to the external monitor while eDP is off
    hl.exec_cmd("systemctl --user start vitreus-brightness-mirror.service")

    -- Re-apply the saved display layout when the HDMI panel is plugged or unplugged
    hl.exec_cmd("pgrep -f '[v]itreus-display-switch.sh --watch' > /dev/null || " .. home .. "/.local/bin/vitreus-display-switch.sh --watch")

    -- Start Vitreus shell under its keeper (restarts on crash, gives up after 5 quick deaths)
    -- NOTE: absolute paths, Hyprland exec PATH has no ~/.local/bin
    hl.exec_cmd("$HOME/.local/bin/vitreus-keep $HOME/.config/pleamar/shells/vitreus/vitreus.plm $HOME/.local/share/pleamar/vitreus/vitreus.log")
    hl.exec_cmd("$HOME/.local/bin/vitreus-keep $HOME/.config/pleamar/shells/vitreus/lockscreen/lockscreen.plm")
    hl.exec_cmd("$HOME/.local/bin/vitreus-keep $HOME/.config/pleamar/shells/vitreus/wptrans/wptrans.plm")
    hl.exec_cmd("$HOME/.local/bin/vitreus-keep $HOME/.config/pleamar/shells/vitreus/desktopclock/desktopclock.plm")
end)
