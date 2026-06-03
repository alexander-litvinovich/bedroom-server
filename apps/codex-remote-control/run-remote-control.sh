#!/usr/bin/env bash
set -euo pipefail

CODEX_HOME="${CODEX_REMOTE_CONTROL_HOME:-/home/alex}"
LOG_DIR="${CODEX_REMOTE_CONTROL_LOG_DIR:-${CODEX_HOME}/.codex/remote-control}"
LOG_FILE="${LOG_DIR}/remote-control.log"

mkdir -p "${LOG_DIR}"

if [[ -s "${CODEX_HOME}/.nvm/nvm.sh" ]]; then
  export NVM_DIR="${CODEX_HOME}/.nvm"
  # shellcheck disable=SC1091
  . "${NVM_DIR}/nvm.sh"
  nvm use --silent default >/dev/null
fi

codex_path="$(command -v codex)"
command -v script >/dev/null
command -v tail >/dev/null

printf 'Using codex: %s\n' "${codex_path}" >>"${LOG_FILE}"
exec tail -f /dev/null | TERM=xterm-256color NO_COLOR=1 script -q -e -a -f -c "${codex_path} remote-control" "${LOG_FILE}"
