#!/usr/bin/env bash

# Installing Necessary Packages
paru -S --needed --noconfirm hyprland waybar rofi-lbonn-wayland-git xdg-desktop-portal-hyprland linux-headers

paru -S --needed --noconfirm nwg-look mpv yt-dlp mpd ncmpcpp cava

paru -S --needed --noconfirm wezterm hyprlock-git downgrade blueman

paru -S --needed --noconfirm wlsunset qt5-wayland qt6-wayland 

paru -S --needed --noconfirm hypridle-git swww python-geoip swaync waypaper-git

paru -S --needed --noconfirm macchina imagemagick network-manager-applet bottom

paru -S --needed --noconfirm pavucontrol vnstat wl-clipboard cliphist

paru -S --needed --noconfirm fish starship firewalld brightnessctl imv

paru -S --needed --noconfirm noto-fonts noto-fonts-cjk noto-fonts-extra noto-fonts-emoji

paru -S --needed --noconfirm polkit-gnome tremc-git grim bemoji

paru -S --needed --noconfirm slurp satty-bin newsboat bat lsd speech-dispatcher

paru -S --needed --noconfirm papirus-icon-theme ttf-nerd-fonts-symbols

paru -S --needed --noconfirm thunar tumbler thunar-volman thunar-archive-plugin thunar-media-tags-plugin file-roller

paru -S --needed --noconfirm gvfs gvfs-afc gvfs-mtp xdg-user-dirs ffmpegthumbnailer

#paru -S --needed --noconfirm gst-plugins-good gst-plugins-bad gst-plugins-ugly

paru -S --needed --noconfirm flatpak xdg-desktop-portal-gtk

paru -S --needed --noconfirm zathura zathura-pdf-mupdf zathura-cb yazi fd

paru -S --needed --npconfirm fzf poppler zoxide ripgrep waycheck

#paru -S --needed --noconfirm kvantum qt5ct qt6ct avizo-git onefetch

#paru -S --needed --noconfirm sddm plymouth sddm-theme-sugar-candy-git

# Installing Intel Hardware Decoding Driver
#paru -S --needed --noconfirm intel-media-driver thermald power-profiles-daemon

# Installing nVidia Drivers
#paru -S --needed --noconfirm nvidia-dkms nvidia-utils nvidia-settings lib32-nvidia-utils

# Removing Extra Packages
paru -Rns vim
paru -Rns kitty
paru -Rns xdg-desktop-portal-gnome
paru -Rns xdg-desktop-portal-kde
paru -c

# Flatpak Apps Install
flatpak install flathub com.github.tchx84.Flatseal -y
flatpak install flathub io.missioncenter.MissionCenter -y
flatpak install flathub dev.edfloreshz.Done -y
flatpak install flathub info.febvre.Komikku -y
flatpak install flathub org.telegram.desktop -y
#flatpak install flathub org.kde.KStyle.Adwaita
