-- Window and layer rules for Prism
hl.layer_rule({
    match = { namespace = "^quickshell.*" },
    blur = true,
    ignore_alpha = 0.45,
})

hl.window_rule({
    name = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    match = { class = "^(pavucontrol|org.pulseaudio.pavucontrol)$" },
    float = true,
})

hl.window_rule({
    match = { class = "^(blueman-manager)$" },
    float = true,
})
