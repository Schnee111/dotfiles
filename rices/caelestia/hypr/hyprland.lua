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

-- Persisted display choice written by caelestia-display-switch.sh (bin/, on
-- PATH): "external", "laptop" or "extend".
-- When the file is absent the smart physical-DRM default below is used.
local function persisted_display_mode()
    -- `home` comes from the top of this file; the fallback keeps the helper
    -- self-contained if it is ever called from another scope (no behaviour
    -- change — `home` is always set here).
    local base = home or os.getenv("HOME")
    if not base then
        return nil
    end

    local f = io.open(base .. "/.config/caelestia/display-mode", "r")
    if not f then
        return nil
    end

    local mode = f:read("*l")
    f:close()

    if type(mode) == "string" then
        return mode:gsub("%s+", ""):lower()
    end

    return nil
end

local function enable_external(position)
    hl.monitor({
        output   = "HDMI-A-1",
        mode     = "1920x1080@200",
        position = position or "0x0",
        scale    = 1,
    })
end

local function enable_laptop(position)
    hl.monitor({
        output   = "eDP-1",
        mode     = "2880x1800@90",
        position = position or "0x0",
        scale    = 1.6,
    })
end

local function disable_monitor(output)
    hl.monitor({
        output   = output,
        disabled = true,
    })
end

local external = is_external_connected()
local mode = persisted_display_mode()

-- "external" and "extend" need the HDMI panel. If it is gone (unplugged,
-- undocked) fall back to the physical-DRM default so the laptop panel is
-- never left disabled with no active display at all.
if not external and (mode == "external" or mode == "extend") then
    mode = nil
end

if mode == "external" then
    enable_external()
    disable_monitor("eDP-1")
elseif mode == "laptop" then
    enable_laptop()
    disable_monitor("HDMI-A-1")
elseif mode == "extend" then
    enable_laptop()
    enable_external("auto-right")
elseif external then
    enable_external()
    disable_monitor("eDP-1")
else
    enable_laptop()
    disable_monitor("HDMI-A-1")
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

