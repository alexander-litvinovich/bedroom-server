#!/usr/bin/env bash
set -euo pipefail

UNIT_NAME="codex-remote-control.service"
UNIT_TARGET="/etc/systemd/system/${UNIT_NAME}"
SYSCTL_TARGET="/etc/sysctl.d/99-codex-remote-control.conf"

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run as root: sudo $0" >&2
  exit 1
fi

systemctl stop "${UNIT_NAME}" 2>/dev/null || true
systemctl disable "${UNIT_NAME}" 2>/dev/null || true
rm -f "${UNIT_TARGET}"
rm -f "${SYSCTL_TARGET}"
systemctl daemon-reload

echo "Uninstalled ${UNIT_NAME}."
echo "Removed ${SYSCTL_TARGET}. Reboot or set the sysctl manually if you need to restore the previous runtime value."
