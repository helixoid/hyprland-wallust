#!/usr/bin/env sh
swayidle -w \
timeout 120 ' swaylock ' \
timeout 180 ' hyprctl dispatch dpms off' \
timeout 900 'systemctl suspend' \
resume ' hyprctl dispatch dpms on' \
before-sleep 'swaylock'