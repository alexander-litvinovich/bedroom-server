#!/bin/zsh

#
# XRDP INSTALLATION SCRIPT
# Installs and configures XRDP with dummy video driver for headless GUI access
#

# Source utility scripts
source "$UTILS_DIR/print.sh"
source "$UTILS_DIR/command.sh"

print_header "XRDP Installation"

# Validate required environment variables
if [ -z "$XRDP_USER" ]; then
    print_error "XRDP_USER environment variable is not set"
    exit 1
fi

xrdp_home_dir=$(eval echo "~$XRDP_USER")

# Update package list and install required packages
print_info "Updating package list and installing XRDP packages..."
if ! sudo apt update; then
    print_error "Failed to update package list"
    exit 1
fi

print_info "Installing XRDP and required packages..."
if ! sudo apt install -y xrdp xserver-xorg-video-dummy pulseaudio samba; then
    print_error "Failed to install required packages"
    exit 1
fi
print_success "Successfully installed packages"

# Create XRDP user if it doesn't exist
if id "$XRDP_USER" &>/dev/null; then
    print_info "User $XRDP_USER already exists, skipping user creation"
else
    print_info "Creating user $XRDP_USER..."
    if ! sudo adduser "$XRDP_USER"; then
        print_error "Failed to create user $XRDP_USER"
        exit 1
    fi
    print_success "User $XRDP_USER created successfully"
fi

print_info "Adding $XRDP_USER to system groups..."
if ! sudo usermod -aG sudo,adm,cdrom,dip,plugdev,lpadmin,sambashare,audio,video,netdev "$XRDP_USER"; then
    print_error "Failed to add user to groups"
    exit 1
fi

print_info "Configuring XRDP, Polkit, and Video dummy driver..."

# Create required directories
directories=(
    "/etc/X11/xorg.conf.d"
    "/etc/polkit-1/rules.d"
    "/etc/polkit-1/localauthority.conf.d"
    "/etc/polkit-1/localauthority/50-local.d"
    "/etc/xrdp/pam.d/"
)

for dir in "${directories[@]}"; do
    if ! sudo mkdir -p "$dir"; then
        print_error "Failed to create directory: $dir"
        exit 1
    fi
done

# Copy asset files
xrdp_assets=(
    "$ASSETS_DIR/xrdp_02-allow-colord.conf:/etc/polkit-1/localauthority.conf.d/02-allow-colord.conf"
    "$ASSETS_DIR/xrdp_10-networkmanager.pkla:/etc/polkit-1/localauthority/50-local.d/10-networkmanager.pkla"
    "$ASSETS_DIR/xrdp_10-headless.conf:/etc/X11/xorg.conf.d/10-headless.conf"
    "$ASSETS_DIR/xrdp_49-nopasswd-localrdp.rules:/etc/polkit-1/rules.d/49-nopasswd-localrdp.rules"
    "$ASSETS_DIR/xrdp_01-terminate-old-sessions:/etc/xrdp/pam.d/01-terminate-old-sessions"
    "$ASSETS_DIR/xrdp_xrdp-terminate-old-session.sh:/usr/local/bin/xrdp-terminate-old-session.sh"
)

for asset in "${xrdp_assets[@]}"; do
    source_file="${asset%:*}"
    dest_file="${asset#*:}"

    if [ ! -f "$source_file" ]; then
        print_error "Source asset file not found: $source_file"
        exit 1
    fi

    if ! sudo cp "$source_file" "$dest_file"; then
        print_error "Failed to copy $source_file to $dest_file"
        exit 1
    fi
    print_success "Copied $(basename "$source_file")"
done

# Setup .xsession file for the user
print_info "Setting up .xsession file for $XRDP_USER..."
if [ ! -f "$ASSETS_DIR/xrdp_xsession" ]; then
    print_error "xsession template file not found: $ASSETS_DIR/xrdp_xsession"
    exit 1
fi

if ! sudo cp "$ASSETS_DIR/xrdp_xsession" "$xrdp_home_dir/.xsession"; then
    print_error "Failed to copy .xsession file"
    exit 1
fi

if ! sudo chown "$XRDP_USER:$XRDP_USER" "$xrdp_home_dir/.xsession"; then
    print_error "Failed to change ownership of .xsession file"
    exit 1
fi

# Add auto termination script
ses_file="/etc/pam.d/xrdp-sesman"
hook_line="auth       optional    pam_exec.so quiet /usr/local/bin/xrdp-terminate-old-session.sh"

if ! grep -Fxq "$hook_line" "$ses_file"; then
    sudo sed -i "/@include common-auth/i $hook_line" "$ses_file"
else
    echo "The old session termination script already added"
fi

print_info "Enabling and restarting services..."

# Enable XRDP service
if ! sudo systemctl enable xrdp; then
    print_error "Failed to enable XRDP service"
    exit 1
fi

# Restart services
services=("polkit" "xrdp")
for service in "${services[@]}"; do
    print_info "Restarting $service service..."
    if ! sudo systemctl restart "$service"; then
        print_error "Failed to restart $service service"
        exit 1
    fi

    # Verify service is running
    if ! sudo systemctl is-active --quiet "$service"; then
        print_error "$service service is not running after restart"
        exit 1
    fi
    print_success "$service service restarted and is running"
done

sudo ufw allow 3389/tcp comment "Allow XRDP"

# Get server IP address
server_ip=$(hostname -I | awk '{print $1}')
if [ -z "$server_ip" ]; then
    server_ip="<server-ip>"
    print_warning "Could not determine server IP address"
fi

print_success "XRDP installation completed successfully!"
print_info "Connect to XRDP at: $server_ip using \"$XRDP_USER\" username"
print_info "Make sure to set a password for $XRDP_USER if you haven't already: sudo passwd $XRDP_USER"
