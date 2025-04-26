#!/bin/bash

sudo apt update && sudo apt install openssh-server ufw
sudo systemctl enable ssh
sudo ufw allow ssh

# SSH Agent Configuration
# Create systemd service file for the user
cat > /etc/systemd/user/ssh-agent.service << 'EOL'
[Unit]
Description=SSH key agent

[Service]
Type=simple
Environment=SSH_AUTH_SOCK=%t/ssh-agent.socket
ExecStart=/usr/bin/ssh-agent -D -a $SSH_AUTH_SOCK

[Install]
WantedBy=default.target
EOL

# Enable SSH agent for the user
echo "# SSH Agent configuration" >> $HOME/.bashrc
echo "export SSH_AUTH_SOCK=\"\$XDG_RUNTIME_DIR/ssh-agent.socket\"" >> $HOME/.bashrc
echo "# Start ssh-agent if not already running" >> $HOME/.bashrc
echo "if ! pgrep -u \"$USER\" ssh-agent > /dev/null; then" >> $HOME/.bashrc
echo "    systemctl --user start ssh-agent" >> $HOME/.bashrc
echo "fi" >> $HOME/.bashrc

# Add GitHub SSH key to ssh-agent automatically
echo "# Add GitHub SSH key to ssh-agent" >> $HOME/.bashrc
echo "if [ -f \"$HOME/.ssh/gitkey\" ]; then" >> $HOME/.bashrc
echo "    ssh-add -q \"$HOME/.ssh/gitkey\" 2>/dev/null || true" >> $HOME/.bashrc
echo "fi" >> $HOME/.bashrc

# Enable the service to start on boot
systemctl --user enable ssh-agent

echo "SSH agent has been configured to start automatically on boot"
echo "Your GitHub SSH key will be automatically added to ssh-agent on login"
