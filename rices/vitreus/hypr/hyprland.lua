local home   = os.getenv("HOME")
local hypr   = home .. "/.config/hypr"
package.path = package.path .. ";" .. home .. "/.config/vitreus/?.lua"

-- User variables
local overrides_file = home .. "/.config/vitreus/hypr-vars.lua"
local f = io.open(overrides_file)
if not f then
    local w = io.open(overrides_file, "w")
    if w then w:write("return {}\n") w:close() end
else
    f:close()
end
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

-- Vitreus shell binds (loaded last so SUPER+Space/D/L/B win over rice binds)
pcall(require, "hypr_vitreus")
pcall(require, "vitreus_monitors")
pcall(require, "vitreus_hypr")
pcall(require, "vitreus_colors")

-- User configs
local uf = io.open(home .. "/.config/vitreus/hypr-user.lua")
if not uf then
    local w = io.open(home .. "/.config/vitreus/hypr-user.lua", "w")
    if w then w:close() end
else
    uf:close()
end
require("hypr-user")
