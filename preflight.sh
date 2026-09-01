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

# Software distributed via APT and not yet managed by Ansible
sudo apt-get install -y toilet boxes

# Software w/ install bash scripts
install "tailscale" "curl -fsSL https://tailscale.com/install.sh | sh"
install "lazydocker" "curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash"
install "ollama" "curl -fsSL https://ollama.com/install.sh | sh"
zsh -c "export XRDP_USER=\"$XRDP_USER\" && \"$INSTALLS_DIR/xrdp.sh\""
