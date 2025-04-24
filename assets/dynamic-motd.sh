#!/bin/bash
# dynamic-motd.sh - Script that generates dynamic MOTD content
# For Ubuntu 24.04 on HP Prodesk 405 G4 Mini bedroom server

cat <<'BANNER'
===================================================================

  ██████╗ ███████╗██████╗ ██████╗  ██████╗  ██████╗ ███╗   ███╗
  ██╔══██╗██╔════╝██╔══██╗██╔══██╗██╔═══██╗██╔═══██╗████╗ ████║
  ██████╔╝█████╗  ██║  ██║██████╔╝██║   ██║██║   ██║██╔████╔██║
  ██╔══██╗██╔══╝  ██║  ██║██╔══██╗██║   ██║██║   ██║██║╚██╔╝██║
  ██████╔╝███████╗██████╔╝██║  ██║╚██████╔╝╚██████╔╝██║ ╚═╝ ██║
  ╚═════╝ ╚══════╝╚═════╝ ╚═╝  ╚═╝ ╚═════╝  ╚═════╝ ╚═╝     ╚═╝

  ███████╗███████╗██████╗ ██╗   ██╗███████╗██████╗             
  ██╔════╝██╔════╝██╔══██╗██║   ██║██╔════╝██╔══██╗            
  ███████╗█████╗  ██████╔╝██║   ██║█████╗  ██████╔╝            
  ╚════██║██╔══╝  ██╔══██╗╚██╗ ██╔╝██╔══╝  ██╔══██╗            
  ███████║███████╗██║  ██║ ╚████╔╝ ███████╗██║  ██║            
  ╚══════╝╚══════╝╚═╝  ╚═╝  ╚═══╝  ╚══════╝╚═╝  ╚═╝            

===================================================================

BANNER

# Display dynamic system information
echo "Server IP: $(hostname -I | awk '{print $1}')"
echo "Hostname: $(hostname)"
echo "System load: $(cat /proc/loadavg | awk '{print $1, $2, $3}')"
echo "Memory usage: $(free -m | awk '/Mem/{printf("%.2f%%", $3/$2*100)}')"
echo "Disk usage: $(df -h / | awk '/\// {print $5}')"
echo "Last login: $(last -n 1 | head -n 1 | awk '{print $4, $5, $6, $7}')"
echo "Uptime: $(uptime -p)"

# Check for system updates (if apt is available)
if command -v apt &>/dev/null; then
  echo ""
  # Create a temporary file for output
  tmp_file=$(mktemp)
  # Try to refresh package lists but don't show output and don't fail if it doesn't work
  apt-get update -qq >/dev/null 2>&1 || true

  # Count available updates
  updates=$(apt-get --just-print upgrade 2>/dev/null | grep -c "^Inst")
  security_updates=$(apt-get --just-print upgrade 2>/dev/null | grep -c "^Inst.*security")

  echo -n "Updates: "
  if [ "$updates" -eq 0 ]; then
    echo "System is up to date!"
  else
    echo -e "\033[33m$updates packages can be updated ($security_updates security updates)\033[0m"
    echo "Run 'sudo apt update && sudo apt upgrade' to update the system"
  fi
fi

echo ""
echo "==================================================================="
