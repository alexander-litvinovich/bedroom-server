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
install "ollama" "curl -fsSL https://ollama.com/install.sh | sh"
zsh -c "export IMMICH_PG_PASS=\"$IMMICH_PG_PASS\" && \"$INSTALLS_DIR/immich.sh\""
zsh -c "export PIHOLE_PASS=\"$PIHOLE_PASS\" && \"$INSTALLS_DIR/pi-hole.sh\""
zsh "$INSTALLS_DIR/nginx-proxy-manager.sh"
zsh -c "export XRDP_USER=\"$XRDP_USER\" && \"$INSTALLS_DIR/xrdp.sh\""
zsh -c "export N8N_DATA_DIR=\"$N8N_DATA_DIR\" && \"$INSTALLS_DIR/n8n.sh\""
