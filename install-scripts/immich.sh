#!/bin/bash

# Install immich app

source "$(dirname "${BASH_SOURCE[0]}")/../utils/paths.sh"
IMMICH_DIR="$HOME/.immich-app/"

if [ ! -d "$IMMICH_DIR" ]; then
  mkdir -p $IMMICH_DIR
  curl -L -o "$IMMICH_DIR/docker-compose.yml" https://github.com/immich-app/immich/releases/latest/download/docker-compose.yml
  cp "$ASSETS_DIR/immich.example.env" "$IMMICH_DIR/.env"

  # Prompt the user for the PostgreSQL password. If no input, use 'postgres' as default
  read -p "Enter your PostgreSQL password (default is 'postgres'): " postgres_password

  if [ -z "$postgres_password" ]; then
    postgres_password="postgres"
  fi

  # Update the .env file with the password
  sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=$postgres_password/" "$IMMICH_DIR/.env"

  echo "PostgreSQL password has been set in the .env file."
fi
