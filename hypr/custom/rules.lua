-- Dynamic Opacity State Check (Toggled via SUPER + ALT + O)
local is_solid = is_file_exists(HOME .. "/.config/hypr/custom/.solid_mode")
local term_opacity = is_solid and "1.0 override 1.0 override" or "0.85 override 0.75 override"
local app_opacity  = is_solid and "1.0 override 1.0 override" or "0.80 override 0.70 override"

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

-- Terminals (visual only)
hl.window_rule({ match = { class = "^(kitty.*)$" }, opacity = term_opacity })
hl.window_rule({ match = { class = "^(kitty.*)$" }, no_blur = false })
hl.window_rule({ match = { class = "^(org\\.gnome\\.Ptyxis)$" }, opacity = term_opacity })
hl.window_rule({ match = { class = "^(org\\.gnome\\.Ptyxis)$" }, no_blur = false })

-- Google Chrome (visual only)
hl.window_rule({ match = { class = "^(google-chrome)$" }, no_blur = false })

-- osu! (free workspace, allow tearing for low latency & disable compositor blur)
hl.window_rule({ match = { class = "^(osu!\\.exe)$" }, immediate = true })
hl.window_rule({ match = { class = "^(osu!\\.exe)$" }, no_blur = true })
hl.window_rule({ match = { class = "^(osu!\\.exe)$" }, opacity = "1.0 override 1.0 override" })

-- Firefox / Pinterest PWA (visual only)
hl.window_rule({ match = { class = "^(firefox.*|org\\.mozilla\\.firefox)$" }, no_blur = false })

-- WhatsApp PWA (visual only)
hl.window_rule({ match = { class = "^(whatsapp-app)$" }, no_blur = false })

-- Discord (visual only)
hl.window_rule({ match = { class = "^(discord)$" }, no_blur = false })

-- Unload module so it re-evaluates on every hyprctl reload
package.loaded["custom.rules"] = nil
