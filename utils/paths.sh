#!/bin/bash
#
# PATHS UTILITY
# Provides common path variables and utilities for the bedroom-server repo
#

# Get the absolute path to the repository root directory
get_root_dir() {
  local script_path="$1"
  local dir="$(cd "$(dirname "$script_path")" && pwd)"

  # Navigate up until we find the root directory (where the README.md exists)
  while [[ ! -f "$dir/README.md" && "$dir" != "/" ]]; do
    dir="$(dirname "$dir")"
  done

  # If we found the root directory (README.md exists), return it
  if [[ -f "$dir/README.md" ]]; then
    echo "$dir"
  else
    # Fallback: just return the parent of the utils directory
    echo "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  fi
}

# Define dirs
ROOT_DIR="$(get_root_dir "${BASH_SOURCE[0]}")"
ASSETS_DIR="$ROOT_DIR/assets"
UTILS_DIR="$ROOT_DIR/utils"
INSTALLS_DIR="$ROOT_DIR/install-scripts"

# Export dirs
export ROOT_DIR
export ASSETS_DIR
export UTILS_DIR
export INSTALLS_DIR
