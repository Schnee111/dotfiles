-- Repo defaults — merged into main.lua during install/update
-- @live: use current Hyprland value, @static: use value as-is
hl.config({decoration={rounding=18}}) -- @live
hl.config({general={layout="dwindle"}}) -- @live
hl.animation({leaf="workspaces", enabled=true, speed=7, bezier="menu_decel", style="slide"}) -- @live
hl.layer_rule({match={namespace="quickshell:dock"}, animation="slide bottom"}) -- @static

