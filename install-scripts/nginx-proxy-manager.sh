#!/bin/zsh
#
# NGINX Proxy Manager INSTALLATION SCRIPT
# Installs NGINX Proxy Manager using Docker Compose
#

# Source utility scripts
source "$UTILS_DIR/print.sh"

# Constants
nginx_proxy_manager_dir="$HOME/.nginx-proxy-manager"

print_header "NGINX Proxy Manager Installation"

# Check if NGINX Proxy Manager directory already exists
if [ ! -d "$nginx_proxy_manager_dir" ]; then
  print_info "Creating NGINX Proxy Manager directory at $nginx_proxy_manager_dir"
  mkdir -p "$nginx_proxy_manager_dir"

  # Copy Docker Compose file
  print_info "Copying Docker Compose configuration"
  cp "$ASSETS_DIR/nginx-proxy-manager.docker-compose.yaml" "$nginx_proxy_manager_dir/docker-compose.yaml"

  # Start NGINX Proxy Manager
  print_info "Starting NGINX Proxy Manager container"
  cd "$nginx_proxy_manager_dir" || {
    print_error "Failed to change directory to $nginx_proxy_manager_dir"
    exit 1
  }
  docker compose up -d

  if [ $? -eq 0 ]; then
    print_success "NGINX Proxy Manager successfully installed and running"
  else
    print_error "Failed to start NGINX Proxy Manager container"
    exit 1
  fi
else
  print_info "NGINX Proxy Manager directory already exists at $nginx_proxy_manager_dir"
  print_info "If you want to reinstall, please remove the directory first"
  exit 0
fi
