-- Monitor configuration with physical DRM check (Laptop screen fallback if HDMI unplugged)
local function is_external_connected()
    for _, card in ipairs({"card1", "card0"}) do
        local f = io.open("/sys/class/drm/" .. card .. "-HDMI-A-1/status", "r")
        if f then
            local st = f:read("*l")
            f:close()
            if st == "connected" then
                return true
            end
        end
    end
    return false
end

if is_external_connected() then
    hl.monitor({
        output   = "HDMI-A-1",
        mode     = "1920x1080@200",
        position = "0x0",
        scale    = 1,
    })
    hl.monitor({
        output   = "eDP-1",
        disabled = true,
    })
else
    hl.monitor({
        output   = "eDP-1",
        mode     = "2880x1800@90",
        position = "0x0",
        scale    = 1.6,
    })
    hl.monitor({
        output   = "HDMI-A-1",
        disabled = true,
    })
end
