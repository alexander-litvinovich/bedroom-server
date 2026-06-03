#!/usr/bin/env bash
set -euo pipefail

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${APP_DIR}/../.." && pwd)"
UNIT_NAME="codex-remote-control.service"
UNIT_TARGET="/etc/systemd/system/${UNIT_NAME}"
SYSCTL_SOURCE="${APP_DIR}/codex-remote-control.sysctl.conf"
SYSCTL_TARGET="/etc/sysctl.d/99-codex-remote-control.conf"
CODEX_USER="${CODEX_REMOTE_CONTROL_USER:-alex}"
CODEX_HOME="${CODEX_REMOTE_CONTROL_HOME:-/home/alex}"
CODEX_SHELL="${CODEX_REMOTE_CONTROL_SHELL:-/usr/bin/zsh}"

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run as root: sudo ${APP_DIR}/install.sh" >&2
  exit 1
fi

if ! id "${CODEX_USER}" >/dev/null 2>&1; then
  echo "User '${CODEX_USER}' does not exist." >&2
  exit 1
fi

for script in "/codex-remote-control.sh" "/run-remote-control.sh"; do
  if [[ ! -x "" ]]; then
    chmod +x ""
  fi
done

if [[ -f "${SYSCTL_SOURCE}" ]]; then
  install -m 0644 "${SYSCTL_SOURCE}" "${SYSCTL_TARGET}"
  sysctl -p "${SYSCTL_TARGET}"
fi

if ! runuser -u "${CODEX_USER}" -- env HOME="${CODEX_HOME}" "${CODEX_SHELL}" -lc 'command -v codex >/dev/null'; then
  echo "codex is not available in ${CODEX_USER}'s login shell." >&2
  exit 1
fi

cat >"${UNIT_TARGET}" <<EOF_UNIT
[Unit]
Description=Codex remote-control daemon
Documentation=https://github.com/openai/codex
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=${CODEX_USER}
Group=${CODEX_USER}
Environment=HOME=${CODEX_HOME}
Environment=CODEX_REMOTE_CONTROL_USER=${CODEX_USER}
Environment=CODEX_REMOTE_CONTROL_HOME=${CODEX_HOME}
Environment=CODEX_REMOTE_CONTROL_SHELL=${CODEX_SHELL}
Environment=TERM=xterm-256color
Environment=NO_COLOR=1
WorkingDirectory=${ROOT_DIR}
ExecStart=${APP_DIR}/codex-remote-control.sh start
Restart=on-failure
RestartSec=5
KillSignal=SIGINT
TimeoutStopSec=30

[Install]
WantedBy=multi-user.target
EOF_UNIT

systemctl daemon-reload
systemctl enable "${UNIT_NAME}"
systemctl restart "${UNIT_NAME}"

echo "Installed and started ${UNIT_NAME}."
echo "Status: sudo systemctl status ${UNIT_NAME}"
echo "Logs:   sudo journalctl -u ${UNIT_NAME} -n 50 --no-pager"
