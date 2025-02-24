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
  printf "Error: %s\n" "$1"
  exit 1
}

# Ask yes/no questions
ask_yes_no() {
  local prompt="$1"
  local response
  while true; do
    read -rp "$prompt [Y]es [N]o: " response
    case "$response" in
    [Yy]*) return 0 ;;
    [Nn]*) return 1 ;;
    *) printf "Invalid input. Please type Y or N.\n" ;;
    esac
  done
}

# Install a package if it's not already installed
install_package() {
  local pkg="$1"
  printf "Installing %s...\n" "$pkg"
  paru -S --needed --noconfirm "$pkg"
  if [[ $? -ne 0 ]]; then
    handle_error "Failed to install $pkg using paru."
  fi
  if ! paru -Qs "^$pkg\$" >/dev/null; then
    handle_error "Package $pkg installation verification failed"
  fi
  printf "%s installed successfully.\n" "$pkg"
}

# Clone a repository if it doesn't already exist
clone_repo() {
  local repo_url="$1"
  local target_dir="$2"
  if [ -d "$target_dir" ]; then
    printf "Directory %s already exists. Skipping clone.\n" "$target_dir"
  else
    printf "Cloning repository from %s...\n" "$repo_url"
    git clone --depth=1 "$repo_url" "$target_dir"
    if [[ $? -ne 0 ]]; then
      handle_error "Failed to clone $repo_url"
    fi
  fi
}

# Install GPU drivers based on user choice
install_gpu_drivers() {
  local gpu_choice
  while true; do
    read -rp "Which GPU are you using? [N]vidia [A]md [I]ntel [S]kip: " gpu_choice
    case "$gpu_choice" in
    [Nn]*)
      paru -S --needed --noconfirm "nvidia-open-dkms nvidia-utils" || handle_error "Failed to install NVIDIA drivers"
      break
      ;;
    [Ii]*)
      paru -S --needed --noconfirm "intel-media-driver vulkan-intel thermald" || handle_error "Failed to install Intel drivers"
      printf "Enabling thermald service...\n"
      sudo systemctl enable --now thermald || handle_error "Failed to enable thermald"
      break
      ;;
    [Aa]*)
      printf "No additional drivers needed for AMD.\n"
      break
      ;;
    [Ss]*)
      printf "Skipping GPU driver installation.\n"
      break
      ;;
    *)
      printf "Invalid input. Please choose N, I, A, or S.\n"
      ;;
    esac
  done
}

# Install packages from a file
install_packages_from_file() {
  local pkg_file="$1"
  if [[ ! -r "$pkg_file" ]]; then
    printf "No package list found (%s) or file is not readable. Skipping package installation.\n" "$pkg_file"
    return 0
  fi
  if [[ "$pkg_file" == *gaming.txt* ]] && ! command_exists flatpak; then
    printf "flatpak is not installed, skipping gaming package installation.\n"
    return 0
  fi
  printf "Installing packages from %s...\n" "$pkg_file"
  while IFS= read -r pkg; do
    install_package "$pkg"
  done <"$pkg_file"
}

# Configure shell to fish
configure_shell() {
  local current_shell="$(echo "$SHELL")"
  local fish_path="$(which fish)"

  if [[ "$current_shell" != "$fish_path" ]]; then
    ask_yes_no "Would you like to change your default shell to fish?" || return 0
    install_package "fish"
    if command_exists fish; then
      sudo chsh -s "$fish_path" || handle_error "Failed to change shell to fish"
      printf "Shell changed to fish.\n"
    else
      handle_error "Fish shell installation failed."
    fi
  else
    printf "Your default shell is already fish.\n"
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
  printf "Starting services...\n"
  for service in "${services[@]}"; do
    local service_name="${service// --user/}"
    if [[ "$service" == *"--user"* ]]; then
      if ! systemctl --user enable --now "$service_name"; then
        printf "Warning: Failed to enable/start %s user service.\n" "$service_name"
      fi
    else
      if ! sudo systemctl enable --now "$service_name"; then
        printf "Warning: Failed to enable/start %s.\n" "$service_name"
      fi
    fi
  done
}

# Prompt for reboot
prompt_reboot() {
  ask_yes_no "Reboot system now?" && sudo -v && sudo reboot || printf "Reboot skipped. Exiting.\n"
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
  printf "Paru installed successfully.\n"
}

# --- Main Script ---

# Initial checks
ask_yes_no "Have you reviewed the packages.txt and gaming.txt files?" || {
  printf "Please review the package files before proceeding. Exiting...\n"
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
printf "Symlinking dotfiles to your home directory using GNU Stow...\n"
stow -v -t "$HOME" . 2>&1 | tee stow_output.log
if [[ $? -ne 0 ]]; then
  printf "Stow failed to symlink files. Check stow_output.log for details.\n"
  exit 1
fi

# Enable systemd services
enable_systemd_services

# Configure shell
configure_shell

# Prompt for reboot
prompt_reboot
