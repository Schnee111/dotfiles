local vars = require("variables")
local home = os.getenv("HOME") or "/home/schnee"

-- Themes
hl.env("QT_QPA_PLATFORMTHEME", "qtengine")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("XCURSOR_THEME", vars.cursorTheme)
hl.env("XCURSOR_SIZE", vars.cursorSize)

-- Toolkit backends
hl.env("GDK_BACKEND", "wayland,x11")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("SDL_VIDEODRIVER", "wayland,x11,windows")
hl.env("CLUTTER_BACKEND", "wayland")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

-- XDG specifications
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

-- Others
hl.env("_JAVA_AWT_WM_NONREPARENTING", "1")

-- Locally built Caelestia QML plugins + audio libs (cava/fftw in ~/.local)
hl.env("QML2_IMPORT_PATH", home .. "/.local/lib64/qt6/qml")
hl.env("LD_LIBRARY_PATH", home .. "/.local/lib:" .. home .. "/.local/lib64")

-- PATH hardening: when GDM starts Hyprland the inherited PATH is only
-- /usr/local/bin:/usr/bin, so every bare command the rice spawns from
-- ~/.local/bin (caelestia, caelestia-display-switch.sh, play_sound.sh, ...)
-- fails silently -- including `caelestia shell -d`, which leaves no shell at all.
local path = os.getenv("PATH") or "/usr/local/bin:/usr/bin:/bin"
if not path:find(home .. "/.local/bin", 1, true) then
    hl.env("PATH", home .. "/.local/bin:" .. path)
end
