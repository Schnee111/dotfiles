#!/bin/bash

case "$1" in
play-pause)
  playerctl play-pause
  ;;
next)
  playerctl next
  ;;
prev)
  playerctl previous
  ;;
stop)
  playerctl stop
  ;;
*)
  echo "Usage: $0 {play-pause|next|prev|stop}"
  exit 1
  ;;
esac
