#!/usr/bin/env bash

# Starting Services
systemctl enable --user mpd
sudo systemctl enable firewalld
sudo systemctl enable vnstat
sudo systemctl enable thermald
sudo systemctl enable power-profiles-daemon
sudo systemctl enable bluetooth

# Changing the default shell
chsh -s $(which fish)

sudo reboot