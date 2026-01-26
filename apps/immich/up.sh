#!/usr/bin/env bash
set -euo pipefail

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${APP_DIR}/../.." && pwd)"
LOCAL_ENV="${APP_DIR}/.env"

# Check if local .env exists
if [[ ! -f "${LOCAL_ENV}" ]]; then
    echo "Error: ${LOCAL_ENV} not found"
    echo "Copy and configure: cp ${ROOT_DIR}/assets/immich.example.env ${LOCAL_ENV}"
    exit 1
fi

docker compose -f "${APP_DIR}/docker-compose.yml" up -d
