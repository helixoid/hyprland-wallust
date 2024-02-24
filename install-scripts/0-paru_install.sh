#!/usr/bin/env bash

sudo pacman -Syy
sudo pacman -S --needed --noconfirm git

sudo pacman -S --needed base-devel
git clone https://aur.archlinux.org/paru-bin.git
cd paru-bin
makepkg -si 
cd