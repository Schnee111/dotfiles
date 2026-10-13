-- DDC-aware brightness keys for the Vitreus rice. Loaded from hyprland.lua
-- AFTER hypr_vitreus.lua, so these binds win over both keybinds.lua and the
-- shell's own brightness binds (which only know brightnessctl).
-- External monitor (eDP disabled) is driven over DDC/CI, the laptop panel
-- over brightnessctl; `vitreus-brightness` picks the backend and prints the
-- new level (0..1) for the shell's OSD, same channel as before.
hl.unbind("XF86MonBrightnessUp")
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd([[PATH="$HOME/.local/bin:$PATH"; f=$(vitreus-brightness up); pleamar --say vitreus "emit bright_key $f"]]), { locked = true, repeating = true })
hl.unbind("XF86MonBrightnessDown")
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd([[PATH="$HOME/.local/bin:$PATH"; f=$(vitreus-brightness down); pleamar --say vitreus "emit bright_key $f"]]), { locked = true, repeating = true })
