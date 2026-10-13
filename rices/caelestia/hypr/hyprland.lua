local home   = os.getenv("HOME")
local hypr   = home .. "/.config/hypr"
package.path = package.path .. ";" .. home .. "/.config/caelestia/?.lua"

-- Create a file if it doesn't exist, optionally with initial content
local function maybe_create(file, content)
    local f = io.open(file)

    if f then
        f:close()
        return
    end

    f = io.open(file, "w")
    if f then
        if content then f:write(content) end
        f:close()
    end
end

-- Copy src to dst, but only if dst doesn't already exist
local function maybe_copy(src, dst)
    local out = io.open(dst)
    if out then
        out:close()
        return
    end

    local input = io.open(src, "r")
    if not input then return end

    out = io.open(dst, "w")
    if out then
        out:write(input:read("*a"))
        out:close()
    end
    input:close()
end

-- Maybe set current colours to defaults
maybe_copy(hypr .. "/scheme/default.lua", hypr .. "/scheme/current.lua")

-- User variables
maybe_create(home .. "/.config/caelestia/hypr-vars.lua", "return {}\n")
local overrides = require("hypr-vars")
if type(overrides) == "table" then
    local vars = require("variables")
    for k, v in pairs(overrides) do
        vars[k] = v
    end
end

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

-- Configs
require("hyprland.env")
require("hyprland.general")
require("hyprland.input")
require("hyprland.misc")
require("hyprland.animations")
require("hyprland.decoration")
require("hyprland.group")
require("hyprland.execs")
require("hyprland.rules")
require("hyprland.gestures")
require("hyprland.keybinds")

-- User configs
maybe_create(home .. "/.config/caelestia/hypr-user.lua")
require("hypr-user")
