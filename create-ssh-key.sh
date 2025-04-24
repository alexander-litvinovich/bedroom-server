#!/bin/bash

# Define the key name as a variable for easy modification
KEY_NAME="gitkey"
PUBLIC_KEY_PATH="$HOME/.ssh/$KEY_NAME"
PUBLIC_KEY_PATH_PUB="$HOME/.ssh/$KEY_NAME.pub"
PUBLIC_KEY_EXPORT="$KEY_NAME"_public.txt

# Check if .env file exists, create it if it doesn't
if [ ! -f ./.env ]; then
  echo "No .env file found. Creating one..."
  echo -n "Enter your Git email address: "
  read email
  echo "GIT_EMAIL=$email" >./.env
  echo ".env file created with Git email."
fi

# Load email from .env file
. ./.env

# Make sure .ssh directory exists
if [ ! -d ~/.ssh ]; then
  mkdir -p ~/.ssh
  chmod 700 ~/.ssh
  echo "Created ~/.ssh directory with proper permissions."
fi

# Check if SSH keys with the specified name already exist
if [ -f "$PUBLIC_KEY_PATH" ] && [ -f "$PUBLIC_KEY_PATH_PUB" ]; then
  echo "SSH keys with name '$KEY_NAME' already exist."
else
  # Generate SSH key
  echo "Generating SSH key..."
  ssh-keygen -t ed25519 -C "$GIT_EMAIL" -f "$PUBLIC_KEY_PATH" -N ""
  echo "SSH key '$KEY_NAME' generated."

  # Set proper permissions for SSH keys
  chmod 600 "$PUBLIC_KEY_PATH"
  chmod 644 "$PUBLIC_KEY_PATH_PUB"
fi

# Add the SSH key to the ssh-agent
echo "Adding SSH key to ssh-agent..."
# Check if ssh-agent is running, start it if not
if ! ps -p $SSH_AGENT_PID >/dev/null 2>&1; then
  eval "$(ssh-agent -s)"
fi
ssh-add "$PUBLIC_KEY_PATH" 2>/dev/null || echo "Could not add key to ssh-agent. You may need to add it manually."

# Display the public key prominently for manual copying
echo ""
echo "=================================================================="
echo "                     YOUR SSH PUBLIC KEY                          "
echo "=================================================================="
echo ""
cat "$PUBLIC_KEY_PATH_PUB"
echo ""
echo "=================================================================="
echo "     COPY THE ENTIRE KEY ABOVE (INCLUDING ssh-ed25519 PREFIX)     "
echo "=================================================================="
echo ""

# Ubuntu Server & general Linux support for clipboard
if [[ "$OSTYPE" == "darwin"* ]]; then
  if command -v pbcopy &>/dev/null; then
    pbcopy <"$PUBLIC_KEY_PATH_PUB"
    echo "SSH public key copied to clipboard using pbcopy."
  fi
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  if command -v xclip &>/dev/null; then
    xclip -selection clipboard <"$PUBLIC_KEY_PATH_PUB"
    echo "SSH public key copied to clipboard using xclip."
  elif command -v wl-copy &>/dev/null; then
    wl-copy <"$PUBLIC_KEY_PATH_PUB"
    echo "SSH public key copied to clipboard using wl-copy."
  fi
fi
