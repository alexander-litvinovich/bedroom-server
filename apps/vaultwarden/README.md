# Vaultwarden with Cloudflare Tunnel

Self-hosted password manager accessible from the internet via Cloudflare Tunnel. No public IPv4 or port forwarding required.

## Architecture

```
Internet → Cloudflare Edge → cloudflared tunnel → vaultwarden:80
```

**Stack:** 2 containers (Vaultwarden + cloudflared)

## Prerequisites

- Docker and Docker Compose installed
- Own domain name
- Free Cloudflare account: https://dash.cloudflare.com/sign-up

## Setup Guide

### 1. Add Domain to Cloudflare

1. In Cloudflare dashboard: **Add a site** → enter your domain
2. Select **Free** plan
3. Cloudflare will provide two nameservers (e.g., `anna.ns.cloudflare.com`, `bob.ns.cloudflare.com`)
4. Update NS records at your domain registrar with the provided nameservers
5. Wait 5-30 minutes for DNS propagation

**Verify:**
```bash
dig NS yourdomain.com
```

> **Important:** After NS change, set SSL/TLS mode to **Full** (SSL/TLS → Overview) to avoid issues with existing sites on the domain.

### 2. Create Cloudflare Tunnel

1. Go to **Cloudflare Zero Trust**: https://one.dash.cloudflare.com/
2. Navigate to **Networks** → **Tunnels**
3. Click **Create a tunnel**
4. Select **Cloudflared** type
5. Name the tunnel (e.g., `vaultwarden`)
6. On "Install and run a connector" step, select **Docker**
7. **Copy the token** (long string starting with `eyJhIjoi...`) - you'll need it for `.env`

### 3. Configure Public Hostname

In the tunnel creation wizard (or later in tunnel settings):

1. **Public Hostnames** → **Add a public hostname**
2. Fill in:
   - **Subdomain**: `vault` (or `bw`, `passwords`, etc.)
   - **Domain**: select your domain from the list
   - **Service Type**: `HTTP`
   - **URL**: `vaultwarden:80`
3. Save

The public URL will be: `https://vault.yourdomain.com`

> **Note:** Cloudflare automatically creates a CNAME record for the hostname. Specific CNAME records take priority over wildcard A records.

### 4. Configure Environment Variables

1. Create data directory (outside the repo):
   ```bash
   sudo mkdir -p /var/lib/vaultwarden
   sudo chown $USER:$USER /var/lib/vaultwarden
   ```

2. Copy the example environment file in the repository root:
   ```bash
   cd /Users/alex/dev/bedroom-server
   cp .env.example .env
   ```

3. Fill in the Vaultwarden section in `.env`:
   ```dotenv
   # Path to Vaultwarden data directory (outside the repo!)
   VW_DATA_DIR=/var/lib/vaultwarden
   
   # Public URL (your domain via Cloudflare Tunnel)
   VW_PUBLIC_URL=https://vault.yourdomain.com
   
   # Allow new user registrations (set to false after creating first user)
   VW_SIGNUPS_ALLOWED=true
   
   # Admin panel token (generate with: openssl rand -base64 48)
   VW_ADMIN_TOKEN=
   
   # Cloudflare Tunnel token
   VW_CF_TUNNEL_TOKEN=eyJhIjoiY2U...
   ```

4. Generate admin token:
   ```bash
   openssl rand -base64 48
   ```

### 5. Start the Stack

```bash
cd apps/vaultwarden
./up.sh
```

**Check status:**
```bash
./debug.sh
```

The debug script will:
- Show service status and health
- Test internal connectivity
- Verify WebSocket endpoint
- Display recent logs

**Verify external access:**
```bash
curl -i https://vault.yourdomain.com/alive
```

Expected: `200 OK`

### 6. Create First User and Disable Registrations

1. Open `https://vault.yourdomain.com` in browser
2. Create your account
3. After registration, disable public signups:
   - In `.env` set `VW_SIGNUPS_ALLOWED=false`
   - Restart: `./up.sh`

### 7. Connect Bitwarden Clients

In Bitwarden client (desktop/mobile/browser extension):
1. Select **Self-hosted**
2. Set Server URL: `https://vault.yourdomain.com`
3. Login with your credentials

## Configuration Files

- [`docker-compose.yml`](./docker-compose.yml) - Service definitions (vaultwarden + cloudflared)
- Repository root `.env` - Environment variables (not in repository, see `.env.example`)

## Updating Vaultwarden

1. Check release notes: https://github.com/dani-garcia/vaultwarden/releases
2. Create backup before updating (see TODO section)
3. Update version in [`docker-compose.yml`](./docker-compose.yml):
   ```yaml
   image: vaultwarden/server:1.33.0  # new version
   ```
4. Apply update:
   ```bash
   cd apps/vaultwarden
   docker compose pull vaultwarden
   ./up.sh
   ```
5. Check status: `./debug.sh`

## Troubleshooting

### Quick Diagnostics

Run the debug script for comprehensive diagnostics:
```bash
./debug.sh
```

The script will automatically:
- Check service status and health
- Start a test container and verify internal connectivity
- Test Vaultwarden's `/alive` and WebSocket endpoints
- Display recent logs from both services
- Optionally clean up the test container

### Manual Checks

**View logs:**
```bash
docker compose logs --tail=100 vaultwarden
docker compose logs --tail=100 cloudflared
```

**Check tunnel status:**
- Cloudflare Zero Trust dashboard → Tunnels → select your tunnel → status should be **Healthy**

### Common Issues

| Symptom | Possible Cause | Solution |
|---------|---------------|----------|
| 502 Bad Gateway | Vaultwarden not ready | Check healthcheck, wait for startup |
| Tunnel disconnected | Invalid token | Verify `VW_CF_TUNNEL_TOKEN` in `.env` |
| WebSocket not working | Old Vaultwarden version | Ensure version ≥1.29 |
| DNS not resolving | NS records not updated | Wait longer, check `dig NS domain` |
| Admin panel not accessible | No ADMIN_TOKEN set | Generate token and add to `.env` |

**Test WebSocket endpoint:**
```bash
curl -i https://vault.yourdomain.com/notifications/hub
```
Expected: `400` or `426` (WebSocket upgrade required), but **not** `404`

## Security

### Admin Panel

**Option 1: Disable after setup**
- Remove or comment out `VW_ADMIN_TOKEN` in `.env`
- Restart: `./up.sh`

**Option 2: Protect with Cloudflare Access**
- Zero Trust → Access → Applications
- Create application for `vault.yourdomain.com/admin`
- Set policy (e.g., allow only specific emails)

### Emergency Access

1. **Regular vault exports:**
   - Web vault → Tools → Export vault
   - Format: **Encrypted JSON** (password protected)
   - Store offline (USB drive, encrypted cloud)

2. **Create emergency sheet:**
   - Email password
   - Master password hint
   - 2FA recovery codes
   - Store separately from backups

## Data Location

Vaultwarden data is stored **outside the repository** at the path specified in `VW_DATA_DIR`:

```
/var/lib/vaultwarden/
├── db.sqlite3          # Password database
├── rsa_key.pem         # Encryption keys
├── attachments/        # File attachments
└── ...
```

**Why outside the repo?**
- **Security:** Prevent accidental commits of password database
- **Flexibility:** Can use separate disk/partition
- **Backups:** Easier to set up separate backup policies

## TODO

- [ ] **Implement automated backups**
  - Create `backup.sh` script to archive `${VW_DATA_DIR}`
  - Add cron job for daily backups
  - Set up backup retention policy (e.g., 30 days)
  - Configure rclone for cloud backup storage
  - Test restore procedure

- [ ] Set up monitoring/alerts for service health
- [ ] Configure SMTP for password reset emails
- [ ] Document backup restoration procedure
- [ ] Add fail2ban for brute-force protection

## Useful Commands

**Start stack:**
```bash
./up.sh
```

**Stop stack:**
```bash
./down.sh
```

**Run diagnostics:**
```bash
./debug.sh
```

**View logs:**
```bash
docker compose logs -f           # follow all logs
docker compose logs vaultwarden  # specific service
```

**Restart services:**
```bash
./down.sh && ./up.sh
```

## Resources

- [Vaultwarden GitHub](https://github.com/dani-garcia/vaultwarden)
- [Vaultwarden Wiki](https://github.com/dani-garcia/vaultwarden/wiki)
- [Cloudflare Tunnel Documentation](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/)
- [Full Setup Guide](../../docs/bitwarden-serv.md) (detailed, in Russian)
