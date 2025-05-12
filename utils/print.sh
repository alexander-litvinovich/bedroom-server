#!/bin/bash
#
# Print Utility Functions
# Shared colored output functions for scripts
#

# Colors
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
NC='\033[0m' # No Color

# Print functions
print_header() {
  printf "\n${BLUE}==== %s ====${NC}\n" "$1"
}

print_success() {
  printf "${GREEN}✓ %s${NC}\n" "$1"
}

print_info() {
  printf "${CYAN}→ %s${NC}\n" "$1"
}

print_skip() {
  printf "${YELLOW}⤷ %s${NC}\n" "$1"
}

print_error() {
  printf "${YELLOW}× %s${NC}\n" "$1"
}
