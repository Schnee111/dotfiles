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

-- Application Workspace Rules
-- Workspace 2: Terminals
hl.window_rule({ match = { class = "^(kitty-fastfetch)$" }, workspace = "2 silent" })
hl.window_rule({ match = { class = "^(kitty-btop)$" }, workspace = "2 silent" })
hl.window_rule({ match = { class = "^(kitty-main)$" }, workspace = "2 silent" })
hl.window_rule({ match = { class = "^(kitty)$" }, workspace = "2" })
hl.window_rule({ match = { class = "^(kitty.*)$" }, opacity = term_opacity })
hl.window_rule({ match = { class = "^(kitty.*)$" }, no_blur = false })
hl.window_rule({ match = { class = "^(org\\.gnome\\.Ptyxis)$" }, opacity = term_opacity })
hl.window_rule({ match = { class = "^(org\\.gnome\\.Ptyxis)$" }, no_blur = false })

-- Workspace 3: Hermes Desktop
hl.window_rule({ match = { class = "^(Hermes|com\\.nousresearch\\.hermes)$" }, workspace = "3 silent" })

-- Workspace 4: Google Chrome
hl.window_rule({ match = { class = "^(google-chrome)$" }, workspace = "4 silent" })
hl.window_rule({ match = { class = "^(google-chrome)$" }, no_blur = false })

-- osu! (free workspace, allow tearing for low latency & disable compositor blur)
hl.window_rule({ match = { class = "^(osu!\\.exe)$" }, immediate = true })
hl.window_rule({ match = { class = "^(osu!\\.exe)$" }, no_blur = true })
hl.window_rule({ match = { class = "^(osu!\\.exe)$" }, opacity = "1.0 override 1.0 override" })

-- Workspace 6: Pinterest PWA, Firefox, and Ptyxis btop
hl.window_rule({ match = { class = "^(chrome-.*fbibgohghoobeeljoejfdmdhgoadhjbc.*)$" }, workspace = "6 silent" })
hl.window_rule({ match = { class = "^(firefox.*|org\\.mozilla\\.firefox)$" }, workspace = "6 silent" })
hl.window_rule({ match = { class = "^(firefox.*|org\\.mozilla\\.firefox)$" }, no_blur = false })
hl.window_rule({ match = { class = "^(org\\.gnome\\.Ptyxis)$", title = ".*btop-ws6.*" }, workspace = "6 silent" })

-- Workspace 7: WhatsApp PWA & Telegram Desktop
hl.window_rule({ match = { class = "^(whatsapp-app)$" }, workspace = "7 silent" })
hl.window_rule({ match = { class = "^(whatsapp-app)$" }, no_blur = false })
hl.window_rule({ match = { class = "^(org\\.telegram\\.desktop.*|TelegramDesktop)$" }, workspace = "7 silent" })

-- Unload module so it re-evaluates on every hyprctl reload
package.loaded["custom.rules"] = nil

-- Workspace 8: Discord, Kitty, and Spotify
hl.window_rule({ match = { class = "^(discord)$" }, workspace = "8 silent" })
hl.window_rule({ match = { class = "^(discord)$" }, no_blur = false })
hl.window_rule({ match = { class = "^(kitty-ws8)$" }, workspace = "8 silent" })
hl.window_rule({ match = { class = "^(spotify)$" }, workspace = "8 silent" })
