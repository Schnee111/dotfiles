-- Enable cua-driver's native Wayland backend (experimental, opt-in upstream).
-- Without this the driver falls back to X11/Xwayland, which sees 0 windows on
-- this Hyprland session (all apps are native Wayland) -> computer_use captures fail.
hl.env("CUA_DRIVER_RS_ENABLE_WAYLAND", "1")
