#!/bin/bash
#
# n8n Installation Script
# -----------------------
# This script installs and configures the n8n workflow automation tool

# Source utility scripts
source "$UTILS_DIR/print.sh"

# Define n8n directories
n8n_dir="$HOME/.n8n-app"
n8n_data_dir="$N8N_DATA_DIR"

if [ ! -d "$n8n_dir" ]; then
  print_info "Setting up n8n..."

  # Create directories
  mkdir -p "$n8n_dir"
  mkdir -p "$n8n_data_dir"

  # Copy configuration files
  cp "$ASSETS_DIR/n8n_docker-compose.yml" "$n8n_dir/docker-compose.yml"
  cp "$ASSETS_DIR/n8n_example.env" "$n8n_dir/.env"

  # Generate security keys
  print_info "Generating security keys..."
  encryption_key=$(openssl rand -hex 32)
  jwt_secret=$(openssl rand -hex 32)

  # Configure environment with sensible defaults
  sed -i "s|N8N_DATA_DIR=.*|N8N_DATA_DIR=$n8n_data_dir|" "$n8n_dir/.env"
  sed -i "s/N8N_ENCRYPTION_KEY=.*/N8N_ENCRYPTION_KEY=$encryption_key/" "$n8n_dir/.env"
  sed -i "s/N8N_JWT_SECRET=.*/N8N_JWT_SECRET=$jwt_secret/" "$n8n_dir/.env"

  print_success "n8n configuration completed with default settings"
else
  print_info "n8n directory already exists at $n8n_dir"
fi

# Start n8n
cd "$n8n_dir"
print_info "Starting n8n with Docker Compose..."
docker compose up -d

if [ $? -eq 0 ]; then
  print_success "n8n started successfully!"
  print_info "Access n8n at: http://localhost:5678"
  print_info "Data directory: $n8n_data_dir"
  print_warning "First-time setup required - create your admin account via the web interface"
else
  print_error "Failed to start n8n. Check logs with: docker compose logs"
  exit 1
fi
