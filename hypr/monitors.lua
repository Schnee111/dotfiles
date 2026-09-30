hl.monitor({
    output = "eDP-1",
    mode = "2880x1800@90",
    position = "0x0",
    scale = 1.5,
})

hl.monitor({
    output = "HDMI-A-1",
    disabled = true,
})

hl.monitor({
    output = "FALLBACK",
    mode = "1920x1080@60",
    position = "auto",
    scale = 1,
})
