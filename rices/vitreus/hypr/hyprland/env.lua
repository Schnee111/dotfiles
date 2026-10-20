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

-- Locally built libs (libpam/awww/lz4 in ~/.local)
hl.env("LD_LIBRARY_PATH", home .. "/.local/lib:" .. home .. "/.local/lib64")

-- PATH hardening: GDM hands Hyprland PATH=/usr/local/bin:/usr/bin only, so the
-- bare ~/.local/bin commands this rice spawns (pleamar, rice-switch,
-- audio_output_toggle.sh, battery_limit_toggle.sh, power_profile_toggle.sh)
-- fail silently. Prepend the user bin dir for every spawned command.
local path = os.getenv("PATH") or "/usr/local/bin:/usr/bin:/bin"
-- match whole PATH components so /opt/x/home/.../.local/bin-extra does not count
if not (":" .. path .. ":"):find(":" .. home .. "/.local/bin:", 1, true) then
    hl.env("PATH", home .. "/.local/bin:" .. path)
end
