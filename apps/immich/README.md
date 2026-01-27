# Immich

Self-hosted photo and video management solution. Google Photos alternative with automatic backup, facial recognition, and powerful search.

## Architecture

```
Mobile Apps / Web UI → immich-server:2283 → PostgreSQL + Redis
                              ↓
                    immich-machine-learning
```

**Stack:** 4 containers (immich-server, immich-machine-learning, redis, postgres)

## Prerequisites

- Docker and Docker Compose installed
- Sufficient storage for photos/videos
- SSD recommended for PostgreSQL data (required for good performance)

## Setup Guide

### 1. Create Data Directories

```bash
# Create directories for library and database
sudo mkdir -p /media/storage/immich/library
sudo mkdir -p /media/storage/immich/postgres
sudo chown -R $USER:$USER /media/storage/immich
```

Adjust paths as needed for your setup.

### 2. Configure Environment File

1. Copy the example environment file:

   ```bash
   cd /home/alex/dev/bedroom-server
   cp .env.example .env

   # Ensure apps/immich/.env points at the repo root .env
   ln -sf ../.env apps/immich/.env
   ```

2. Edit `apps/immich/.env` and configure:

   ```dotenv
   # Container path for Immich media (mounted to UPLOAD_LOCATION)
   IMMICH_MEDIA_LOCATION=/data

   # The location where your uploaded files are stored
   UPLOAD_LOCATION=/media/storage/immich/library

   # The location where your database files are stored (use SSD!)
   DB_DATA_LOCATION=/media/storage/immich/postgres

   # Timezone
   TZ=Europe/Helsinki

   # Immich version
   IMMICH_VERSION=release

   # Database setup
   DB_USERNAME=postgres
   DB_DATABASE_NAME=immich
   DB_PASSWORD=your-secure-password
   ```

3. Generate a secure database password:
   ```bash
   openssl rand -base64 32
   ```

### 3. Start Immich

```bash
cd apps/immich
./up.sh
```

**Check status:**

```bash
docker compose ps
docker compose logs -f immich-server
```

Wait for all services to be healthy (may take a few minutes on first start as ML models are downloaded).

### 4. Access Web Interface

Open in browser: http://localhost:2283

1. Create your admin account
2. Start uploading photos or configure mobile app backup

### 5. Connect Mobile Apps

Download the Immich app:

- [iOS App Store](https://apps.apple.com/app/immich/id1613945652)
- [Google Play Store](https://play.google.com/store/apps/details?id=app.alextran.immich)
- [F-Droid](https://f-droid.org/packages/app.alextran.immich/)

In the app:

1. Set Server URL: `http://your-server-ip:2283`
2. Login with your credentials
3. Enable automatic backup in settings

## Ports

| Port | Description           |
| ---- | --------------------- |
| 2283 | Web interface and API |

## Configuration Files

- [`docker-compose.yml`](./docker-compose.yml) - Service definitions (downloaded from Immich releases)
- `.env` - Environment variables (symlinked at `apps/immich/.env`)
- Repository root `.env.example` - Reference for available variables

## Updating Immich

Use the update script to download the latest docker-compose.yml:

```bash
cd apps/immich

# Download latest compose file (backs up current)
./update.sh

# Pull new images and restart
docker compose pull
./up.sh
```

**Check release notes before updating:** https://github.com/immich-app/immich/releases

### Manual Update

If you prefer manual updates:

```bash
cd apps/immich

# Backup current compose file
cp docker-compose.yml docker-compose.yml.backup

# Download latest
curl -L -o docker-compose.yml https://github.com/immich-app/immich/releases/latest/download/docker-compose.yml

# Pull and restart
docker compose pull
./up.sh
```

## Troubleshooting

### Services Not Starting

Check logs for errors:

```bash
docker compose logs immich-server
docker compose logs database
```

Common issues:

- Missing `.env` file - copy from `.env.example`
- Invalid paths in `.env` - ensure directories exist and are writable
- Port 2283 already in use

### Machine Learning Container Slow/Crashing

The ML container downloads models on first start (~1-2GB). Give it time.

If it keeps crashing:

```bash
# Check logs
docker compose logs immich-machine-learning

# Restart just the ML container
docker compose restart immich-machine-learning
```

### Database Connection Issues

```bash
# Check database logs
docker compose logs database

# Verify database is healthy
docker compose ps
```

Ensure `DB_PASSWORD` in `.env` matches across all uses.

### Slow Performance

- Ensure PostgreSQL data is on SSD (not HDD)
- Check available disk space
- Consider enabling hardware acceleration for transcoding (see docker-compose.yml comments)

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
docker compose logs -f              # follow all logs
docker compose logs immich-server   # specific service
```

**Restart:**

```bash
./down.sh && ./up.sh
```

**Update to latest:**

```bash
./update.sh && docker compose pull && ./up.sh
```

**Check service health:**

```bash
docker compose ps
```

## Data Location

Immich data is stored **outside the repository** at the paths specified in `.env`:

```
/media/storage/immich/
├── library/           # Photos and videos
│   ├── upload/        # Original uploads
│   ├── thumbs/        # Generated thumbnails
│   └── encoded-video/ # Transcoded videos
└── postgres/          # PostgreSQL database
```

**Why outside the repo?**

- **Security:** Prevent accidental commits of personal photos
- **Flexibility:** Can use separate disk/partition for media
- **Performance:** Database on SSD, media on larger HDD if needed

## Hardware Acceleration

Immich supports hardware-accelerated transcoding. Edit `docker-compose.yml` to enable:

- **NVIDIA GPU:** Uncomment `hwaccel.transcoding.yml` extends and set service to `nvenc`
- **Intel QuickSync:** Set service to `quicksync`
- **AMD/VAAPI:** Set service to `vaapi`

See: https://immich.app/docs/features/hardware-transcoding

## External Libraries

You can add existing photo folders as external libraries:

1. Mount additional volumes in `docker-compose.yml` under `immich-server`
2. In Immich web UI: Administration → External Libraries → Create Library

See: https://immich.app/docs/features/libraries

## Resources

- [Immich GitHub](https://github.com/immich-app/immich)
- [Immich Documentation](https://immich.app/docs)
- [Environment Variables Reference](https://immich.app/docs/install/environment-variables)
- [Hardware Transcoding Guide](https://immich.app/docs/features/hardware-transcoding)
- [Discord Community](https://discord.immich.app)
