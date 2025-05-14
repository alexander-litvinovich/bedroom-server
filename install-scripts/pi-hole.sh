#!/bin/zsh
#
# PI-HOLE INSTALLATION SCRIPT
# Installs Pi-hole using Docker Compose
#

# Source utility scripts
source "$(dirname "${BASH_SOURCE[0]}")/../utils/paths.sh"
source "$UTILS_DIR/print.sh"

# Constants
pihole_dir="$HOME/.pi-hole"
pihole_env_file="$pihole_dir/.env"

print_header "Pi-hole Installation"

# Check if Pi-hole directory already exists
if [ ! -d "$pihole_dir" ]; then
  print_info "Creating Pi-hole directory at $pihole_dir"
  mkdir -p "$pihole_dir"

  # Copy Docker Compose file
  print_info "Copying Docker Compose configuration"
  cp "$ASSETS_DIR/pi-hole.docker-compose.yaml" "$pihole_dir/docker-compose.yaml"
  cp "$ASSETS_DIR/pi-hole.example.env" "$pihole_env_file"

  # Prompt for password, with default from environment variable
  print_info "Enter password for Pi-hole web interface (default is '$PIHOLE_PASS'): "
  read pihole_password

  if [ -z "$pihole_password" ]; then
    pihole_password="$PIHOLE_PASS"
  fi

  # Update the .env file with the password
  sed -i "s/FTLCONF_webserver_api_password=.*$/FTLCONF_webserver_api_password=$pihole_password/" "$pihole_env_file" ||
    echo "FTLCONF_webserver_api_password=$pihole_password" >>"$pihole_env_file"

  print_success "Pi-hole password has been set in the .env file."

  # Start Pi-hole
  print_info "Starting Pi-hole container"
  cd "$pihole_dir" || {
    print_error "Failed to change directory to $pihole_dir"
    exit 1
  }
  docker compose up -d

  if [ $? -eq 0 ]; then
    print_success "Pi-hole successfully installed and running"
    print_info "Access the web interface at http://localhost/admin"
  else
    print_error "Failed to start Pi-hole container"
    exit 1
  fi
else
  print_info "Pi-hole directory already exists at $pihole_dir"
  print_info "If you want to reinstall, please remove the directory first"
  exit 0
fi
