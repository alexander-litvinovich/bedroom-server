#!/bin/bash
#
# Bedroom Server Preflight Script
# -----------------------------
# This script performs initial setup for the bedroom server by installing
# necessary tools and dependencies.

# The script uses utility functions from command.sh to check for and
# install required software packages.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/utils/command.sh"

# Software distributed via APT
sudo apt-get install -y toilet boxes mc zsh

# Install Oh My Zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "Installing Oh My Zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# Software w/ install bash scripts
install "tailscale" "curl -fsSL https://tailscale.com/install.sh | sh"
install "docker" "./docker.sh"
install "lazydocker" "curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash"
