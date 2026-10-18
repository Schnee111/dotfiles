-- Monitor defaults
-- Laptop display (eDP-1: 14" 2.8K OLED): default scale 1.6 (160%)
hl.monitor({
    output = "eDP-1",
    mode = "2880x1800@90",
    position = "0x0",
    scale = 1.6,
})

-- External monitor (HDMI-A-1: 1080p standard): default scale 1.0 (100%)
hl.monitor({
    output = "HDMI-A-1",
    mode = "1920x1080@200",
    position = "auto",
    scale = 1,
})

-- Prevent DPMS wake race condition from triggering lockdead ("Oopsie daisy") emergency screen
-- focus_on_activate = true lets apps that legitimately request focus via the
-- xdg-activation protocol (e.g. a browser opening a link from another window)
-- actually get focused. Background/focus-stealing apps are suppressed per-window
-- in custom/rules.lua with `suppress_event = "activatefocus"`.
hl.config({
    misc = {
        lockdead_screen_delay = 100000000,
        allow_session_lock_restore = true,
        focus_on_activate = true,
    },
    render = {
        direct_scanout = 0,
    },
    decoration = {
        dim_inactive = false,
        blur = {
            brightness = 1.08,
            size = 7,
            passes = 3,
            noise = 0.055,
            contrast = 1.05,
            vibrancy = 0.60,
            vibrancy_darkness = 0.0,
            xray = false,
        }
    }
})
