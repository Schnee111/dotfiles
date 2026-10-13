#!/bin/bash

if [ -f "/tmp/volume_notification_id" ]; then
  NOTIFY_ID=$(cat "/tmp/volume_notification_id")
  [ -z "$NOTIFY_ID" ] && NOTIFY_ID=0
else
  NOTIFY_ID=0
fi

PREV_VOL_INFO=$(wpctl get-volume @DEFAULT_AUDIO_SINK@)
PREV_VOL=$(echo "$PREV_VOL_INFO" | awk '{printf "%.0f", $2 * 100}')

case "$1" in
up)
  if [ "$PREV_VOL" -ge 100 ]; then
    exit 0
  fi
  wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ -l 1.0
  ;;
down)
  if [ "$PREV_VOL" -le 0 ]; then
    exit 0
  fi
  wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
  ;;
mute)
  wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
  ;;
mic-mute)
  wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
  ;;
esac

VOLUME_INFO=$(wpctl get-volume @DEFAULT_AUDIO_SINK@)
VOLUME=$(echo "$VOLUME_INFO" | awk '{printf "%.0f", $2 * 100}')
MUTED=$(echo "$VOLUME_INFO" | grep -q "MUTED" && echo "yes" || echo "no")

if [ "$1" = "mic-mute" ]; then
  if [ -f "/tmp/mic_notification_id" ]; then
    MIC_NOTIFY_ID=$(cat "/tmp/mic_notification_id")
    [ -z "$MIC_NOTIFY_ID" ] && MIC_NOTIFY_ID=0
  else
    MIC_NOTIFY_ID=0
  fi
  MIC_INFO=$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@)
  MIC_MUTED=$(echo "$MIC_INFO" | grep -q "MUTED" && echo "yes" || echo "no")
  if [ "$MIC_MUTED" = "yes" ]; then
    notify-send -p -r "$MIC_NOTIFY_ID" -t 1500 "Microphone" "Muted" >"/tmp/mic_notification_id"
  else
    notify-send -p -r "$MIC_NOTIFY_ID" -t 1500 "Microphone" "Unmuted" >"/tmp/mic_notification_id"
  fi
  exit 0
fi

if [ "$MUTED" = "yes" ]; then
  TEXT="Muted"
elif [ "$VOLUME" -le 30 ]; then
  TEXT="${VOLUME}%"
elif [ "$VOLUME" -le 70 ]; then
  TEXT="${VOLUME}%"
else
  TEXT="${VOLUME}%"
fi

notify-send -p -r "$NOTIFY_ID" -t 1500 -h int:value:"$VOLUME" "Volume" "$TEXT" >"/tmp/volume_notification_id"
