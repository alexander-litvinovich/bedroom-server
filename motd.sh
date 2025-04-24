#!/bin/bash

# motd.sh - Script to set up a custom Message of the Day (MOTD) for SSH connections
# For Ubuntu 24.04 on HP Prodesk 405 G4 Mini bedroom server

set -e

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root. Use sudo."
  exit 1
fi

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
DYNAMIC_MOTD_SOURCE="$SCRIPT_DIR/assets/dynamic-motd.sh"
MOTD_DIR="/etc/update-motd.d"
DYNAMIC_MOTD_DEST="$MOTD_DIR/99-custom-stats"

# First-time setup (only if destination doesn't exist)
if [ ! -f "$DYNAMIC_MOTD_DEST" ]; then
  echo "First time setup: Installing custom MOTD..."

  # Backup original MOTD configuration
  BACKUP_DIR="/etc/motd.backup.$(date +%Y%m%d%H%M%S)"
  mkdir -p $BACKUP_DIR

  if [ -f /etc/motd ]; then
    cp /etc/motd $BACKUP_DIR/
    echo "Backed up original /etc/motd"

    # Remove the static MOTD file since we're using only dynamic MOTD
    rm -f /etc/motd
    echo "Removed static MOTD file"
  fi

  # Disable default MOTD scripts if they exist
  if [ -d "$MOTD_DIR" ]; then
    cp -r $MOTD_DIR $BACKUP_DIR/
    echo "Backed up original MOTD scripts"

    # Disable default MOTD scripts by removing execute permission
    chmod -x $MOTD_DIR/*
    echo "Disabled default MOTD scripts"
  fi

  # Check if we should disable the Ubuntu news/ads in MOTD
  if [ -f /etc/default/motd-news ]; then
    sed -i 's/ENABLED=1/ENABLED=0/' /etc/default/motd-news
    echo "Disabled Ubuntu MOTD news"
  fi

  echo "Initial MOTD setup complete!"
fi

# Check if the dynamic MOTD script exists
if [ ! -f "$DYNAMIC_MOTD_SOURCE" ]; then
  echo "Error: dynamic-motd.sh not found in the assets directory"
  echo "Please make sure it exists at: $DYNAMIC_MOTD_SOURCE"
  exit 1
fi

# Check if we need to update the dynamic MOTD script
if [ ! -f "$DYNAMIC_MOTD_DEST" ] || ! cmp -s "$DYNAMIC_MOTD_SOURCE" "$DYNAMIC_MOTD_DEST"; then
  # Copy our dynamic MOTD script to the server
  cp "$DYNAMIC_MOTD_SOURCE" "$DYNAMIC_MOTD_DEST"
  chmod +x "$DYNAMIC_MOTD_DEST"
  echo "Updated dynamic MOTD script"
else
  echo "Dynamic MOTD script is already up to date"
fi

echo "Your custom message will display on SSH login."
echo "To test, try connecting to your server via SSH."
