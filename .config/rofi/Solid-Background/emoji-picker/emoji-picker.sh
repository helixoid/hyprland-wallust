#!/usr/bin/env bash

dir="$HOME/.config/rofi/Solid-Background/emoji-picker"
theme='style-1'

## Run
rofi \
    -dmenu \
    -p "😸" \
    -theme ${dir}/${theme}.rasi
