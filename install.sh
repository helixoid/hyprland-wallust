#!/usr/bin/bash

# --- Constants ---
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
REPO_URL="https://github.com/helixoid/hyprland-wallust.git"

# --- Functions ---

# Check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Helper to handle errors
handle_error() {
  echo "Error: $1"
  exit 1
}

# Ask yes/no questions
ask_yes_no() {
  local prompt="$1"
  local response
  while true; do
    read -p "$prompt [Y]es [N]o: " response
    case "$response" in
    [Yy]*) return 0 ;;
    [Nn]*) return 1 ;;
    *) echo "Invalid input. Please type Y or N." ;;
    esac
  done
}

# Install a package if it's not already installed
install_package() {
  local pkg="$1"
  echo "Installing $pkg..."
  paru -S --needed --noconfirm "$pkg" || handle_error "Failed to install $pkg"
  echo "$pkg installed successfully."
}

# Clone a repository if it doesn't already exist
clone_repo() {
  local repo_url="$1"
  local target_dir="$2"
  if [ -d "$target_dir" ]; then
    echo "Directory $target_dir already exists. Skipping clone."
  else
    echo "Cloning repository from $repo_url..."
    git clone --depth=1 "$repo_url" "$target_dir" || handle_error "Failed to clone $repo_url"
  fi
}

# Install GPU drivers based on user choice
install_gpu_drivers() {
  local gpu_choice
  while true; do
    read -p "Which GPU are you using? [N]vidia [A]md [I]ntel [S]kip: " gpu_choice
    case "$gpu_choice" in
    [Nn]*)
      install_package "nvidia-open-dkms"
      install_package "nvidia-utils"
      break
      ;;
    [Ii]*)
      install_package "intel-media-driver"
      install_package "vulkan-intel"
      install_package "thermald"
      echo "Enabling thermald service..."
      sudo systemctl enable --now thermald || handle_error "Failed to enable thermald"
      break
      ;;
    [Aa]*)
      echo "No additional drivers needed for AMD."
      break
      ;;
    [Ss]*)
      echo "Skipping GPU driver installation."
      break
      ;;
    *)
      echo "Invalid input. Please choose N, I, A, or S."
      ;;
    esac
  done
}

# Install packages from a file
install_packages_from_file() {
  local pkg_file="$1"
  if [[ ! -r "$pkg_file" ]]; then
    echo "No package list found ($pkg_file) or file is not readable. Skipping package installation."
    return 0
  fi
  if [[ "$pkg_file" == *gaming.txt* ]] && ! command_exists flatpak; then
    echo "flatpak is not installed, skipping gaming package installation."
    return 0
  fi
  echo "Installing packages from $pkg_file..."
  while IFS= read -r pkg; do
    install_package "$pkg"
  done <"$pkg_file"
}

# Configure shell to fish
configure_shell() {
  local current_shell="$(echo $SHELL)"
  local fish_path="$(which fish)"

  if [[ "$current_shell" != "$fish_path" ]]; then
    ask_yes_no "Would you like to change your default shell to fish?" || return 0
    install_package "fish"
    if command_exists fish; then
      sudo chsh -s "$fish_path" || handle_error "Failed to change shell to fish"
      echo "Shell changed to fish."
    else
      handle_error "Fish shell installation failed."
    fi
  else
    echo "Your default shell is already fish."
  fi
}

# Enable systemd services
enable_systemd_services() {
  local services=(
    "mpd --user"
    "firewalld"
    "vnstat"
    "power-profiles-daemon"
    "bluetooth"
  )
  echo "Starting services..."
  for service in "${services[@]}"; do
    if [[ "$service" == *"--user"* ]]; then
      service=${service// --user/}
      systemctl --user enable --now "$service" || echo "Warning: Failed to enable/start $service user service."
    else
      sudo systemctl enable --now "$service" || echo "Warning: Failed to enable/start $service."
    fi
  done
}

# Prompt for reboot
prompt_reboot() {
  ask_yes_no "Reboot system now?" && sudo -v && sudo reboot || echo "Reboot skipped. Exiting."
}

# Paru installation.
install_paru() {
  if ! command_exists paru; then
    if ! command_exists base-devel; then
      install_package base-devel
    fi
    clone_repo "https://aur.archlinux.org/paru.git" "paru"
    (cd paru && makepkg -si --noconfirm) || handle_error "Failed to build and install paru"
  fi
  echo "Paru installed successfully."
}

# --- Main Script ---

# Initial checks
ask_yes_no "Have you reviewed the packages.txt and gaming.txt files?" || {
  echo "Please review the package files before proceeding. Exiting..."
  exit 1
}

# Install core packages
install_package "git"
install_package "base-devel"
install_paru
install_package "stow"
install_package "linux-headers"
install_gpu_drivers

# Clone dotfiles
clone_repo "$REPO_URL" "$DOTFILES_DIR"
cd "$DOTFILES_DIR" || handle_error "Failed to navigate to $DOTFILES_DIR."

# Install Flatpak if necessary
ask_yes_no "Do you want to install Flatpak?" && install_package "flatpak"

# Install Flatpak packages
install_packages_from_file "$DOTFILES_DIR/gaming.txt"

# Install other packages
install_packages_from_file "$DOTFILES_DIR/packages.txt"

# Symlink dotfiles using Stow
echo "Symlinking dotfiles to your home directory using GNU Stow..."
stow -v -t "$HOME" . || {
  echo "Stow failed to symlink files."
  echo "$(stow -v 2>&1)"
  exit 1
}

# Enable systemd services
enable_systemd_services

# Configure shell
configure_shell

# Prompt for reboot
prompt_reboot
