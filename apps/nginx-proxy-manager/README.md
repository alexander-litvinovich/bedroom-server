# Nginx Proxy Manager

Reverse proxy with a web UI for managing hosts, SSL certificates, and access lists.

**Stack:** 1 container (nginx-proxy-manager)

## Prerequisites

- Docker and Docker Compose installed
- Ports 80, 81, and 443 available on the host

## Setup Guide

### 1. Create Data Directories

Pick a base directory for persistent storage (outside this repo):

```bash
sudo mkdir -p /var/lib/nginx-proxy-manager/{data,letsencrypt}
sudo chown $USER:$USER /var/lib/nginx-proxy-manager
```

### 2. Configure Environment Variables

1. Copy the example environment file in the repository root (if not done already):
   ```bash
   cp .env.example .env
   ```

2. Set the base path in `.env`:
   ```dotenv
   # Base path for data + letsencrypt
   NGINX_PROXY_MANAGER_VOLUMES=/var/lib/nginx-proxy-manager
   ```

### 3. Start Nginx Proxy Manager

```bash
cd apps/nginx-proxy-manager
./up.sh
```

**Check status:**
```bash
docker compose ps
docker compose logs -f app
```

### 4. Access the Web UI

Open in browser: http://localhost:81

## Ports

| Port | Protocol | Description |
|------|----------|-------------|
| 80   | TCP      | Public HTTP |
| 443  | TCP      | Public HTTPS |
| 81   | TCP      | Admin UI |

## Configuration Files

- [`docker-compose.yaml`](./docker-compose.yaml) - Service definition
- Repository root `.env` - Environment variables (see `.env.example`)

## Stopping

```bash
cd apps/nginx-proxy-manager
./down.sh
```
