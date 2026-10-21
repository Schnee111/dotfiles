-- User Keybindings
hl.bind("CTRL+SUPER+ALT+Slash", hl.dsp.exec_cmd("xdg-open ~/.config/hypr/custom/keybinds.lua"), {description = "Edit user keybinds"} )
hl.bind("CTRL + SUPER + Slash", hl.dsp.exec_cmd("xdg-open ~/.config/illogical-impulse/config.json"), { description = "Edit shell config" })
hl.bind("SUPER + escape", hl.dsp.global("quickshell:settingsToggle"), {description = "Toggle settings"})
hl.bind("XF86KbdBrightnessUp", hl.dsp.exec_cmd("brightnessctl -d 'asus::kbd_backlight' s 1+"))
hl.bind("XF86KbdBrightnessDown", hl.dsp.exec_cmd("brightnessctl -d 'asus::kbd_backlight' s 1-"))
hl.bind("XF86Display", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/display_switch.sh"), {description = "Display switch menu"})
hl.bind("SUPER + F8", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/display_switch.sh"), {description = "Display switch menu"})
hl.bind("SUPER + P", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/display_switch.sh"), {description = "Display switch menu"})
hl.bind("SUPER + Space", hl.dsp.exec_cmd("$HOME/.config/rofi/launcher.sh"), {description = "App Launcher: Launchpad Grid"})
hl.bind("SUPER + ALT + V", hl.dsp.exec_cmd("$HOME/.local/bin/audio_output_toggle.sh"), {description = "Audio: Toggle Headset / Laptop Speaker"})
hl.bind("SUPER + ALT + O", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/opacity_toggle.sh"), {description = "Appearance: Toggle Frosted Glass / Solid Mode"})

-- Battery & Power Management
hl.bind("SUPER + ALT + B", hl.dsp.exec_cmd("$HOME/.local/bin/battery_limit_toggle.sh"), {description = "Battery: Toggle 80% / 100% Charge Limit"})
hl.bind("SUPER + ALT + P", hl.dsp.exec_cmd("$HOME/.local/bin/power_profile_toggle.sh"), {description = "Power Profile: Cycle Quiet / Balanced / Performance"})
hl.bind("XF86Launch1", hl.dsp.exec_cmd("$HOME/.local/bin/power_profile_toggle.sh"), {description = "Power Profile: Asus Fan Key"})
hl.bind("XF86Launch4", hl.dsp.exec_cmd("$HOME/.local/bin/power_profile_toggle.sh"), {description = "Power Profile: Asus Fan Key"})

-- Window Switcher (Alt + Tab)
hl.bind("ALT + Tab", function()
    hl.dispatch(hl.dsp.window.cycle_next())
    hl.dispatch(hl.dsp.window.bring_to_top())
end, { description = "Window: Cycle next" })
hl.bind("ALT + SHIFT + Tab", function()
    hl.dispatch(hl.dsp.window.cycle_next(true))
    hl.dispatch(hl.dsp.window.bring_to_top())
end, { description = "Window: Cycle prev" })

-- Fast Workspace Switcher (Previous Workspace Toggle)
hl.bind("SUPER + grave", hl.dsp.focus({ workspace = "previous" }), { description = "Workspace: Toggle previous workspace" })
hl.bind("SUPER + code:49", hl.dsp.focus({ workspace = "previous" }))
hl.bind("SUPER + ALT + Tab", hl.dsp.focus({ workspace = "previous" }), { description = "Workspace: Toggle previous workspace" })
hl.bind("ALT + SUPER + Tab", hl.dsp.focus({ workspace = "previous" }))

-- Desktop Profile Switcher
hl.bind("SUPER + SHIFT + D", hl.dsp.exec_cmd("$HOME/.local/bin/rice-switch"), { description = "Rice: Switch desktop profile" })
