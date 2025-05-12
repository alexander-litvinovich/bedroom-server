#!/bin/bash
#
# Command Utility Functions
# ------------------------
# This script provides utility functions for checking if commands are installed
# and installing them if needed. It's designed to be sourced by other scripts
# in the bedroom-server project to ensure required dependencies are available.
#
# Functions:
#   check(command_name) - Checks if a command exists in the system PATH
#     Parameters:
#       command_name - The name of the command to check
#     Returns:
#       0 - Command exists
#       1 - Command not found
#
#   install(command_name, [install_command]) - Installs a command if not present
#     Parameters:
#       command_name - The name of the command to install
#       install_command - (Optional) Custom installation command
#     Returns:
#       0 - Command was newly installed
#       1 - Command was already installed
#
# Usage Examples:
#   Source this file in your script:
#     source "$(dirname "$0")/utils/command.sh"
#
#   Check if a command exists:
#     if check "docker"; then
#       echo "Docker is installed"
#     else
#       echo "Docker is not installed"
#     fi
#
#   Install a command with default apt-get:
#     install "curl"
#
#   Install a command with custom installation:
#     install "node" "curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash - && apt-get install -y nodejs"
#
#   Use with conditional execution:
#     check "git" || install "git"
#

check() {
  local command_name="$1"
  if ! command -v "$command_name" &>/dev/null; then
    return 1 # Command not found
  else
    return 0 # Command exists
  fi
}

install() {
  local command_name="$1"
  local install_command="$2"

  if ! check "$command_name"; then
    echo "$command_name is not installed. Installing..."
    if [ -n "$install_command" ]; then
      eval "$install_command"
    else
      apt-get install -y "$command_name"
    fi
    echo "$command_name installed successfully."
    return 0 # Newly installed
  else
    echo "$command_name is already installed."
    return 1 # Already installed
  fi
}
