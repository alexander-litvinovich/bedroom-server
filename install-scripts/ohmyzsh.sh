#!/bin/zsh

source "$UTILS_DIR/print.sh"

# Install Oh My Zsh

if [ ! -d "$HOME/.oh-my-zsh" ]; then
  print_info "Installing Oh My Zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
  print_info "Oh My Zsh seems installed"
fi
