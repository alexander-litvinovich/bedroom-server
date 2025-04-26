#!/bin/bash

# Handy scripts

sudo apt-get install -y toilet boxes mc

# Check if zsh is installed
if ! command -v zsh &>/dev/null; then
  echo "zsh is not installed. Installing zsh..."
  apt-get install -y zsh
  echo "zsh installed successfully."

  # Install Oh My Zsh
  echo "Installing Oh My Zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
  echo "zsh is already installed."
fi
