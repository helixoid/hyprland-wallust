#!/usr/bin/env bash

dir="$HOME/.config/rofi/Blurred-Background/clipboard"
theme='style-1'

## Run
rofi \
    -dmenu \
    -p "📋" \
    -theme ${dir}/${theme}.rasi
