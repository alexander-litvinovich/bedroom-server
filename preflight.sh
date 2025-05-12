#!/bin/bash
#
# Bedroom Server Preflight Script
# -----------------------------
# This script performs initial setup for the bedroom server by installing
# necessary tools and dependencies.

# The script uses utility functions from command.sh to check for and
# install required software packages.

source ./.env
source "$(pwd)/utils/paths.sh"
source "$UTILS_DIR/command.sh"
source "$UTILS_DIR/print.sh"

# Software distributed via APT
sudo apt-get install -y toilet boxes mc zsh

# Software w/ install bash scripts
zsh "$INSTALLS_DIR/ohmyzsh.sh"
install "tailscale" "curl -fsSL https://tailscale.com/install.sh | sh"
install "docker" "$INSTALLS_DIR/docker.sh"
install "lazydocker" "curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash"
zsh "$INSTALLS_DIR/immich.sh"
