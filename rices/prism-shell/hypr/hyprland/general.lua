-- General configurations for Prism Hyprland
local palette = (os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")) .. "/quickshell/prism/.state/colors.lua"
local ok, c = pcall(dofile, palette)
if not ok or type(c) ~= "table" then
    c = {
        primary = "rgba(82d5caff)",
        tertiary = "rgba(aecae6ff)",
        outline = "rgba(899390ff)",
        surface = "rgba(0e1513ff)",
        shadow = "rgba(000000ff)",
    }
end

hl.config({
    general = {
        gaps_in = 4,
        gaps_out = 8,
        border_size = 2,
        ["col.active_border"] = c.primary or "rgba(82d5caff)",
        ["col.inactive_border"] = c.outline or "rgba(899390ff)",
        layout = "dwindle",
    },
    decoration = {
        rounding = 12,
        blur = {
            enabled = true,
            size = 6,
            passes = 3,
            new_optimizations = true,
        },
        shadow = {
            enabled = true,
            range = 10,
            render_power = 3,
            color = c.shadow or "rgba(000000ff)",
        },
    },
    animations = {
        enabled = true,
    },
    input = {
        kb_layout = "us",
        follow_mouse = 1,
        touchpad = {
            natural_scroll = true,
        },
    },
    misc = {
        disable_hyprland_logo = true,
        force_default_wallpaper = 0,
    },
})
