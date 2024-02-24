#!/usr/bin/env bash

dir="$HOME/.config/rofi/Solid-Background/launcher"
theme='style-7'

## Run
rofi \
    -show drun \
    -theme ${dir}/${theme}.rasi
