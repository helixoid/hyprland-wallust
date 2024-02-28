#!/bin/bash

tooltip="$(playerctl -p spotify metadata title) - $(playerctl -p spotify metadata artist) - $(playerctl -p spotify metadata album)"
text="$(playerctl -p spotify metadata title) - $(playerctl -p spotify metadata artist)"

echo "{\"text\": \"$text\", \"tooltip\": \"$tooltip\"}"
