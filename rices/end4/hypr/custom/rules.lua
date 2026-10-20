-- Dynamic Opacity State Check (Toggled via SUPER + ALT + O)
local is_solid = is_file_exists(HOME .. "/.config/hypr/custom/.solid_mode")
local term_opacity = is_solid and "1.0 override 1.0 override" or "1.0 override 0.80 override"
local app_opacity  = is_solid and "1.0 override 1.0 override" or "0.72 override 0.62 override"

-- Custom rules for Rofi Launcher
hl.layer_rule({ match = { namespace = "rofi" }, blur = true })
hl.layer_rule({ match = { namespace = "rofi" }, ignore_alpha = 0.5 })
hl.window_rule({ match = { class = "^(Rofi|rofi)$" }, float = true })
hl.window_rule({ match = { class = "^(Rofi|rofi)$" }, center = true })

-- Global Window Blur Override (allow blur for all windows by default in glass mode)
hl.window_rule({ match = { class = ".*" }, no_blur = is_solid })

-- NOTE: No `workspace` window rules here on purpose.
-- Workspace placement happens ONLY at login via autostart.sh using
-- `hyprctl dispatch exec "[workspace N silent] <cmd>"`,
-- so manually opened apps follow the active workspace.

-- Terminals (visual only: active 1.0 keeps glyphs 100% solid & razor-sharp; inactive 0.80 smoothly fades out; no_dim prevents darkening)
hl.window_rule({ match = { class = "^(kitty.*)$" }, opacity = term_opacity })
hl.window_rule({ match = { class = "^(kitty.*)$" }, no_blur = is_solid })
hl.window_rule({ match = { class = "^(kitty.*)$" }, no_dim = true })
hl.window_rule({ match = { class = "^(org\\.gnome\\.Ptyxis)$" }, opacity = term_opacity })
hl.window_rule({ match = { class = "^(org\\.gnome\\.Ptyxis)$" }, no_blur = is_solid })
hl.window_rule({ match = { class = "^(org\\.gnome\\.Ptyxis)$" }, no_dim = true })

-- Google Chrome (visual only)
hl.window_rule({ match = { class = "^(google-chrome)$" }, no_blur = false })

-- osu! (free workspace, allow tearing for low latency & disable compositor blur)
hl.window_rule({ match = { class = "^(osu!\\.exe)$" }, immediate = true })
hl.window_rule({ match = { class = "^(osu!\\.exe)$" }, no_blur = true })
hl.window_rule({ match = { class = "^(osu!\\.exe)$" }, opacity = "1.0 override 1.0 override" })

-- Firefox / Pinterest PWA (visual only)
hl.window_rule({ match = { class = "^(firefox.*|org\\.mozilla\\.firefox)$" }, no_blur = false })

-- Dedicated App Workspaces (guarantees slow-starting Flatpaks / PWAs land cleanly without race conditions)
hl.window_rule({ match = { class = "^(whatsapp-app)$" }, workspace = "7 silent" })
hl.window_rule({ match = { class = "^(whatsapp-app)$" }, no_blur = false })
hl.window_rule({ match = { class = "^(org\\.telegram\\.desktop.*)$" }, workspace = "7 silent" })

hl.window_rule({ match = { class = "^(discord)$" }, workspace = "9 silent" })
hl.window_rule({ match = { class = "^(discord)$" }, no_blur = false })
hl.window_rule({ match = { class = "^(spotify)$" }, workspace = "9 silent" })
hl.window_rule({ match = { class = "^(spotify)$" }, no_blur = false })
hl.window_rule({ match = { class = "^(spotify)$" }, no_initial_focus = true })
hl.window_rule({ match = { class = "^(kitty-ws9)$" }, workspace = "9 silent" })

-- xdg-activation guards: misc:focus_on_activate is enabled globally (custom/general.lua)
-- so browsers focus when you open a link, but these background apps must never
-- steal focus when they request activation.
hl.window_rule({ match = { class = "^(spotify)$" }, suppress_event = "activatefocus" })
hl.window_rule({ match = { class = "^(discord)$" }, suppress_event = "activatefocus" })
hl.window_rule({ match = { class = "^(org\\.telegram\\.desktop.*)$" }, suppress_event = "activatefocus" })
hl.window_rule({ match = { class = "^(whatsapp-app)$" }, suppress_event = "activatefocus" })

-- Drawing tablet (OpenTabletDriver 1:1 dynamic monitor binding)
local is_external = false
for _, card in ipairs({"card1", "card0"}) do
    local f = io.open("/sys/class/drm/" .. card .. "-HDMI-A-1/status", "r")
    if f then
        local st = f:read("*l")
        f:close()
        if st == "connected" then is_external = true break end
    end
end

hl.device({
    name = "opentabletdriver-virtual-artist-tablet",
    output = is_external and "HDMI-A-1" or "eDP-1",
})

-- Unload module so it re-evaluates on every hyprctl reload
package.loaded["custom.rules"] = nil
