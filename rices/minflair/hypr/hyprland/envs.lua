hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("XCURSOR_THEME", "Bibata-Modern-Classic")
hl.env("HYPRCURSOR_THEME", "Bibata-Modern-Classic")
hl.env("QT_QPA_PLATFORMTHEME", "qt5ct")

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

-- PATH hardening: GDM hands Hyprland PATH=/usr/local/bin:/usr/bin only, so the
-- bare ~/.local/bin commands this rice spawns (awww-daemon, rice-switch,
-- audio_output_toggle.sh, battery_limit_toggle.sh, power_profile_toggle.sh)
-- fail silently. Prepend the user bin dir for every spawned command.
local home = os.getenv("HOME") or "/home/schnee"
local path = os.getenv("PATH") or "/usr/local/bin:/usr/bin:/bin"
-- match whole PATH components so /opt/x/home/.../.local/bin-extra does not count
if not (":" .. path .. ":"):find(":" .. home .. "/.local/bin:", 1, true) then
    hl.env("PATH", home .. "/.local/bin:" .. path)
end
