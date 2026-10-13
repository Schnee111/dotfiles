local mainMod = "SUPER"
local terminal = "kitty"
local fileManager = "nautilus"

-- ## Applications

-- # Open Terminal
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal))
-- # Open Floating Terminal
hl.bind(mainMod .. " + SHIFT + Return", hl.dsp.exec_cmd("kitty --class kitty-floating"))
-- # Open File Manager
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
-- # Open Browser
hl.bind(
	mainMod .. " + B",
	hl.dsp.exec_cmd(
		"if command -v firefox; then firefox; elif command -v brave; then brave; elif command -v chromium; then chromium; else google-chrome-stable; fi"
	)
)

-- ## Window Management

-- # Close Active Window
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
-- # Exit Hyprland
hl.bind(mainMod .. " + SHIFT + M", hl.dsp.exit())
-- # Lock Screen (idempotent, single locker)
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("sh -c 'hyprctl locked | grep -q true || socat - UNIX-CONNECT:/tmp/quickshell_lockScreen'"))
-- # Toggle Floating Mode
hl.bind(mainMod .. " + W", hl.dsp.window.float({ action = "toggle" }))
-- # Toggle Maximize Window
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))
-- # Toggle True Fullscreen
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
-- # Pseudo Tiling Layout
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
-- # Toggle Split Direction
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))
-- # Center Floating Window
hl.bind(mainMod .. " + C", hl.dsp.window.center())
-- # Pin Window on All Workspaces
hl.bind(mainMod .. " + SHIFT + P", hl.dsp.window.pin())
-- # Minimize Window to Scratchpad
hl.bind(mainMod .. " + N", hl.dsp.window.move({ workspace = "special:minimized", silent = true }))
-- # Restore Minimized Windows
hl.bind(mainMod .. " + SHIFT + N", hl.dsp.workspace.toggle_special("minimized"))

-- ## Tools & Global Controls

-- # Pick Color
hl.bind(mainMod .. " + SHIFT + C", hl.dsp.exec_cmd("hyprpicker -a"))
-- # Rofi Launchpad / Keyboard Layout Switch
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd("rofi -show drun -theme ~/.config/rofi/launchpad.rasi"))
-- # Restart Quickshell (minflair profile)
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd("killall qs 2>/dev/null; qs -c minflair"))

-- # Rice Switcher (Global)
hl.bind(mainMod .. " + SHIFT + D", hl.dsp.exec_cmd("rice-switch"))

-- # Hardware Toggles (Global)
hl.bind("SUPER + ALT + V", hl.dsp.exec_cmd("audio_output_toggle.sh"))
hl.bind("SUPER + ALT + B", hl.dsp.exec_cmd("battery_limit_toggle.sh"))
hl.bind("SUPER + ALT + P", hl.dsp.exec_cmd("power_profile_toggle.sh"))
hl.bind("XF86Launch1", hl.dsp.exec_cmd("power_profile_toggle.sh"))
hl.bind("XF86Launch4", hl.dsp.exec_cmd("power_profile_toggle.sh"))

-- ## Volume

-- # Raise Volume
hl.bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/volume.sh up"),
	{ repeating = true, locked = true }
)
-- # Lower Volume
hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/volume.sh down"),
	{ repeating = true, locked = true }
)
-- # Mute Speaker
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/volume.sh mute"), { locked = true })
-- # Mute Microphone
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/volume.sh mic-mute"), { locked = true })

-- ## Brightness

-- # Increase Brightness
hl.bind(
	"XF86MonBrightnessUp",
	hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/brightness.sh up"),
	{ repeating = true, locked = true }
)
-- # Decrease Brightness
hl.bind(
	"XF86MonBrightnessDown",
	hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/brightness.sh down"),
	{ repeating = true, locked = true }
)

-- ## Media Player

-- # Play / Pause
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/media_player.sh play-pause"), { locked = true })
-- # Next Track
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/media_player.sh next"), { locked = true })
-- # Previous Track
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/media_player.sh prev"), { locked = true })
-- # Stop
hl.bind("XF86AudioStop", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/media_player.sh stop"), { locked = true })

-- ## Quickshell Widgets

-- # Toggle App Launcher
hl.bind(mainMod .. " + A", hl.dsp.exec_cmd("socat - UNIX-CONNECT:/tmp/quickshell_launcher"))
-- # Toggle Control Center
hl.bind("CTRL + ALT + S", hl.dsp.exec_cmd("socat - UNIX-CONNECT:/tmp/quickshell_controlCenter"))
-- # Toggle Power Menu
hl.bind("CTRL + ALT + X", hl.dsp.exec_cmd("socat - UNIX-CONNECT:/tmp/quickshell_powerMenu"))
-- # Toggle Clipboard History
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd("socat - UNIX-CONNECT:/tmp/quickshell_clipboard"))
-- # Toggle Wallpaper Selector
hl.bind("CTRL + ALT + W", hl.dsp.exec_cmd("socat - UNIX-CONNECT:/tmp/quickshell_wallpaper"))
-- # Toggle Screenshot
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd("socat - UNIX-CONNECT:/tmp/quickshell_screenshot"))
-- # Toggle Dashboard
hl.bind("CTRL + ALT + D", hl.dsp.exec_cmd("socat - UNIX-CONNECT:/tmp/quickshell_dashboard"))
-- # Toggle Music Popup
hl.bind("CTRL + ALT + M", hl.dsp.exec_cmd("socat - UNIX-CONNECT:/tmp/quickshell_music"))
-- # Toggle Notifications Center
hl.bind("CTRL + ALT + N", hl.dsp.exec_cmd("socat - UNIX-CONNECT:/tmp/quickshell_notificationsCenter"))

-- ## Quickshell Apps

-- # Toggle Settings
hl.bind(mainMod .. " + S", hl.dsp.exec_cmd("socat - UNIX-CONNECT:/tmp/quickshell_minflair_settings"))
-- # Toggle Package Manager
hl.bind("CTRL + ALT + P", hl.dsp.exec_cmd("socat - UNIX-CONNECT:/tmp/quickshell_packagemanager"))
-- # Toggle Keybinds Cheat Sheet
hl.bind(mainMod .. " + K", hl.dsp.exec_cmd("socat - UNIX-CONNECT:/tmp/quickshell_minflair_keybinds"))

-- ## Window Groups

-- # Create / Dissolve Group
hl.bind(mainMod .. " + G", hl.dsp.group.toggle())
-- # Cycle Group Windows
hl.bind(mainMod .. " + Tab", hl.dsp.group.next())
-- # Lock / Unlock Group
hl.bind(mainMod .. " + SHIFT + G", hl.dsp.group.lock("toggle"))

-- ## Navigation

-- # Move Focus ←→↑↓
hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "l" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "r" }))
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "u" }))
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "d" }))

-- # Move Window Position ←→↑↓
hl.bind(mainMod .. " + SHIFT + left", hl.dsp.window.move({ direction = "l" }))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.move({ direction = "r" }))
hl.bind(mainMod .. " + SHIFT + up", hl.dsp.window.move({ direction = "u" }))
hl.bind(mainMod .. " + SHIFT + down", hl.dsp.window.move({ direction = "d" }))

-- # Resize Active Window ←→↑↓
hl.bind(mainMod .. " + ALT + right", hl.dsp.window.resize({ x = 10, y = 0 }), { repeating = true })
hl.bind(mainMod .. " + ALT + left", hl.dsp.window.resize({ x = -10, y = 0 }), { repeating = true })
hl.bind(mainMod .. " + ALT + up", hl.dsp.window.resize({ x = 0, y = -10 }), { repeating = true })
hl.bind(mainMod .. " + ALT + down", hl.dsp.window.resize({ x = 0, y = 10 }), { repeating = true })

-- ## Workspaces

-- # Switch to Workspace 1-10
for i = 1, 10 do
	local key = tostring(i % 10)
	hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
	hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- # Scroll Through Existing Workspaces
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- # Move/Resize Windows with Mouse
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.drag({ resize = true }), { mouse = true })
