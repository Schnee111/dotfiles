-- ==============================================================================
-- Hyprland Monitors Hardware Safeguard
-- Prevents black screen on cold boot or reload when no external display is connected
-- ==============================================================================

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

-- If external monitor is NOT physically connected, enforce internal laptop screen
if not is_external_connected() then
    hl.monitor({
        output = "eDP-1",
        mode = "2880x1800@90",
        position = "0x0",
        scale = 1.5,
        disabled = false,
    })
    hl.monitor({
        output = "HDMI-A-1",
        disabled = true,
    })
end
