#!/bin/bash
CARD="alsa_card.pci-0000_00_1f.3-platform-skl_hda_dsp_generic"
ACTIVE_PROFILE=$(pactl list cards | grep "Active Profile:" | awk -F': ' '{print $2}')

if [[ "$ACTIVE_PROFILE" == *"Headphones"* ]]; then
    # Currently Headphones -> switch to Speaker
    pactl set-card-profile "$CARD" "HiFi (HDMI1, HDMI2, HDMI3, Mic1, Speaker)"
    sleep 0.15
    pactl set-default-sink "alsa_output.pci-0000_00_1f.3-platform-skl_hda_dsp_generic.HiFi__Speaker__sink"
    notify-send -a "Audio Output" -n "speaker" "Audio Output: Speaker" "Switched to Laptop Speaker" -t 2000
    canberra-gtk-play -i audio-volume-change 2>/dev/null &
else
    # Currently Speaker -> switch to Headphones
    pactl set-card-profile "$CARD" "HiFi (HDMI1, HDMI2, HDMI3, Headphones, Mic1)"
    sleep 0.15
    pactl set-default-sink "headphone_balanced"
    notify-send -a "Audio Output" -n "headphones" "Audio Output: Headset" "Switched to Headphones" -t 2000
    canberra-gtk-play -i audio-volume-change 2>/dev/null &
fi
