# Kavita (Docker)

Self-hosted ebook/comic/manga reader.

## Prerequisites

- Docker + Docker Compose installed

## Setup

1. Create directories for your library and Kavita config data (outside the repo):

   ```bash
   sudo mkdir -p /var/lib/kavita/config /srv/media/books
   sudo chown -R $USER:$USER /var/lib/kavita /srv/media/books
   ```

2. Set environment variables in the repository root `.env`:

   ```dotenv
   # Kavita paths (host)
   KAVITA_BOOKS=/srv/media/books
   KAVITA_CONFIG=/var/lib/kavita/config

   # Optional
   TZ=America/New_York
   ```

3. Start Kavita:

   ```bash
   cd apps/kavita
   ./up.sh
   ```

4. Open the UI:

   - http://localhost:5000

## Stop

```bash
cd apps/kavita
./down.sh
```

## Notes

- The Docker image is `jvmilazz0/kavita:latest` and the container listens on port `5000`.
- Kavita expects your library mounted at `/books` and its config at `/kavita/config`.
