#!/bin/bash
# install-ansible.sh - Install Ansible on Ubuntu Desktop

set -e

echo "Installing Ansible on Ubuntu Desktop..."

# Update package cache
sudo apt update

# Install prerequisites
sudo apt install -y software-properties-common python3-pip python3-venv git

# Add Ansible PPA for newer versions
sudo add-apt-repository --yes --update ppa:ansible/ansible

# Install Ansible via PPA
sudo apt install -y ansible

# Verify installation
ansible --version

# Test connectivity to localhost
echo "Testing Ansible connectivity..."
ansible localhost -m ping

echo "Ansible installation completed successfully!"
echo "Current user: $(whoami)"