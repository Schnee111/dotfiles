local home_dir = os.getenv("HOME")

-- Wayland
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

-- Applications
-- Strip our own flatpak paths first so repeated reloads / rice switches
-- don't stack duplicates onto XDG_DATA_DIRS.
local xdg_data_dirs_old = os.getenv("XDG_DATA_DIRS") or ""
xdg_data_dirs_old = xdg_data_dirs_old:gsub(home_dir .. "/%.local/share/flatpak/exports/share:?", ""):gsub("/var/lib/flatpak/exports/share:?", ""):gsub("/usr/local/share:?", ""):gsub("/usr/share:?", ""):gsub("^:+", ""):gsub(":+$", ""):gsub("::+", ":")
local xdg_suffix = xdg_data_dirs_old ~= "" and (":" .. xdg_data_dirs_old) or ""
hl.env("XDG_DATA_DIRS", home_dir .. "/.local/share/flatpak/exports/share:/var/lib/flatpak/exports/share:/usr/local/share:/usr/share" .. xdg_suffix)

-- Themes
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "kde")
hl.env("XDG_MENU_PREFIX", "plasma-")

-- Virtual environment
hl.env("ILLOGICAL_IMPULSE_VIRTUAL_ENV", home_dir .. "/.local/state/quickshell/.venv")
