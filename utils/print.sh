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
  echo -e "\n${BLUE}==== $1 ====${NC}"
}

print_success() {
  echo -e "${GREEN}✓ $1${NC}"
}

print_info() {
  echo -e "${CYAN}→ $1${NC}"
}

print_skip() {
  echo -e "${YELLOW}⤷ $1${NC}"
}
