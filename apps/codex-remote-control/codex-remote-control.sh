#!/usr/bin/env bash
set -euo pipefail

SERVICE_NAME="codex-remote-control.service"
APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CODEX_USER="${CODEX_REMOTE_CONTROL_USER:-alex}"
CODEX_HOME="${CODEX_REMOTE_CONTROL_HOME:-/home/alex}"
CODEX_SHELL="${CODEX_REMOTE_CONTROL_SHELL:-/usr/bin/zsh}"
LOG_DIR="${CODEX_REMOTE_CONTROL_LOG_DIR:-${CODEX_HOME}/.codex/remote-control}"
LOG_FILE="${LOG_DIR}/remote-control.log"

run_codex_doctor() {
  HOME="${CODEX_HOME}" "${CODEX_SHELL}" -lc "exec codex doctor"
}

run_codex_remote_control() {
  HOME="${CODEX_HOME}" CODEX_REMOTE_CONTROL_HOME="${CODEX_HOME}" "${CODEX_SHELL}" -lc "exec '${APP_DIR}/run-remote-control.sh'"
}

require_user() {
  local current_user
  current_user="$(id -un)"

  if [[ "${current_user}" != "${CODEX_USER}" ]]; then
    printf 'This command must run as %s, not %s.\n' "${CODEX_USER}" "${current_user}" >&2
    exit 1
  fi
}

show_status() {
  systemctl status "${SERVICE_NAME}" --no-pager || true
  journalctl -u "${SERVICE_NAME}" -n 50 --no-pager || true
  if [[ -f "${LOG_FILE}" ]]; then
    printf '\n--- %s ---\n' "${LOG_FILE}"
    tail -n 50 "${LOG_FILE}" || true
  fi
}

case "${1:-}" in
  start)
    require_user
    run_codex_remote_control
    ;;
  stop)
    require_user
    printf 'codex remote-control has no documented foreground stop command; systemd stops this wrapper process.\n'
    ;;
  doctor)
    require_user
    run_codex_doctor
    ;;
  status)
    show_status
    ;;
  *)
    cat >&2 <<EOF_USAGE
Usage: $0 {start|stop|status|doctor}

Commands:
  start   Start codex remote-control daemon
  stop    Print stop note; systemd terminates the service process
  status  Show systemd status, recent journal logs, and wrapper log tail
  doctor  Run codex doctor with the daemon user environment
EOF_USAGE
    exit 2
    ;;
esac
