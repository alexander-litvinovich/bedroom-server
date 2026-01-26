# n8n Workflow Automation

Self-hosted workflow automation tool for connecting apps and automating tasks.

## Architecture

```
Browser → localhost:5678 → n8n container → SQLite database
```

**Stack:** 1 container (n8n with embedded SQLite)

## Prerequisites

- Docker and Docker Compose installed
- At least 1GB RAM available for n8n

## Setup Guide

### 1. Create Data Directory

Create a directory outside the repo to store n8n data:

```bash
sudo mkdir -p /var/lib/n8n
sudo chown $USER:$USER /var/lib/n8n
```

### 2. Configure Environment Variables

1. Copy the example environment file in the repository root:
   ```bash
   cd /path/to/bedroom-server
   cp .env.example .env
   ```

2. Generate security keys:
   ```bash
   # Encryption key (for workflow credentials)
   openssl rand -hex 32
   
   # JWT secret (for user sessions)
   openssl rand -hex 32
   ```

3. Fill in the n8n section in `.env`:
   ```dotenv
   # Path to n8n data directory
   N8N_DATA_DIR=/var/lib/n8n
   
   # Timezone
   TZ=Europe/Helsinki
   
   # Host and protocol settings
   N8N_HOST=localhost
   N8N_PORT=5678
   N8N_PROTOCOL=http
   N8N_WEBHOOK_URL=http://localhost:5678
   
   # Security keys (paste your generated values)
   N8N_ENCRYPTION_KEY=your-generated-encryption-key
   N8N_JWT_SECRET=your-generated-jwt-secret
   ```

> **Warning:** Do NOT change `N8N_ENCRYPTION_KEY` after initial setup. Changing it will make existing workflow credentials unreadable.

### 3. Start the Stack

```bash
cd apps/n8n
./up.sh
```

**Check status:**
```bash
docker compose ps
docker compose logs -f n8n
```

**Verify n8n is running:**
```bash
curl -s http://localhost:5678/healthz
```

Expected: `{ "status": "ok" }`

### 4. Create First User

1. Open `http://localhost:5678` in browser
2. Create your admin account
3. Start building workflows

## Configuration Files

- [`docker-compose.yml`](./docker-compose.yml) - Service definition
- Repository root `.env` - Environment variables (not in repository, see `.env.example`)

## Updating n8n

1. Check release notes: https://github.com/n8n-io/n8n/releases
2. Backup your data directory before updating
3. Update version in [`docker-compose.yml`](./docker-compose.yml):
   ```yaml
   image: docker.n8n.io/n8nio/n8n:1.73.0  # new version
   ```
4. Apply update:
   ```bash
   cd apps/n8n
   docker compose pull n8n
   ./up.sh
   ```
5. Check logs: `docker compose logs -f n8n`

## Troubleshooting

### Quick Diagnostics

Run the debug script for comprehensive diagnostics:
```bash
./debug.sh
```

### Manual Checks

**View logs:**
```bash
docker compose logs --tail=100 n8n
```

**Check health:**
```bash
curl -s http://localhost:5678/healthz
```

### Common Issues

| Symptom | Possible Cause | Solution |
|---------|---------------|----------|
| Container won't start | Missing encryption key | Generate and set `N8N_ENCRYPTION_KEY` in `.env` |
| Workflows broken after update | Changed encryption key | Restore original `N8N_ENCRYPTION_KEY` from backup |
| Can't access UI | Port conflict | Check if port 5678 is in use: `lsof -i :5678` |
| Database locked | Multiple instances | Ensure only one n8n container is running |
| Webhooks not working | Wrong webhook URL | Verify `N8N_WEBHOOK_URL` matches your access URL |

## Security

### Basic Authentication

For additional protection, enable basic auth:

1. In `.env` set:
   ```dotenv
   N8N_BASIC_AUTH_ACTIVE=true
   N8N_BASIC_AUTH_USER=admin
   N8N_BASIC_AUTH_PASSWORD=your-secure-password
   ```
2. Restart: `./up.sh`

### Production Deployment

For production/internet-facing deployments:

1. Use HTTPS (via reverse proxy like Caddy, nginx, or Cloudflare Tunnel)
2. Update protocol settings:
   ```dotenv
   N8N_PROTOCOL=https
   N8N_WEBHOOK_URL=https://n8n.yourdomain.com
   ```
3. Consider rate limiting and firewall rules

### Credential Security

n8n encrypts workflow credentials using `N8N_ENCRYPTION_KEY`. Keep this key:
- Backed up securely
- Never committed to git
- Never changed after initial setup

## Data Location

n8n data is stored **outside the repository** at the path specified in `N8N_DATA_DIR`:

```
/var/lib/n8n/
├── database.sqlite     # Workflows, credentials, executions
├── .n8n/              # n8n internal files
└── ...
```

**Why outside the repo?**
- **Security:** Prevent accidental commits of credentials
- **Flexibility:** Can use separate disk/partition
- **Backups:** Easier to set up separate backup policies

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
docker compose logs n8n          # specific service
```

**Restart service:**
```bash
./down.sh && ./up.sh
```

**Enter container shell:**
```bash
docker compose exec n8n sh
```

**Export workflows (backup):**
```bash
docker compose exec n8n n8n export:workflow --all --output=/data/workflows-backup.json
```

## Resources

- [n8n Documentation](https://docs.n8n.io/)
- [n8n GitHub](https://github.com/n8n-io/n8n)
- [Environment Variables Reference](https://docs.n8n.io/hosting/configuration/environment-variables/)
- [Workflow Templates](https://n8n.io/workflows/)
- [Community Forum](https://community.n8n.io/)
