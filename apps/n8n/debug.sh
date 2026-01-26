#!/bin/bash
# Debug utility for testing n8n container health and connectivity

set -e

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${APP_DIR}/../.." && pwd)"
ENV_FILE="${ROOT_DIR}/.env"
COMPOSE_FILE="${APP_DIR}/docker-compose.yml"

compose() {
    docker compose --env-file "${ENV_FILE}" -f "${COMPOSE_FILE}" "$@"
}

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== n8n Debug Utility ===${NC}"
echo ""

# Check if service is running
echo -e "${YELLOW}[1/3] Checking service status...${NC}"
compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Health}}"
echo ""

# Run connectivity tests
echo -e "${YELLOW}[2/3] Running health checks...${NC}"
echo ""

echo -n "  n8n /healthz endpoint: "
if curl -sf http://localhost:5678/healthz > /dev/null 2>&1; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FAILED${NC}"
fi

echo -n "  n8n root page: "
STATUS=$(curl -so /dev/null -w "%{http_code}" http://localhost:5678/ 2>/dev/null)
if [ "$STATUS" = "200" ] || [ "$STATUS" = "302" ]; then
    echo -e "${GREEN}OK (HTTP $STATUS)${NC}"
else
    echo -e "${RED}FAILED (HTTP $STATUS)${NC}"
fi

echo ""

# Show recent logs
echo -e "${YELLOW}[3/3] Recent logs (last 15 lines)...${NC}"
echo ""
echo -e "${YELLOW}--- n8n ---${NC}"
compose logs --no-log-prefix --tail=15 n8n 2>/dev/null || echo "  (not running)"
echo ""
