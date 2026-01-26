#!/bin/bash
# Debug utility for testing Vaultwarden container connectivity

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== Vaultwarden Debug Utility ===${NC}"
echo ""

# Check if main services are running
echo -e "${YELLOW}[1/4] Checking service status...${NC}"
docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Health}}"
echo ""

# Start tester container if not running
echo -e "${YELLOW}[2/4] Starting tester container...${NC}"
docker compose --profile debug up -d tester
echo ""

# Run connectivity tests
echo -e "${YELLOW}[3/4] Running connectivity tests...${NC}"
echo ""

echo -n "  Vaultwarden /alive endpoint: "
if docker compose exec -T tester curl -sf http://vaultwarden/alive > /dev/null 2>&1; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FAILED${NC}"
fi

echo -n "  Vaultwarden root page: "
STATUS=$(docker compose exec -T tester curl -so /dev/null -w "%{http_code}" http://vaultwarden/ 2>/dev/null)
if [ "$STATUS" = "200" ]; then
    echo -e "${GREEN}OK (HTTP $STATUS)${NC}"
else
    echo -e "${RED}FAILED (HTTP $STATUS)${NC}"
fi

echo -n "  Vaultwarden WebSocket endpoint: "
STATUS=$(docker compose exec -T tester curl -so /dev/null -w "%{http_code}" http://vaultwarden/notifications/hub 2>/dev/null)
if [ "$STATUS" = "400" ] || [ "$STATUS" = "426" ]; then
    echo -e "${GREEN}OK (HTTP $STATUS - expected, needs WS upgrade)${NC}"
elif [ "$STATUS" = "404" ]; then
    echo -e "${RED}FAILED (HTTP 404 - WebSocket not configured)${NC}"
else
    echo -e "${YELLOW}UNKNOWN (HTTP $STATUS)${NC}"
fi

echo ""

# Show recent logs
echo -e "${YELLOW}[4/4] Recent logs (last 10 lines each)...${NC}"
echo ""
echo -e "${YELLOW}--- vaultwarden ---${NC}"
docker compose logs --no-log-prefix --tail=10 vaultwarden 2>/dev/null || echo "  (not running)"
echo ""
echo -e "${YELLOW}--- cloudflared ---${NC}"
docker compose logs --no-log-prefix --tail=10 cloudflared 2>/dev/null || echo "  (not running)"
echo ""

# Optional: stop tester
read -p "Stop tester container? [y/N] " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    docker compose --profile debug stop tester
    echo -e "${GREEN}Tester stopped.${NC}"
fi
