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
hl.config({
    misc = {
        lockdead_screen_delay = 100000000,
        allow_session_lock_restore = true,
    },
    render = {
        direct_scanout = 0,
    },
    decoration = {
        blur = {
            brightness = 1.0,
            size = 3,
        }
    }
})
