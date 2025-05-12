#!/bin/zsh

# ======================================================
# Gnome Remote Desktop Installation
# ======================================================
# This script installs and configures Gnome Remote Desktop
# to work without a physical monitor, opens required firewall
# ports, and sets up automatic startup.
# ======================================================

# Source utility scripts
source "$UTILS_DIR/print.sh"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  print_error "This script must be run as root"
  exit 1
fi

# Get the current non-root user who executed the script
if [ -n "$SUDO_USER" ]; then
  CURRENT_USER="$SUDO_USER"
else
  print_error "Unable to determine the current user"
  exit 1
fi

print_info "Installing Gnome Remote Desktop packages..."
sudo apt-get update || {
  print_error "Failed to update package lists"
  exit 1
}
sudo apt-get install -y gnome-remote-desktop || {
  print_error "Failed to install gnome-remote-desktop"
  exit 1
}
sudo apt-get install -y xrdp || {
  print_error "Failed to install xrdp"
  exit 1
}

# Stop the service if it's running
systemctl stop gnome-remote-desktop.service

# Configure virtual monitor if no monitor is connected
print_info "Configuring virtual monitor..."
# Create a dummy monitor config file for Xorg
cat >/usr/share/X11/xorg.conf.d/10-dummy-monitor.conf <<EOF
Section "Device"
    Identifier "DummyDevice"
    Driver "dummy"
    VideoRam 256000
EndSection

Section "Monitor"
    Identifier "DummyMonitor"
    HorizSync 30-70
    VertRefresh 50-75
EndSection

Section "Screen"
    Identifier "DummyScreen"
    Device "DummyDevice"
    Monitor "DummyMonitor"
    DefaultDepth 24
    SubSection "Display"
        Depth 24
        Modes "1920x1080"
    EndSubSection
EndSection
EOF

# Configure UFW firewall
print_info "Configuring firewall..."
sudo ufw allow 3389/tcp comment "RDP" || { print_warning "Failed to configure firewall for RDP"; }
sudo ufw reload || { print_warning "Failed to reload firewall"; }

# Set up GNOME Remote Desktop for the current user
print_info "Setting up Remote Desktop for user: $CURRENT_USER"

# Create a temporary script to run commands as the current user
TMP_SCRIPT=$(mktemp)
cat >"$TMP_SCRIPT" <<EOF
#!/bin/bash
export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/\$(id -u)/bus
export XDG_RUNTIME_DIR=/run/user/\$(id -u)
export DISPLAY=:1

# Enable RDP
grdctl rdp enable

# Set RDP credentials
grdctl rdp set-credentials ${CURRENT_USER} 12345678

# Enable control
gsettings set org.gnome.desktop.remote-desktop.rdp screen-share-mode 'control'
EOF

chmod +x "$TMP_SCRIPT"
sudo -u "$CURRENT_USER" "$TMP_SCRIPT"
rm "$TMP_SCRIPT"

# Create systemd service to start Gnome Remote Desktop on boot
print_info "Setting up autostart service..."
cat >/etc/systemd/system/gnome-remote-desktop-starter.service <<EOF
[Unit]
Description=Gnome Remote Desktop Starter
After=network.target

[Service]
Type=simple
User=$CURRENT_USER
Environment="DISPLAY=:1"
Environment="DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u $CURRENT_USER)/bus"
Environment="XDG_RUNTIME_DIR=/run/user/$(id -u $CURRENT_USER)"
ExecStartPre=/bin/sleep 10
ExecStart=/usr/libexec/gnome-remote-desktop-daemon

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd configurations
sudo systemctl daemon-reload

# Enable and start the services
sudo systemctl enable gnome-remote-desktop-starter.service
sudo systemctl start gnome-remote-desktop-starter.service
sudo systemctl enable xrdp
sudo systemctl start xrdp

print_success "Gnome Remote Desktop installation and configuration completed"
print_info "You can connect to this system using any RDP client"
print_info "Username: $CURRENT_USER"
print_info "Password: 12345678"
print_warning "Please change the default password for security reasons"
print_info "Default RDP port: 3389"

exit 0
