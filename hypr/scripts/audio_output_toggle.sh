#!/bin/bash
CARD="alsa_card.pci-0000_00_1f.3-platform-skl_hda_dsp_generic"
ACTIVE_PROFILE=$(pactl list cards | grep "Active Profile:" | awk -F': ' '{print $2}')

wait_for_sink() {
    local target="$1"
    for _ in {1..30}; do
        if pactl list sinks short | grep -q "$target"; then
            return 0
        fi
        sleep 0.05
    done
    return 1
}

move_streams_to() {
    local dest="$1"
    for id in $(pactl list sink-inputs short | awk '{print $1}'); do
        local media_name
        media_name=$(pactl list sink-inputs | grep -A 15 "Sink Input #$id" | grep 'media.name' | head -1)
        if [[ "$media_name" != *"Headphones (Balanced)"* ]]; then
            pactl move-sink-input "$id" "$dest" 2>/dev/null || true
        fi
    done
}

if [[ "$ACTIVE_PROFILE" == *"Headphones"* ]]; then
    # Currently Headphones -> switch to Speaker
    TARGET_SINK="alsa_output.pci-0000_00_1f.3-platform-skl_hda_dsp_generic.HiFi__Speaker__sink"
    pactl set-card-profile "$CARD" "HiFi (HDMI1, HDMI2, HDMI3, Mic1, Speaker)"
    wait_for_sink "$TARGET_SINK"
    pactl set-default-sink "$TARGET_SINK"
    move_streams_to "$TARGET_SINK"
    notify-send -a "Audio Output" -n "speaker" "Audio Output: Speaker" "Switched to Laptop Speaker" -t 2000
    canberra-gtk-play -i audio-volume-change 2>/dev/null &
else
    # Currently Speaker -> switch to Headphones
    HW_SINK="alsa_output.pci-0000_00_1f.3-platform-skl_hda_dsp_generic.HiFi__Headphones__sink"
    TARGET_SINK="headphone_balanced"
    pactl set-card-profile "$CARD" "HiFi (HDMI1, HDMI2, HDMI3, Headphones, Mic1)"
    wait_for_sink "$HW_SINK"
    wait_for_sink "$TARGET_SINK"
    pactl set-default-sink "$TARGET_SINK"
    move_streams_to "$TARGET_SINK"
    notify-send -a "Audio Output" -n "headphones" "Audio Output: Headset" "Switched to Headphones" -t 2000
    canberra-gtk-play -i audio-volume-change 2>/dev/null &
fi
