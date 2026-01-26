# Pi-hole

Network-wide ad blocking via DNS. All devices on your network get ad blocking without any client-side software.

## Architecture

```
Clients → Pi-hole DNS (port 53) → Upstream DNS (Cloudflare/Google/etc.)
                ↓
         Block ads/trackers
```

**Stack:** 1 container (Pi-hole)

## Prerequisites

- Docker and Docker Compose installed
- Port 53 available (no other DNS server running)
- On Linux: may need to disable systemd-resolved (see Troubleshooting)

## Setup Guide

### 1. Create Data Directory

```bash
sudo mkdir -p /var/lib/pihole
sudo chown $USER:$USER /var/lib/pihole
```

### 2. Configure Environment Variables

1. Copy the example environment file in the repository root (if not done already):
   ```bash
   cp .env.example .env
   ```

2. Fill in the Pi-hole section in `.env`:
   ```dotenv
   # Path to Pi-hole data directory (outside the repo!)
   PIHOLE_DATA_DIR=/var/lib/pihole
   
   # Web interface password
   PIHOLE_PASS=your-secure-password
   
   # DNS listening mode: all, local, single, bind
   PIHOLE_DNS_LISTENING_MODE=all
   ```

### 3. Start Pi-hole

```bash
cd apps/pi-hole
./up.sh
```

**Check status:**
```bash
docker compose ps
docker compose logs pihole
```

### 4. Access Web Interface

Open in browser: http://localhost:8080/admin

Login with the password set in `PIHOLE_PASS`.

### 5. Configure Clients to Use Pi-hole

**Option A: Router-level (recommended)**
- Set your router's DHCP DNS server to the Pi-hole host IP
- All devices on the network will automatically use Pi-hole

**Option B: Per-device**
- Manually set DNS server on each device to the Pi-hole host IP

## Ports

| Port | Protocol | Description |
|------|----------|-------------|
| 53   | TCP/UDP  | DNS queries |
| 8080 | TCP      | Web interface (HTTP) |
| 8443 | TCP      | Web interface (HTTPS) |

## Configuration Files

- [`docker-compose.yaml`](./docker-compose.yaml) - Service definition
- Repository root `.env` - Environment variables (not in repository, see `.env.example`)

## Updating Pi-hole

1. Check release notes: https://github.com/pi-hole/docker-pi-hole/releases
2. Update version in [`docker-compose.yaml`](./docker-compose.yaml):
   ```yaml
   image: pihole/pihole:2024.07.0  # new version
   ```
3. Apply update:
   ```bash
   cd apps/pi-hole
   docker compose pull pihole
   ./up.sh
   ```

## Troubleshooting

### Port 53 Already in Use (Linux)

If systemd-resolved is using port 53:

```bash
# Check what's using port 53
sudo lsof -i :53

# Disable systemd-resolved DNS stub listener
sudo sed -i 's/#DNSStubListener=yes/DNSStubListener=no/' /etc/systemd/resolved.conf
sudo systemctl restart systemd-resolved
```

### Container Won't Start

Check logs for errors:
```bash
docker compose logs pihole
```

Common issues:
- Port 53 conflict (see above)
- Missing data directory
- Invalid password characters

### DNS Not Resolving

1. Verify Pi-hole is running: `docker compose ps`
2. Test DNS directly:
   ```bash
   dig @localhost google.com
   ```
3. Check Pi-hole logs: `docker compose logs pihole`

### Web Interface Not Loading

- Ensure port 8080 is not blocked by firewall
- Try accessing via IP instead of localhost
- Check healthcheck status: `docker compose ps`

## Useful Commands

**Start stack:**
```bash
./up.sh
```

**Stop stack:**
```bash
./down.sh
```

**View logs:**
```bash
docker compose logs -f           # follow all logs
docker compose logs pihole       # specific service
```

**Restart:**
```bash
./down.sh && ./up.sh
```

**Pi-hole CLI (inside container):**
```bash
docker exec -it pihole pihole status
docker exec -it pihole pihole -g  # update gravity (blocklists)
```

## Data Location

Pi-hole data is stored **outside the repository** at the path specified in `PIHOLE_DATA_DIR`:

```
/var/lib/pihole/
├── pihole-FTL.db       # Query database
├── gravity.db          # Blocklist database
├── custom.list         # Custom DNS records
└── ...
```

## Resources

- [Pi-hole Docker GitHub](https://github.com/pi-hole/docker-pi-hole)
- [Pi-hole Documentation](https://docs.pi-hole.net/)
- [Pi-hole Discourse](https://discourse.pi-hole.net/)
