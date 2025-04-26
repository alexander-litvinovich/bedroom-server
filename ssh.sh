#!/bin/bash

# Install SSH server and related tools
sudo apt update && sudo apt install openssh-server ufw keychain
sudo systemctl enable ssh
sudo ufw allow ssh

# Add keychain initialization to .zshrc for Oh My Zsh
if ! grep -q "keychain --eval --quiet" "$HOME/.zshrc"; then
  echo "# Start SSH agent with keychain" >>"$HOME/.zshrc"
  echo "eval \$(keychain --eval --quiet)" >>"$HOME/.zshrc"
  echo "Added keychain initialization to .zshrc"
fi

# Configure SSH to use template from assets - simplified approach
mkdir -p "$HOME/.ssh"
SSH_CONFIG="$HOME/.ssh/config"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SSH_CONFIG_TEMPLATE="${SCRIPT_DIR}/assets/ssh_config"

# Always back up existing config if it exists
if [ -f "$SSH_CONFIG" ]; then
  cp "$SSH_CONFIG" "${SSH_CONFIG}.bak"
  echo "Backed up existing SSH config to ${SSH_CONFIG}.bak"
fi

# Simply copy the template, overwriting any existing config
cp "$SSH_CONFIG_TEMPLATE" "$SSH_CONFIG"
echo "Updated SSH config from template"

# Set proper permissions for SSH directory and config
chmod 700 "$HOME/.ssh"
chmod 600 "$SSH_CONFIG"

echo "SSH agent configuration with keychain is complete"
echo "Your SSH keys will be automatically added to the agent when used"
