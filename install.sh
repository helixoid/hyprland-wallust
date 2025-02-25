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
    case "${response,,}" in
    y|yes) return 0 ;;
    n|no) return 1 ;;
    *) printf "Invalid input. Please type Y or N.\n" ;;
    esac
  done
}

# Check if a package group is installed
package_group_exists() {
  pacman -Sg "$1" >/dev/null 2>&1
}

# Check if a package is installed
package_exists() {
  pacman -Qi "$1" >/dev/null 2>&1
}

# Install a package if it's not already installed
install_package() {
  local pkg="$1"
  
  # Check if already installed
  if package_exists "$pkg"; then
    printf "Package %s is already installed.\n" "$pkg"
    return 0
  fi
  
  printf "Installing %s...\n" "$pkg"
  paru -S --needed --noconfirm "$pkg" || handle_error "Failed to install $pkg using paru."
  
  # Verify installation
  if ! package_exists "$pkg"; then
    handle_error "Package $pkg installation verification failed"
  fi
  
  printf "%s installed successfully.\n" "$pkg"
}

# Install multiple packages at once
install_multiple_packages() {
  local packages=("$@")
  local pkg_list=""
  
  # Check which packages need to be installed
  for pkg in "${packages[@]}"; do
    if ! package_exists "$pkg"; then
      pkg_list+="$pkg "
    fi
  done
  
  # Skip if all packages are already installed
  if [[ -z "$pkg_list" ]]; then
    printf "All packages already installed: %s\n" "${packages[*]}"
    return 0
  fi
  
  # Install missing packages
  printf "Installing: %s\n" "$pkg_list"
  paru -S --needed --noconfirm $pkg_list || handle_error "Failed to install packages: $pkg_list"
  
  # Verify installation
  for pkg in "${packages[@]}"; do
    if ! package_exists "$pkg"; then
      handle_error "Package $pkg installation verification failed"
    fi
  done
  
  printf "Successfully installed: %s\n" "$pkg_list"
}

# Clone a repository if it doesn't already exist
clone_repo() {
  local repo_url="$1"
  local target_dir="$2"
  
  if [ -e "$target_dir" ]; then
    if [ -d "$target_dir" ] && [ -d "$target_dir/.git" ]; then
      printf "Repository already exists at %s. Updating...\n" "$target_dir"
      (cd "$target_dir" && git pull) || handle_error "Failed to update repository at $target_dir"
    else
      handle_error "$target_dir exists but is not a git repository. Please remove or rename it."
    fi
  else
    printf "Cloning repository from %s...\n" "$repo_url"
    git clone --depth=1 "$repo_url" "$target_dir" || handle_error "Failed to clone $repo_url"
    printf "Repository cloned successfully to %s.\n" "$target_dir"
  fi
}

# Install GPU drivers based on user choice
install_gpu_drivers() {
  local gpu_choice
  
  while true; do
    read -rp "Which GPU are you using? [N]vidia [A]md [I]ntel [S]kip: " gpu_choice
    case "${gpu_choice,,}" in
    n|nvidia)
      install_multiple_packages "nvidia-open-dkms" "nvidia-utils"
      break
      ;;
    i|intel)
      install_multiple_packages "intel-media-driver" "vulkan-intel" "thermald"
      printf "Enabling thermald service...\n"
      sudo systemctl enable --now thermald || handle_error "Failed to enable thermald"
      break
      ;;
    a|amd)
      printf "No additional drivers needed for AMD.\n"
      break
      ;;
    s|skip)
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
  
  # Special handling for gaming packages
  if [[ "$pkg_file" == *gaming.txt* ]] && ! command_exists flatpak; then
    printf "Flatpak is not installed, skipping gaming package installation.\n"
    return 0
  fi
  
  printf "Installing packages from %s...\n" "$pkg_file"
  
  # Read file line by line and install packages
  while IFS= read -r line || [[ -n "$line" ]]; do
    # Skip empty lines and comments
    [[ -z "$line" || "$line" =~ ^# ]] && continue
    
    install_package "$line"
  done < "$pkg_file"
}

# Configure shell to fish
configure_shell() {
  local current_shell="$(getent passwd "$USER" | cut -d: -f7)"
  local fish_path="$(command -v fish)"
  
  if [[ -z "$fish_path" ]]; then
    ask_yes_no "Fish shell is not installed. Would you like to install it?" || return 0
    install_package "fish"
    fish_path="$(command -v fish)"
    
    if [[ -z "$fish_path" ]]; then
      handle_error "Fish shell installation failed."
    fi
  fi
  
  if [[ "$current_shell" != "$fish_path" ]]; then
    ask_yes_no "Would you like to change your default shell to fish?" || return 0
    
    # Change shell
    sudo chsh -s "$fish_path" "$USER" || handle_error "Failed to change shell to fish"
    printf "Shell changed to fish. Changes will take effect on next login.\n"
  else
    printf "Your default shell is already fish.\n"
  fi
}

# Enable systemd services
enable_systemd_services() {
  # Define services with their types (user or system)
  declare -A services
  services["mpd"]="user"
  services["firewalld"]="system"
  services["vnstat"]="system"
  services["power-profiles-daemon"]="system"
  services["bluetooth"]="system"
  
  printf "Starting services...\n"
  
  for service in "${!services[@]}"; do
    local service_type="${services[$service]}"
    
    if [[ "$service_type" == "user" ]]; then
      printf "Enabling user service: %s\n" "$service"
      systemctl --user enable --now "$service" || printf "Warning: Failed to enable/start user service %s.\n" "$service"
    else
      printf "Enabling system service: %s\n" "$service"
      sudo systemctl enable --now "$service" || printf "Warning: Failed to enable/start system service %s.\n" "$service"
    fi
  done
}

# Prompt for reboot
prompt_reboot() {
  ask_yes_no "Installation complete. Reboot system now?" && sudo reboot || printf "Reboot skipped. Installation complete.\n"
}

# Paru installation
install_paru() {
  if command_exists paru; then
    printf "Paru is already installed.\n"
    return 0
  fi
  
  # Install base-devel package group
  printf "Installing base-devel package group...\n"
  sudo pacman -S --needed --noconfirm base-devel || handle_error "Failed to install base-devel"
  
  # Create temporary directory
  local temp_dir=$(mktemp -d)
  printf "Cloning paru repository...\n"
  
  clone_repo "https://aur.archlinux.org/paru.git" "$temp_dir"
  
  # Build and install paru
  printf "Building and installing paru...\n"
  (cd "$temp_dir" && makepkg -si --noconfirm) || handle_error "Failed to build and install paru"
  
  # Clean up temporary directory
  rm -rf "$temp_dir"
  
  # Verify installation
  command_exists paru || handle_error "Paru installation failed"
  printf "Paru installed successfully.\n"
}

# --- Main Script ---

# Print welcome message
printf "===== Hyprland-Wallust Installation Script =====\n"
printf "This script will install the necessary packages and dotfiles for Hyprland with Wallust.\n\n"

# Initial checks
ask_yes_no "Have you reviewed the packages.txt and gaming.txt files?" || {
  printf "Please review the package files before proceeding. Exiting...\n"
  exit 1
}

# Install git if not already installed
if ! command_exists git; then
  printf "Installing git...\n"
  sudo pacman -S --needed --noconfirm git || handle_error "Failed to install git"
fi

# Install paru
install_paru

# Install stow
install_package "stow"

# Install linux-headers
install_package "linux-headers"

# Install GPU drivers
install_gpu_drivers

# Clone dotfiles
printf "Setting up dotfiles...\n"
clone_repo "$REPO_URL" "$DOTFILES_DIR"

# Navigate to dotfiles directory
cd "$DOTFILES_DIR" || handle_error "Failed to navigate to $DOTFILES_DIR"

# Install Flatpak if necessary
if ask_yes_no "Do you want to install Flatpak?"; then
  install_package "flatpak"
  
  # Add Flathub repository if not already added
  if command_exists flatpak; then
    flatpak --user remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || printf "Warning: Failed to add Flathub repository.\n"
  fi
fi

# Install packages
printf "Installing packages...\n"
install_packages_from_file "packages.txt"

# Install Flatpak packages
if command_exists flatpak; then
  install_packages_from_file "gaming.txt"
fi

# Symlink dotfiles using Stow
printf "Symlinking dotfiles to your home directory using GNU Stow...\n"
stow -v -t "$HOME" . 2>&1 | tee stow_output.log || {
  printf "Stow failed to symlink files. Check stow_output.log for details.\n"
  exit 1
}

# Enable systemd services
enable_systemd_services

# Configure shell
configure_shell

# Prompt for reboot
prompt_reboot
