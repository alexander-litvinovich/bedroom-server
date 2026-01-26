#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ROOT_DIR}/.env"
COMPOSE_FILE="${ROOT_DIR}/vaultwarden/docker-compose.yml"

docker compose --env-file "${ENV_FILE}" -f "${COMPOSE_FILE}" up -d
