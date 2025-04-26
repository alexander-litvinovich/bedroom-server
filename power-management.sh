#!/bin/bash
#==============================================================================
# POWER MANAGEMENT SCRIPT FOR UBUNTU
#==============================================================================
# Purpose: Configure Ubuntu power settings to:
#   1. Prevent system sleep/suspend
#   2. Configure power button to trigger system shutdown
#
# Works on: Both Ubuntu Desktop and Ubuntu Server
#==============================================================================

#------------------------------------------------------------------------------
# FUNCTIONS
#------------------------------------------------------------------------------

# Print colored messages for better readability
print_header() {
  echo -e "\n\033[1;34m==== $1 ====\033[0m"
}

print_success() {
  echo -e "\033[1;32m✓ $1\033[0m"
}

print_info() {
  echo -e "\033[1;36m→ $1\033[0m"
}

print_skip() {
  echo -e "\033[1;33m⤷ $1\033[0m"
}

# Configure desktop environment power settings
configure_desktop_settings() {
  print_header "DESKTOP ENVIRONMENT SETTINGS"

  # Check for GNOME
  if command -v gsettings &>/dev/null; then
    print_info "GNOME desktop detected"

    # Get current user to apply settings for
    CURRENT_USER=$(who | awk '{print $1}' | head -1)

    # Configure GNOME power settings
    runuser -l "$CURRENT_USER" -c "gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'"
    runuser -l "$CURRENT_USER" -c "gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type 'nothing'"
    print_success "GNOME power settings configured"
  else
    print_skip "GNOME desktop not detected - skipping GNOME settings"
  fi

  # Check for X11
  if command -v xset &>/dev/null && [ -n "$DISPLAY" ]; then
    print_info "X11 display server detected"
    xset s off     # Disable screen saver
    xset -dpms     # Disable DPMS (Energy Star) features
    xset s noblank # Don't blank the screen
    print_success "X11 power management disabled"
  else
    print_skip "X11 display server not detected - skipping X11 settings"
  fi
}

# Configure systemd settings (works on both desktop and server)
configure_systemd_settings() {
  print_header "SYSTEMD POWER SETTINGS"
  print_info "Configuring system-wide sleep prevention"

  # Sleep configuration
  mkdir -p /etc/systemd/sleep.conf.d/
  cat >/etc/systemd/sleep.conf.d/nosleep.conf <<EOF
[Sleep]
AllowSuspend=no
AllowHibernation=no
AllowSuspendThenHibernate=no
AllowHybridSleep=no
EOF
  print_success "System sleep prevention configured"

  # Login configuration
  mkdir -p /etc/systemd/logind.conf.d/
  cat >/etc/systemd/logind.conf.d/nosuspend.conf <<EOF
[Login]
HandleSuspendKey=ignore
HandleLidSwitch=ignore
HandleLidSwitchExternalPower=ignore
IdleAction=ignore
EOF
  print_success "Additional suspend prevention configured"

  # Reload systemd to apply changes
  systemctl daemon-reload
}

# Configure power button behavior
configure_power_button() {
  print_header "POWER BUTTON CONFIGURATION"
  print_info "Setting power button to trigger shutdown"

  # Create dedicated config file
  mkdir -p /etc/systemd/logind.conf.d/
  cat >/etc/systemd/logind.conf.d/power-button.conf <<EOF
[Login]
PowerButtonAction=poweroff
EOF

  # Update main config if it exists
  if [ -f /etc/systemd/logind.conf ]; then
    # Backup the original file
    cp /etc/systemd/logind.conf /etc/systemd/logind.conf.bak

    if grep -q "^PowerButtonAction=" /etc/systemd/logind.conf; then
      # Replace existing setting
      sed -i 's/^PowerButtonAction=.*/PowerButtonAction=poweroff/' /etc/systemd/logind.conf
    else
      # Add the setting if it doesn't exist
      echo "PowerButtonAction=poweroff" >>/etc/systemd/logind.conf
    fi
  fi

  # Restart logind to apply changes
  systemctl restart systemd-logind
  print_success "Power button will now trigger system shutdown"
}

# Additional server-specific configurations
configure_server_settings() {
  # Detect if this is a server (no desktop environment)
  if ! command -v gnome-session &>/dev/null && ! command -v xset &>/dev/null; then
    print_header "SERVER-SPECIFIC SETTINGS"
    print_info "Ubuntu Server environment detected"

    # Mask systemd sleep targets
    systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target
    print_success "Additional server sleep targets disabled"
  fi
}

#------------------------------------------------------------------------------
# MAIN SCRIPT
#------------------------------------------------------------------------------

# Check for root privileges
if [ "$(id -u)" -ne 0 ]; then
  echo -e "\033[1;31mError: This script must be run as root (sudo).\033[0m"
  exit 1
fi

boxes "UBUNTU POWER MANAGEMENT CONFIGURATOR"

# Run all configuration functions
configure_desktop_settings
configure_systemd_settings
configure_power_button
configure_server_settings

boxes "CONFIGURATION COMPLETE"
# Final success message
echo -e "\033[1;36mYour system has been configured to:"
echo "  ✓ Prevent system sleep/suspend"
echo "  ✓ Configure power button to trigger shutdown"
echo -e "\033[0m"
