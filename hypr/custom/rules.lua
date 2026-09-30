-- Custom rules for Rofi Launcher
hl.layer_rule({ match = { namespace = "rofi" }, blur = true })
hl.layer_rule({ match = { namespace = "rofi" }, ignore_alpha = 0.5 })
hl.window_rule({ match = { class = "^(Rofi|rofi)$" }, float = true })
hl.window_rule({ match = { class = "^(Rofi|rofi)$" }, center = true })

-- Application Workspace Rules
-- Workspace 2: Terminals
hl.window_rule({ match = { class = "^(kitty-fastfetch)$" }, workspace = "2 silent" })
hl.window_rule({ match = { class = "^(kitty-btop)$" }, workspace = "2 silent" })
hl.window_rule({ match = { class = "^(kitty-main)$" }, workspace = "2 silent" })
hl.window_rule({ match = { class = "^(kitty)$" }, workspace = "2" })

-- Workspace 3: Hermes Desktop
hl.window_rule({ match = { class = "^(Hermes|com\\.nousresearch\\.hermes)$" }, workspace = "3 silent" })

-- Workspace 4: Google Chrome
hl.window_rule({ match = { class = "^(google-chrome)$" }, workspace = "4 silent" })

-- osu! (free workspace, allow tearing for low latency & disable compositor blur)
hl.window_rule({ match = { class = "^(osu!\\.exe)$" }, immediate = true })
hl.window_rule({ match = { class = "^(osu!\\.exe)$" }, no_blur = true })

-- Workspace 6: Pinterest PWA, Firefox, and Ptyxis btop
hl.window_rule({ match = { class = "^(chrome-.*fbibgohghoobeeljoejfdmdhgoadhjbc.*)$" }, workspace = "6 silent" })
hl.window_rule({ match = { class = "^(org.mozilla.firefox)$" }, workspace = "6 silent" })
hl.window_rule({ match = { class = "^(org.gnome.Ptyxis)$", title = ".*btop-ws6.*" }, workspace = "6 silent" })

-- Workspace 7: WhatsApp PWA & Telegram Desktop
hl.window_rule({ match = { class = "^(whatsapp-app)$" }, workspace = "7 silent" })
hl.window_rule({ match = { class = "^(org\\.telegram\\.desktop.*|TelegramDesktop)$" }, workspace = "7 silent" })

-- Workspace 8: Discord, Kitty, and Spotify
hl.window_rule({ match = { class = "^(discord)$" }, workspace = "8 silent" })
hl.window_rule({ match = { class = "^(discord)$" }, no_blur = false })
hl.window_rule({ match = { class = "^(kitty-ws8)$" }, workspace = "8 silent" })
hl.window_rule({ match = { class = "^(spotify)$" }, workspace = "8 silent" })
