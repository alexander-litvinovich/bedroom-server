#!/bin/bash
#
# Immich Installation Script
# -------------------------
# This script installs and configures the Immich application

# Source utility scripts
source "$UTILS_DIR/print.sh"

local IMMICH_DIR="$HOME/.immich-app/"

if [ ! -d "$IMMICH_DIR" ]; then
  print_info "Creating Immich directory at $IMMICH_DIR"
  mkdir -p $IMMICH_DIR

  print_info "Downloading latest Immich docker-compose.yml"
  curl -L -o "$IMMICH_DIR/docker-compose.yml" https://github.com/immich-app/immich/releases/latest/download/docker-compose.yml

  print_info "Copying example .env file"
  cp "$ASSETS_DIR/immich.example.env" "$IMMICH_DIR/.env"

  # Prompt the user for the PostgreSQL password. If no input, use 'postgres' as default
  read -p "Enter your PostgreSQL password (default is 'postgres'): " postgres_password

  if [ -z "$postgres_password" ]; then
    postgres_password="postgres"
  fi

  # Update the .env file with the password
  sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=$postgres_password/" "$IMMICH_DIR/.env"

  print_success "PostgreSQL password has been set in the .env file."
else
  print_info "Immich directory already exists at $IMMICH_DIR"
fi
