local mainMod = "SUPER"
local terminal = "kitty"
local files    = "nautilus"
local browser  = "firefox"

---- PROGRAMS ----
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + E",      hl.dsp.exec_cmd(files))
hl.bind(mainMod .. " + B",      hl.dsp.exec_cmd(browser))

---- WINDOWS ----
hl.bind(mainMod .. " + Q",         hl.dsp.window.close())
hl.bind(mainMod .. " + F",         hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
hl.bind(mainMod .. " + W",         hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.window.center())
hl.bind(mainMod .. " + P",         hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J",         hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + G",         hl.dsp.group.toggle())

hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "l" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "r" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "u" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "d" }))

hl.bind(mainMod .. " + SHIFT + left",  hl.dsp.window.move({ direction = "l" }))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.move({ direction = "r" }))
hl.bind(mainMod .. " + SHIFT + up",    hl.dsp.window.move({ direction = "u" }))
hl.bind(mainMod .. " + SHIFT + down",  hl.dsp.window.move({ direction = "d" }))

hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.drag({ resize = true }), { mouse = true })

---- PRISM SHELL PANELS ----
hl.bind(mainMod .. " + A",              hl.dsp.exec_cmd("qs -c prism ipc call launcher toggle"))
hl.bind(mainMod .. " + S",              hl.dsp.exec_cmd("qs -c prism ipc call launcher toggle"))
hl.bind(mainMod .. " + escape",         hl.dsp.exec_cmd("qs -c prism ipc call dashboard toggle"))
hl.bind(mainMod .. " + SHIFT + escape", hl.dsp.exec_cmd("qs -c prism ipc call controls toggle"))
hl.bind(mainMod .. " + N",              hl.dsp.exec_cmd("qs -c prism ipc call sidebar toggle"))
hl.bind(mainMod .. " + O",              hl.dsp.exec_cmd("qs -c prism ipc call overview toggle"))
hl.bind("ALT + Tab",                    hl.dsp.exec_cmd("qs -c prism ipc call switcher toggle"))
hl.bind(mainMod .. " + V",              hl.dsp.exec_cmd("qs -c prism ipc call clipboard toggle"))
hl.bind("CTRL + ALT + W",               hl.dsp.exec_cmd("qs -c prism ipc call wallpaper toggle"))
hl.bind(mainMod .. " + SHIFT + S",      hl.dsp.exec_cmd("qs -c prism ipc call screenshot region"))
hl.bind(mainMod .. " + L",              hl.dsp.exec_cmd("pidof hyprlock || hyprlock"))
hl.bind(mainMod .. " + R",              hl.dsp.exec_cmd("killall qs 2>/dev/null; qs -c prism"))

---- GLOBAL CONTROLS & HARDWARE ----
hl.bind(mainMod .. " + Space",   hl.dsp.exec_cmd("rofi -show drun -theme ~/.config/rofi/launchpad.rasi"))
hl.bind(mainMod .. " + SHIFT + D", hl.dsp.exec_cmd("rice-switch"))
hl.bind("SUPER + ALT + V",       hl.dsp.exec_cmd("audio_output_toggle.sh"))
hl.bind("SUPER + ALT + B",       hl.dsp.exec_cmd("battery_limit_toggle.sh"))
hl.bind("SUPER + ALT + P",       hl.dsp.exec_cmd("power_profile_toggle.sh"))
hl.bind("XF86Launch1",           hl.dsp.exec_cmd("power_profile_toggle.sh"))
hl.bind("XF86Launch4",           hl.dsp.exec_cmd("power_profile_toggle.sh"))

---- WORKSPACES ----
for i = 1, 10 do
    local key = tostring(i % 10)
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))
