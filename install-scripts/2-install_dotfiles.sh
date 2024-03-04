#!/usr/bin/env bash

xdg-user-dirs-update

xdg-mime default org.pwmt.zathura.desktop application/pdf

xdg-mime default imv-dir.desktop image/png

xdg-mime default imv-dir.desktop image/webp

xdg-mime default imv-dir.desktop image/jpg

#sudo flatpak override --env=QT_STYLE_OVERRIDE=Adwaita-dark

# Installing Dotfiles
cd $HOME/hyprland-wallust
cp -R .config ~/
cp -R Wallpapers ~/
cd

wallust run ~/Wallpaper/Akiakane-2.jpg

ln -s ~/.cache/wal/cava ~/.config/cava/config
#wget -qO- https://git.io/papirus-icon-theme-install | DESTDIR="$HOME/.local/share/icons" sh
