#!/usr/bin/env bash
set -euo pipefail

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="${APP_DIR}/docker-compose.yml"
BACKUP_DIR="${APP_DIR}/backups"
IMMICH_COMPOSE_URL="https://github.com/immich-app/immich/releases/latest/download/docker-compose.yml"

# Create backup directory
mkdir -p "${BACKUP_DIR}"

# Backup current compose file if exists
if [[ -f "${COMPOSE_FILE}" ]]; then
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    BACKUP_FILE="${BACKUP_DIR}/docker-compose.yml.${TIMESTAMP}"
    cp "${COMPOSE_FILE}" "${BACKUP_FILE}"
    echo "Backed up to: ${BACKUP_FILE}"
fi

# Download latest
echo "Downloading latest docker-compose.yml..."
curl -L -o "${COMPOSE_FILE}" "${IMMICH_COMPOSE_URL}"
echo "Done. Run ./up.sh to apply changes."
