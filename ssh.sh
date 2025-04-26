#!/bin/bash
#
# SSH Setup Script for Ubuntu
# Configures SSH and keychain for easier SSH management
#

# Source the print utility functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/utils/print.sh"

# Install required packages if missing
print_info "Checking required tools..."

# Check for required packages
REQUIRED_PACKAGES="openssh-server ufw keychain"
MISSING_PACKAGES=""

for pkg in $REQUIRED_PACKAGES; do
  if ! dpkg -l | grep -q "ii  $pkg "; then
    MISSING_PACKAGES="$MISSING_PACKAGES $pkg"
  fi
done

if [ -n "$MISSING_PACKAGES" ]; then
  print_info "Installing missing packages:$MISSING_PACKAGES"
  sudo apt update && sudo apt install -y $MISSING_PACKAGES
  print_success "Required packages installed"
else
  print_success "All required packages already installed"
fi

# Enable SSH service on Ubuntu
print_info "Configuring SSH service..."
if ! systemctl is-enabled ssh >/dev/null 2>&1; then
  sudo systemctl enable ssh
  sudo systemctl start ssh
  print_success "SSH service enabled and started"
else
  print_success "SSH service already enabled"
fi

# Configure firewall for SSH
print_info "Configuring firewall..."
if ! sudo ufw status | grep -q "22/tcp.*ALLOW"; then
  sudo ufw allow ssh
  print_success "SSH allowed through firewall"
else
  print_success "SSH already allowed through firewall"
fi

# Set up SSH directory and config
print_info "Setting up SSH configuration..."
SSH_DIR="$HOME/.ssh"
SSH_CONFIG="$SSH_DIR/config"
SSH_CONFIG_TEMPLATE="${SCRIPT_DIR}/assets/ssh_config"

# Create .ssh directory if it doesn't exist
mkdir -p "$SSH_DIR"

# Backup existing config if it exists
if [ -f "$SSH_CONFIG" ]; then
  cp "$SSH_CONFIG" "${SSH_CONFIG}.bak"
  print_info "Backed up existing SSH config to ${SSH_CONFIG}.bak"
fi

# Copy the template
cp "$SSH_CONFIG_TEMPLATE" "$SSH_CONFIG"
print_success "SSH config updated from template"

# Set proper permissions
chmod 700 "$SSH_DIR"
chmod 600 "$SSH_CONFIG"
print_success "SSH permissions set correctly"

# Setup keychain in shell config
SHELL_RC="$HOME/.bashrc"
if [ -f "$HOME/.zshrc" ]; then
  SHELL_RC="$HOME/.zshrc"
fi

if ! grep -q "keychain --eval --quiet" "$SHELL_RC"; then
  echo "" >>"$SHELL_RC"
  echo "# Start SSH agent with keychain" >>"$SHELL_RC"
  echo "eval \$(keychain --eval --quiet)" >>"$SHELL_RC"
  print_success "Added keychain initialization to $SHELL_RC"
else
  print_success "Keychain initialization already configured"
fi

print_success "SSH agent configuration with keychain is complete"
print_info "Your SSH keys will be automatically added to the agent when used"
