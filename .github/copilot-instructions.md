# GitHub Copilot Instructions

## Project Overview

This repository contains bash scripts for server management and automation that run on Ubuntu.

## Development Guidelines

### Tech Stack

- **Primary Language**: Bash scripts
- **Target OS**: Ubuntu
- **Environment**: Server-side deployment

### Path Management

- All scripts should source the paths utility file:
  ```bash
  source "$(dirname "${BASH_SOURCE[0]}")/utils/paths.sh"
  ```
- Always use path variables defined in `utils/paths.sh` instead of hardcoded paths
- For relative paths, ensure they're relative to the script location, not the working directory
  - `ROOT_DIR`: Root directory of the `bedroom-server` repo
  - `ASSETS_DIR`: Directory for assets that can be used by another scripts
  - `UTILS_DIR`: Directory for utility functions
  - `INSTALLS_DIR`: Directory for scripts to install some applications

### Console Output

- Always use the Print Utility Functions from `utils/print.sh` for any console output
- Print functions include:
  - `print_info`: For general information messages
  - `print_success`: For success messages
  - `print_warning`: For warning messages
  - `print_error`: For error messages
- Source the print utility file:
  ```bash
  source "$UTILS_DIR/print.sh"
  ```

### Best Practices

- Include proper error handling in all scripts
- Add comments explaining complex operations
- Make scripts idempotent when possible (can be run multiple times without changing the result)
- Follow shell script best practices for Ubuntu environments
- In the beginning of each scrip include a header with the script title and a short script description

## Example Script Structure

```bash
#!/bin/bash

# Source utility scripts
source "$(dirname "${BASH_SOURCE[0]}")/utils/paths.sh"
source "$UTILS_DIR/print.sh"

# Script logic
print_info "Starting operation..."

# Use path variables
if [ -d "${SERVER_CONFIG_PATH}" ]; then
    print_success "Found configuration directory"
else
    print_error "Configuration directory not found"
    exit 1
fi

# Rest of the script...
```
