#!/usr/bin/bash
#
# Hyprland-Wallust Installation Script
# A comprehensive setup script for Hyprland with Wallust configuration
#

# --- Constants ---
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
REPO_URL="https://github.com/helixoid/hyprland-wallust.git"
PACKAGES_FILE="packages.txt"
GAMING_FILE="gaming.txt"
LOG_FILE="install.log"

# --- Colors ---
# Normal Colors
BLACK='\033[0;30m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'

# Bold Colors
BOLD_BLACK='\033[1;30m'
BOLD_RED='\033[1;31m'
BOLD_GREEN='\033[1;32m'
BOLD_YELLOW='\033[1;33m'
BOLD_BLUE='\033[1;34m'
BOLD_PURPLE='\033[1;35m'
BOLD_CYAN='\033[1;36m'
BOLD_WHITE='\033[1;37m'

# Reset Color
NC='\033[0m' # No Color

# --- Logger Functions ---
log_info() { printf "${BOLD_BLUE}[INFO]${NC} %s\n" "$1" | tee -a "$LOG_FILE"; }
log_warn() { printf "${BOLD_YELLOW}[WARN]${NC} %s\n" "$1" | tee -a "$LOG_FILE"; }
log_error() { printf "${BOLD_RED}[ERROR]${NC} %s\n" "$1" | tee -a "$LOG_FILE"; }
log_success() { printf "${BOLD_GREEN}[SUCCESS]${NC} %s\n" "$1" | tee -a "$LOG_FILE"; }

# --- Helper Functions ---

# Initialize the log file
init_log() {
  mkdir -p "$(dirname "$LOG_FILE")"
  echo "=== Hyprland-Wallust Installation Log - $(date) ===" > "$LOG_FILE"
}

# Handle fatal errors
die() {
  log_error "$1"
  exit 1
}

# Check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Check if we're running as root (which we should not be)
check_not_root() {
  if [[ $EUID -eq 0 ]]; then
    die "This script should not be run as root. Please run as a normal user."
  fi
}

# Ask yes/no questions
ask_yes_no() {
  local prompt="$1"
  local default="${2:-}"
  local response
  
  # Add default option to prompt if provided
  if [[ "$default" == "y" ]]; then
    prompt="${BOLD_GREEN}$prompt [Y/n]${NC}"
  elif [[ "$default" == "n" ]]; then
    prompt="${BOLD_RED}$prompt [y/N]${NC}"
  else
    prompt="${BOLD_CYAN}$prompt [y/n]${NC}"
  fi
  
  while true; do
    read -rp "$prompt: " response
    
    # Handle empty responses with defaults
    if [[ -z "$response" && -n "$default" ]]; then
      response="$default"
    fi
    
    case "${response,,}" in
      y|yes) return 0 ;;
      n|no) return 1 ;;
      *) log_warn "Invalid input. Please type y or n." ;;
    esac
  done
}

# Select from multiple options
select_option() {
  local prompt="$1"
  shift
  local options=("$@")
  local choice
  
  echo -e "${BOLD_CYAN}$prompt${NC}"
  for i in "${!options[@]}"; do
    echo -e "  ${BOLD_GREEN}$((i+1))${NC}. ${options[$i]}"
  done
  
  while true; do
    read -rp "Enter selection [1-${#options[@]}]: " choice
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#options[@]}" ]; then
      echo "${options[$((choice-1))]}"
      return 0
    else
      log_warn "Invalid selection. Please enter a number between 1 and ${#options[@]}."
    fi
  done
}

# Show spinner
show_spinner() {
  local pid=$1
  local delay=0.1
  local spinstr='|/-\'
  while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
    local temp=${spinstr#?}
    printf " [%c]  " "$spinstr"
    local spinstr=$temp${spinstr%"$temp"}
    sleep $delay
    printf "\b\b\b\b\b\b"
  done
  printf "    \b\b\b\b"
}

# --- Package Management ---

# Check if a package exists in repositories
package_in_repos() {
  pacman -Si "$1" >/dev/null 2>&1
}

# Check if a package is installed
package_installed() {
  pacman -Qi "$1" >/dev/null 2>&1
}

# Install a package with pacman
install_with_pacman() {
  local pkg="$1"
  log_info "Installing $pkg with pacman..."
  sudo pacman -S --needed --noconfirm "$pkg" || die "Failed to install $pkg"
  package_installed "$pkg" || die "Package $pkg installation verification failed"
  log_success "$pkg installed successfully"
}

# Install a package with paru
install_with_paru() {
  local pkg="$1"
  log_info "Installing $pkg with paru..."
  paru -S --needed --noconfirm "$pkg" || die "Failed to install $pkg"
  package_installed "$pkg" || die "Package $pkg installation verification failed"
  log_success "$pkg installed successfully"
}

# Smart package installation
install_package() {
  local pkg="$1"
  
  # Skip if already installed
  if package_installed "$pkg"; then
    log_info "Package $pkg is already installed"
    return 0
  fi
  
  # Use pacman for official repos, paru for AUR
  if package_in_repos "$pkg"; then
    install_with_pacman "$pkg"
  else
    if ! command_exists paru; then
      die "Package $pkg not found in official repositories and paru is not installed"
    fi
    install_with_paru "$pkg"
  fi
}

# Install multiple packages at once
install_packages() {
  local packages=("$@")
  local to_install=()
  
  # Check which packages need to be installed
  for pkg in "${packages[@]}"; do
    if ! package_installed "$pkg"; then
      to_install+=("$pkg")
    fi
  done
  
  # Skip if all packages are already installed
  if [[ ${#to_install[@]} -eq 0 ]]; then
    log_info "All packages already installed: ${packages[*]}"
    return 0
  fi
  
  # Install missing packages
  log_info "Installing packages: ${to_install[*]}"
  
  # Use either pacman or paru based on package availability
  local pacman_pkgs=()
  local paru_pkgs=()
  
  for pkg in "${to_install[@]}"; do
    if package_in_repos "$pkg"; then
      pacman_pkgs+=("$pkg")
    else
      paru_pkgs+=("$pkg")
    fi
  done
  
  # Install packages from official repos with pacman
  if [[ ${#pacman_pkgs[@]} -gt 0 ]]; then
    log_info "Installing from official repositories: ${pacman_pkgs[*]}"
    sudo pacman -S --needed --noconfirm "${pacman_pkgs[@]}" || die "Failed to install packages: ${pacman_pkgs[*]}"
  fi
  
  # Install packages from AUR with paru
  if [[ ${#paru_pkgs[@]} -gt 0 ]]; then
    if ! command_exists paru; then
      die "Cannot install AUR packages without paru. Please install paru first."
    fi
    log_info "Installing from AUR: ${paru_pkgs[*]}"
    paru -S --needed --noconfirm "${paru_pkgs[@]}" || die "Failed to install packages: ${paru_pkgs[*]}"
  fi
  
  # Verify all installations
  local failed=()
  for pkg in "${to_install[@]}"; do
    if ! package_installed "$pkg"; then
      failed+=("$pkg")
    fi
  done
  
  if [[ ${#failed[@]} -gt 0 ]]; then
    die "Failed to install packages: ${failed[*]}"
  fi
  
  log_success "Successfully installed all packages"
}

# --- Repository Management ---

# Clone or update a git repository
clone_or_update_repo() {
  local repo_url="$1"
  local target_dir="$2"
  
  if [[ -d "$target_dir/.git" ]]; then
    log_info "Repository already exists at $target_dir. Updating..."
    (cd "$target_dir" && git pull) || die "Failed to update repository at $target_dir"
    log_success "Repository updated successfully"
    return 0
  elif [[ -e "$target_dir" ]]; then
    die "$target_dir exists but is not a git repository"
  fi
  
  log_info "Cloning repository from $repo_url to $target_dir..."
  git clone --depth=1 "$repo_url" "$target_dir" || die "Failed to clone $repo_url"
  log_success "Repository cloned successfully"
}

# --- Dotfiles Management ---

# Symlink dotfiles using GNU Stow
symlink_dotfiles() {
  local source_dir="$1"
  local target_dir="${2:-$HOME}"
  local log_file="${3:-stow_output.log}"
  
  log_info "Symlinking dotfiles from $source_dir to $target_dir..."
  
  # Make sure we're in the source directory
  cd "$source_dir" || die "Failed to navigate to $source_dir"
  
  # Run stow and capture output
  stow -v -t "$target_dir" . 2>&1 | tee "$log_file"
  
  # Check exit status
  if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
    die "Stow failed to symlink files. Check $log_file for details."
  fi
  
  log_success "Dotfiles symlinked successfully"
}

# --- GPU Management ---

# Install GPU drivers
install_gpu_drivers() {
  log_info "Setting up GPU drivers..."
  
  local options=("NVIDIA" "AMD" "Intel" "Skip")
  local choice
  
  choice=$(select_option "Select your GPU:" "${options[@]}")
  
  case "$choice" in
    "NVIDIA")
      install_packages "nvidia-open-dkms" "nvidia-utils" "nvidia-settings"
      ;;
    "AMD")
      log_info "No additional drivers needed for AMD"
      ;;
    "Intel")
      install_packages "intel-media-driver" "vulkan-intel" "thermald"
      log_info "Enabling thermald service..."
      sudo systemctl enable --now thermald || log_warn "Failed to enable thermald"
      ;;
    "Skip")
      log_info "Skipping GPU driver installation"
      ;;
  esac
}

# --- Shell Configuration ---

# Configure shell
configure_shell() {
  local current_shell
  local fish_path
  
  log_info "Checking shell configuration..."
  
  current_shell=$(getent passwd "$USER" | cut -d: -f7)
  fish_path=$(command -v fish 2>/dev/null)
  
  if [[ -z "$fish_path" ]]; then
    if ask_yes_no "Fish shell is not installed. Would you like to install it" "y"; then
      install_package "fish"
      fish_path=$(command -v fish)
      
      if [[ -z "$fish_path" ]]; then
        die "Fish shell installation failed"
      fi
    else
      log_info "Skipping fish shell installation"
      return 0
    fi
  fi
  
  if [[ "$current_shell" != "$fish_path" ]]; then
    if ask_yes_no "Would you like to change your default shell to fish" "y"; then
      sudo chsh -s "$fish_path" "$USER" || die "Failed to change shell to fish"
      log_success "Shell changed to fish. Changes will take effect on next login."
    else
      log_info "Keeping current shell: $current_shell"
    fi
  else
    log_info "Your default shell is already fish"
  fi
}

# --- Service Management ---

# Enable and start a systemd service
enable_service() {
  local service="$1"
  local type="${2:-system}"  # Default to system service
  
  log_info "Enabling $type service: $service..."
  
  if [[ "$type" == "user" ]]; then
    systemctl --user enable --now "$service" || {
      log_warn "Failed to enable/start user service $service"
      return 1
    }
  else
    sudo systemctl enable --now "$service" || {
      log_warn "Failed to enable/start system service $service"
      return 1
    }
  fi
  
  log_success "Service $service enabled successfully"
  return 0
}

# Setup all required services
setup_services() {
  log_info "Setting up services..."
  
  # Define services with their types
  local services=(
    "mpd:user"
    "firewalld:system"
    "vnstat:system"
    "power-profiles-daemon:system"
    "bluetooth:system"
  )
  
  local failed=()
  
  for service_entry in "${services[@]}"; do
    local service_name="${service_entry%%:*}"
    local service_type="${service_entry##*:}"
    
    enable_service "$service_name" "$service_type" || failed+=("$service_name")
  done
  
  if [[ ${#failed[@]} -gt 0 ]]; then
    log_warn "Failed to enable some services: ${failed[*]}"
  else
    log_success "All services enabled successfully"
  fi
}

# --- Package Installation from Files ---

# Install packages from a file
install_packages_from_file() {
  local file_path="$1"
  local packages=()
  
  if [[ ! -r "$file_path" ]]; then
    log_warn "Package file $file_path not found or not readable"
    return 1
  }
  
  log_info "Reading packages from $file_path..."
  
  # Read packages from file, skipping comments and empty lines
  while IFS= read -r line || [[ -n "$line" ]]; do
    # Skip comments and empty lines
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
    
    # Trim whitespace
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"
    
    [[ -n "$line" ]] && packages+=("$line")
  done < "$file_path"
  
  if [[ ${#packages[@]} -eq 0 ]]; then
    log_warn "No packages found in $file_path"
    return 0
  }
  
  log_info "Installing ${#packages[@]} packages from $file_path..."
  install_packages "${packages[@]}"
}

# --- Paru Installation ---

# Install paru AUR helper
install_paru() {
  if command_exists paru; then
    log_info "Paru is already installed"
    return 0
  fi
  
  log_info "Installing paru AUR helper..."
  
  # Make sure base-devel is installed
  install_package "base-devel" || die "Failed to install base-devel"
  
  # Create a temporary directory
  local temp_dir
  temp_dir=$(mktemp -d) || die "Failed to create temporary directory"
  
  # Ensure cleanup on exit
  trap 'rm -rf "$temp_dir"' EXIT
  
  # Clone paru repository
  log_info "Cloning paru repository..."
  git clone --depth=1 https://aur.archlinux.org/paru.git "$temp_dir" || die "Failed to clone paru repository"
  
  # Build and install paru
  log_info "Building and installing paru..."
  (cd "$temp_dir" && makepkg -si --noconfirm) || die "Failed to build and install paru"
  
  # Verify installation
  command_exists paru || die "Paru installation verification failed"
  
  log_success "Paru installed successfully"
}

# --- Flatpak Setup ---

# Setup Flatpak
setup_flatpak() {
  if ! ask_yes_no "Do you want to install Flatpak" "y"; then
    log_info "Skipping Flatpak installation"
    return 0
  fi
  
  log_info "Setting up Flatpak..."
  
  # Install Flatpak
  install_package "flatpak" || die "Failed to install Flatpak"
  
  # Add Flathub repository
  log_info "Adding Flathub repository..."
  flatpak --user remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || log_warn "Failed to add Flathub repository"
  
  log_success "Flatpak setup completed successfully"
}

# --- Display Welcome Screen ---
display_welcome_screen() {
  # Clear the screen
  clear
  
  # Display ASCII art and welcome message
  cat <<'EOF'
${BOLD_CYAN}
 ██╗  ██╗██╗   ██╗██████╗ ██████╗ ██╗      █████╗ ███╗   ██╗██████╗        
 ██║  ██║╚██╗ ██╔╝██╔══██╗██╔══██╗██║     ██╔══██╗████╗  ██║██╔══██╗       
 ███████║ ╚████╔╝ ██████╔╝██████╔╝██║     ███████║██╔██╗ ██║██║  ██║       
 ██╔══██║  ╚██╔╝  ██╔═══╝ ██╔══██╗██║     ██╔══██║██║╚██╗██║██║  ██║       
 ██║  ██║   ██║   ██║     ██║  ██║███████╗██║  ██║██║ ╚████║██████╔╝       
 ╚═╝  ╚═╝   ╚═╝   ╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═════╝        
                                                                            
 ██╗    ██╗ █████╗ ██╗     ██╗     ██╗   ██╗███████╗████████╗              
 ██║    ██║██╔══██╗██║     ██║     ██║   ██║██╔════╝╚══██╔══╝              
 ██║ █╗ ██║███████║██║     ██║     ██║   ██║███████╗   ██║                 
 ██║███╗██║██╔══██║██║     ██║     ██║   ██║╚════██║   ██║                 
 ╚███╔███╔╝██║  ██║███████╗███████╗╚██████╔╝███████║   ██║                 
  ╚══╝╚══╝ ╚═╝  ╚═╝╚══════╝╚══════╝ ╚═════╝ ╚══════╝   ╚═╝                 
${NC}

${BOLD_GREEN}┌─────────────────────────────────────────────────────────────┐
│                 Automatic Installation Script                │
│                                                             │
│  This script will set up a complete Hyprland environment    │
│  with Wallust theme configuration. It includes:             │
│                                                             │
│  • Hyprland Wayland Compositor                              │
│  • Wallust dynamic theming                                  │
│  • Required drivers and dependencies                        │
│  • Shell configuration                                      │
│  • Dotfiles symlinked to your home directory                │
└─────────────────────────────────────────────────────────────┘${NC}

${BOLD_YELLOW}Version: 1.0.0
Author: helixoid
Repository: ${REPO_URL}${NC}

EOF
  
  # Sleep for a moment to let the user read
  sleep 2
  
  echo -e "${BOLD_PURPLE}System Information:${NC}"
  echo -e "${BOLD_BLUE}• OS:${NC} $(grep "PRETTY_NAME" /etc/os-release | cut -d= -f2 | tr -d '"')"
  echo -e "${BOLD_BLUE}• Kernel:${NC} $(uname -r)"
  echo -e "${BOLD_BLUE}• Architecture:${NC} $(uname -m)"
  echo -e "${BOLD_BLUE}• User:${NC} $(whoami)"
  echo -e "${BOLD_BLUE}• Hostname:${NC} $(hostname)"
  echo ""
  
  echo -e "${BOLD_RED}Note: This script will make changes to your system.${NC}"
  echo -e "${BOLD_RED}It is recommended to back up your data before proceeding.${NC}"
  echo ""
  
  # Confirm before proceeding
  if ! ask_yes_no "Ready to proceed with the installation" "n"; then
    echo -e "${BOLD_YELLOW}Installation cancelled by user.${NC}"
    exit 0
  fi
  
  echo ""
}

# --- Show completion screen ---
show_completion_screen() {
  clear
  
  cat <<'EOF'
${BOLD_GREEN}
 ██╗███╗   ██╗███████╗████████╗ █████╗ ██╗     ██╗      █████╗ ████████╗██╗ ██████╗ ███╗   ██╗
 ██║████╗  ██║██╔════╝╚══██╔══╝██╔══██╗██║     ██║     ██╔══██╗╚══██╔══╝██║██╔═══██╗████╗  ██║
 ██║██╔██╗ ██║███████╗   ██║   ███████║██║     ██║     ███████║   ██║   ██║██║   ██║██╔██╗ ██║
 ██║██║╚██╗██║╚════██║   ██║   ██╔══██║██║     ██║     ██╔══██║   ██║   ██║██║   ██║██║╚██╗██║
 ██║██║ ╚████║███████║   ██║   ██║  ██║███████╗███████╗██║  ██║   ██║   ██║╚██████╔╝██║ ╚████║
 ╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝╚═╝  ╚═╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝
                                                                                              
  ██████╗ ██████╗ ███╗   ███╗██████╗ ██╗     ███████╗████████╗███████╗██╗                    
 ██╔════╝██╔═══██╗████╗ ████║██╔══██╗██║     ██╔════╝╚══██╔══╝██╔════╝██║                    
 ██║     ██║   ██║██╔████╔██║██████╔╝██║     █████╗     ██║   █████╗  ██║                    
 ██║     ██║   ██║██║╚██╔╝██║██╔═══╝ ██║     ██╔══╝     ██║   ██╔══╝  ╚═╝                    
 ╚██████╗╚██████╔╝██║ ╚═╝ ██║██║     ███████╗███████╗   ██║   ███████╗██╗                    
  ╚═════╝ ╚═════╝ ╚═╝     ╚═╝╚═╝     ╚══════╝╚══════╝   ╚═╝   ╚══════╝╚═╝                    
${NC}

${BOLD_CYAN}┌─────────────────────────────────────────────────────────────┐
│           Installation completed successfully!              │
│                                                             │
│  • Your dotfiles have been symlinked                        │
│  • Services have been enabled                               │
│  • All required packages have been installed                │
│                                                             │
│  You can now reboot your system to apply all changes.       │
│  After reboot, you can start Hyprland by using 'Hyprland'   │
│  command or through your display manager.                   │
└─────────────────────────────────────────────────────────────┘${NC}

${BOLD_YELLOW}Installation Log: ${LOG_FILE}
Dotfiles Location: ${DOTFILES_DIR}${NC}

${BOLD_PURPLE}Thank you for using this installation script!${NC}
${BOLD_PURPLE}For issues or questions: https://github.com/helixoid/hyprland-wallust/issues${NC}

EOF
}

# --- Progress Bar ---
show_progress_bar() {
  local current=$1
  local total=$2
  local label="$3"
  local cols=$(tput cols)
  local bar_size=$((cols - 30))
  local completed=$((current * bar_size / total))
  local percentage=$((current * 100 / total))
  
  printf "\r${BOLD_BLUE}[${NC}"
  
  for ((i=0; i<bar_size; i++)); do
    if [ $i -lt $completed ]; then
      printf "${BOLD_GREEN}▓${NC}"
    else
      printf "${BOLD_BLACK}▒${NC}"
    fi
  done
  
  printf "${BOLD_BLUE}]${NC} ${BOLD_GREEN}%3d%%${NC} ${CYAN}%s${NC}" "$percentage" "$label"
}

# --- Main Function ---

main() {
  # Initialize log
  init_log
  
  # Display welcome screen
  display_welcome_screen
  
  # Check if running as root
  check_not_root
  
  # Initial confirmation for package files - moved to the welcome screen
  
  # Install git if needed
  if ! command_exists git; then
    log_info "Git is required. Installing..."
    install_with_pacman "git" || die "Failed to install git"
  fi
  
  # Setup progress tracking
  local total_steps=8
  local current_step=0
  
  # Install paru
  ((current_step++))
  show_progress_bar $current_step $total_steps "Installing paru AUR helper..."
  install_paru
  echo ""
  
  # Install essential packages
  ((current_step++))
  show_progress_bar $current_step $total_steps "Installing essential packages..."
  install_packages "stow" "linux-headers"
  echo ""
  
  # Install GPU drivers
  ((current_step++))
  show_progress_bar $current_step $total_steps "Setting up GPU drivers..."
  install_gpu_drivers
  echo ""
  
  # Clone dotfiles repository
  ((current_step++))
  show_progress_bar $current_step $total_steps "Cloning dotfiles repository..."
  clone_or_update_repo "$REPO_URL" "$DOTFILES_DIR"
  echo ""
  
  # Setup Flatpak
  ((current_step++))
  show_progress_bar $current_step $total_steps "Setting up Flatpak..."
  setup_flatpak
  echo ""
  
  # Install packages from files
  ((current_step++))
  show_progress_bar $current_step $total_steps "Installing packages..."
  cd "$DOTFILES_DIR" || die "Failed to navigate to $DOTFILES_DIR"
  
  # Install regular packages
  if [[ -r "$PACKAGES_FILE" ]]; then
    install_packages_from_file "$PACKAGES_FILE"
  else
    log_warn "Packages file $PACKAGES_FILE not found in $DOTFILES_DIR"
  fi
  
  # Install gaming packages if Flatpak is available
  if command_exists flatpak && [[ -r "$GAMING_FILE" ]]; then
    install_packages_from_file "$GAMING_FILE"
  elif [[ -r "$GAMING_FILE" ]]; then
    log_warn "Flatpak is required for gaming packages. Skipping $GAMING_FILE"
  fi
  echo ""
  
  # Symlink dotfiles
  ((current_step++))
  show_progress_bar $current_step $total_steps "Symlinking dotfiles..."
  symlink_dotfiles "$DOTFILES_DIR" "$HOME"
  echo ""
  
  # Setup services and shell
  ((current_step++))
  show_progress_bar $current_step $total_steps "Setting up services and shell..."
  setup_services
  configure_shell
  echo ""
  
  # Show completion screen
  show_completion_screen
  
  # Prompt for reboot
  if ask_yes_no "Would you like to reboot now to apply all changes" "y"; then
    log_info "Rebooting system..."
    sudo reboot
  else
    log_info "Skipping reboot. Please reboot manually when convenient."
  fi
}

# Call main function
main "$@"
