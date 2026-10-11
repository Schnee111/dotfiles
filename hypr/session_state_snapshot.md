# Schnee Desktop Session State & Workspace Architecture Snapshot
Captured: 2026-10-11
Display: Xiaomi Mi Monitor (HDMI-A-1, 1920x1080 @ 200Hz, Scale: 1.0, Reserved Bar: 45px top)
Base Gaps: gaps_in = 6, gaps_out = 8 (Windows start at y = 53, max width = 1904, max height = 1019)

---

## Workspace Layouts & Geometry

### Workspace 2: System Monitor & Main Terminal
- **kitty-fastfetch** (top-left)
  - Pos: [8, 53] | Size: [951, 427]
  - Font: JetBrains Mono Nerd Font @ 11.0 (cols: 101, lines: 19)
  - Command: `kitty --class kitty-fastfetch fish -c 'fastfetch; exec fish'`
- **kitty-btop** (bottom-left)
  - Pos: [8, 486] | Size: [951, 586]
  - Font: JetBrains Mono Nerd Font @ 10.0 (cols: 113, lines: 30)
  - Command: `kitty --class kitty-btop -o font_size=10.0 -e btop`
  - Btop Theme: "TTY", theme_background = true, truecolor = true
- **kitty-main** (right, full height)
  - Pos: [965, 53] | Size: [947, 1019]
  - Font: JetBrains Mono Nerd Font @ 11.0 (cols: 100, lines: 49)
  - Command: `kitty --class kitty-main`

### Workspace 3: Hermes Desktop
- **Hermes Desktop Window 1** (left)
  - Pos: [8, 53] | Size: [1100, 1019]
  - Class: `com.nousresearch.hermes`
- **Hermes Desktop Window 2** (right)
  - Pos: [1114, 53] | Size: [798, 1019]
  - Class: `com.nousresearch.hermes`

### Workspace 4: Primary Browser
- **Google Chrome** (full screen)
  - Pos: [8, 53] | Size: [1904, 1019]
  - Class: `google-chrome`
  - Flags: Wayland native (`--ozone-platform-hint=wayland`, `--enable-features=TouchpadOverscrollHistoryNavigation`)

### Workspace 5: Secondary Browser
- **Mozilla Firefox** (full screen)
  - Pos: [8, 53] | Size: [1904, 1019]
  - Class: `org.mozilla.firefox`

### Workspace 7: Messaging
- **WhatsApp Web PWA** (left)
  - Pos: [8, 53] | Size: [1258, 1019] (66% width)
  - Class: `whatsapp-app`
  - Command: `firefox --name whatsapp-app --new-instance -P whatsapp-pwa https://web.whatsapp.com`
- **Telegram Desktop** (right)
  - Pos: [1272, 53] | Size: [640, 1019] (34% width)
  - Class: `org.telegram.desktop._005eda12d41aae68f7ba873817da6cea`
  - Command: `/home/schnee/.local/bin/telegram`

### Workspace 8: Development Tiling (Dev 3-Split)
- **kitty-main (hermes CLI)** (left, full height)
  - Pos: [8, 53] | Size: [949, 1019]
  - Class: `kitty-main` (title: `hermes ~`)
  - Font: 11.0 (cols: 100, lines: 49)
- **kitty (agy CLI)** (top-right)
  - Pos: [963, 53] | Size: [949, 507]
  - Class: `kitty` (title: `agy ~`)
  - Command: `agy`
  - Font: 11.0 (cols: 100, lines: 23)
- **kitty (btop CLI)** (bottom-right)
  - Pos: [963, 566] | Size: [949, 506]
  - Class: `kitty` (title: `btop ~`)
  - Command: `btop`
  - Font: 10.0 (cols: 113, lines: 26)
  - Btop Theme: "TTY"

### Workspace 9: Social & Entertainment (Social 3-Split)
- **Discord** (left, full height)
  - Pos: [8, 53] | Size: [1075, 1019]
  - Class: `discord` (Flatpak: `com.discordapp.Discord`)
  - Theme: Vencord Frosted Glass Mac
- **Spotify** (top-right)
  - Pos: [1089, 53] | Size: [823, 625]
  - Class: `spotify` (Flatpak: `com.spotify.Client`)
- **kitty-ws9 (fastfetch)** (bottom-right)
  - Pos: [1089, 684] | Size: [823, 388]
  - Class: `kitty-ws9`
  - Font: 9.0
  - Command: `kitty --class kitty-ws9 -o font_size=9.0 fish -c 'fastfetch; exec fish'`

### Special Workspace (`special:special`):
- **Dolphin File Manager**
  - Pos: [31, 76] | Size: [1858, 973]
  - Class: `org.kde.dolphin`
