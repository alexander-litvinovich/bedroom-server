# Vaultwarden Backup Feature — Implementation Plan

## Overview

This document outlines the plan for implementing automated backup and recovery system for Vaultwarden password manager. The goal is to protect against data loss through regular, automated backups with multiple storage tiers.

---

## Goals and Requirements

### Primary Goals

1. **Data Protection**: Automatic daily backups of all Vaultwarden data
2. **Disaster Recovery**: Ability to restore from backup within 1 hour
3. **Retention Policy**: Keep backups for 30 days locally, 90 days in cloud
4. **Security**: Encrypted backups with secure storage
5. **Monitoring**: Alert on backup failures

### What Needs to Be Backed Up

- `db.sqlite3` - Main password database
- `rsa_key.pem` / `rsa_key.der` - Encryption keys
- `attachments/` - File attachments from vault items
- `sends/` - Temporary send files (if used)
- `config.json` - Server configuration (if exists)

### Non-Goals (Out of Scope)

- Real-time replication
- Point-in-time recovery (PITR)
- Backup of `.env` file (contains secrets, should be backed up separately/manually)

---

## Architecture

### Backup Strategy

```
┌─────────────────┐
│  Vaultwarden    │
│   Data Dir      │
│ /var/lib/vw     │
└────────┬────────┘
         │
         │ Daily backup (3 AM)
         ▼
┌─────────────────┐
│ Local Backups   │
│ /var/backups/   │
│ Retention: 30d  │
└────────┬────────┘
         │
         │ After local backup
         ▼
┌─────────────────┐
│ Cloud Storage   │
│ (rclone remote) │
│ Retention: 90d  │
└─────────────────┘
```

### Backup Tiers

1. **Tier 1: Local Backups**
   - Location: `/var/backups/vaultwarden/`
   - Retention: 30 days
   - Purpose: Quick recovery, first line of defense

2. **Tier 2: Cloud Storage**
   - Location: Configured rclone remote (S3, Backblaze B2, etc.)
   - Retention: 90 days
   - Purpose: Off-site disaster recovery

---

## Task 01 — Prepare Backup Infrastructure ✅

### Prerequisites

- Vaultwarden is running and data directory is accessible
- At least 2x data directory size free on backup disk
- (Optional) Cloud storage account and rclone configured

### Steps

1. Create local backup directory:

```bash
sudo mkdir -p /var/backups/vaultwarden
sudo chown $USER:$USER /var/backups/vaultwarden
```

2. Verify available disk space:

```bash
df -h /var/backups
du -sh ${VW_DATA_DIR}
```

Ensure backup location has at least 2x the data directory size.

3. (Optional) Install and configure rclone for cloud backups:

```bash
# Install rclone
curl https://rclone.org/install.sh | sudo bash

# Configure remote
rclone config
```

Follow the wizard to set up your cloud storage provider (S3, Backblaze B2, Google Drive, etc.).

### Manual Test

- Verify directories exist: `test -w /var/backups/vaultwarden && echo OK`
- Test rclone: `rclone lsd remote:` (should list root directories)

---

## Task 02 — Create Backup Script

### Steps

1. Create `apps/vaultwarden/backup.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Vaultwarden Backup Script
# =============================================================================
# Creates compressed backup of Vaultwarden data directory with:
# - Timestamped archives
# - Local retention policy (30 days)
# - Optional cloud sync via rclone
# - Error handling and logging
# =============================================================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Load environment variables from root .env
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "${SCRIPT_DIR}")"
ENV_FILE="${ROOT_DIR}/.env"

if [ ! -f "${ENV_FILE}" ]; then
    echo -e "${RED}Error: .env file not found at ${ENV_FILE}${NC}"
    exit 1
fi

set -a
source "${ENV_FILE}"
set +a

# Configuration
BACKUP_DIR="${VW_BACKUP_DIR:-/var/backups/vaultwarden}"
RETENTION_DAYS="${VW_BACKUP_RETENTION_DAYS:-30}"
CLOUD_ENABLED="${VW_BACKUP_CLOUD_ENABLED:-false}"
CLOUD_REMOTE="${VW_BACKUP_CLOUD_REMOTE:-}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="vaultwarden_${TIMESTAMP}.tar.gz"
BACKUP_PATH="${BACKUP_DIR}/${BACKUP_NAME}"

# Logging
log_info() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

log_error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1" >&2
}

log_warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1"
}

# Validation
if [ -z "${VW_DATA_DIR}" ]; then
    log_error "VW_DATA_DIR not set in .env"
    exit 1
fi

if [ ! -d "${VW_DATA_DIR}" ]; then
    log_error "Data directory does not exist: ${VW_DATA_DIR}"
    exit 1
fi

if [ ! -d "${BACKUP_DIR}" ]; then
    log_error "Backup directory does not exist: ${BACKUP_DIR}"
    exit 1
fi

# Create backup
log_info "Starting backup of ${VW_DATA_DIR}"

# Get data directory size
DATA_SIZE=$(du -sh "${VW_DATA_DIR}" | cut -f1)
log_info "Data directory size: ${DATA_SIZE}"

# Create compressed archive
log_info "Creating archive: ${BACKUP_NAME}"
if tar -czf "${BACKUP_PATH}" -C "$(dirname "${VW_DATA_DIR}")" "$(basename "${VW_DATA_DIR}")"; then
    BACKUP_SIZE=$(du -sh "${BACKUP_PATH}" | cut -f1)
    log_info "Backup created successfully (${BACKUP_SIZE})"
else
    log_error "Failed to create backup archive"
    exit 1
fi

# Verify backup integrity
log_info "Verifying backup integrity..."
if tar -tzf "${BACKUP_PATH}" > /dev/null; then
    log_info "Backup integrity verified"
else
    log_error "Backup integrity check failed"
    rm -f "${BACKUP_PATH}"
    exit 1
fi

# Cloud sync (if enabled)
if [ "${CLOUD_ENABLED}" = "true" ]; then
    if [ -z "${CLOUD_REMOTE}" ]; then
        log_warn "Cloud backup enabled but CLOUD_REMOTE not set, skipping cloud sync"
    elif ! command -v rclone &> /dev/null; then
        log_warn "rclone not found, skipping cloud sync"
    else
        log_info "Syncing to cloud storage: ${CLOUD_REMOTE}"
        if rclone copy "${BACKUP_PATH}" "${CLOUD_REMOTE}/vaultwarden-backups/"; then
            log_info "Cloud sync completed successfully"
        else
            log_error "Cloud sync failed (local backup still available)"
        fi
    fi
fi

# Apply retention policy
log_info "Applying retention policy (${RETENTION_DAYS} days)..."
DELETED_COUNT=$(find "${BACKUP_DIR}" -name "vaultwarden_*.tar.gz" -mtime +${RETENTION_DAYS} -delete -print | wc -l)
if [ "${DELETED_COUNT}" -gt 0 ]; then
    log_info "Deleted ${DELETED_COUNT} old backup(s)"
fi

# Summary
REMAINING_BACKUPS=$(find "${BACKUP_DIR}" -name "vaultwarden_*.tar.gz" | wc -l)
TOTAL_BACKUP_SIZE=$(du -sh "${BACKUP_DIR}" | cut -f1)
log_info "Backup completed successfully"
log_info "Local backups: ${REMAINING_BACKUPS} (total size: ${TOTAL_BACKUP_SIZE})"
```

2. Make script executable:

```bash
chmod +x apps/vaultwarden/backup.sh
```

3. Add backup configuration to `.env.example`:

```bash
# =============================================================================
# VAULTWARDEN BACKUPS
# =============================================================================

# Local backup directory (must exist and be writable)
VW_BACKUP_DIR=/var/backups/vaultwarden

# Number of days to keep local backups
VW_BACKUP_RETENTION_DAYS=30

# Enable cloud backup sync (true/false)
VW_BACKUP_CLOUD_ENABLED=false

# Rclone remote path (format: remote:path)
# Example: "s3:my-bucket" or "b2:vaultwarden-backups"
VW_BACKUP_CLOUD_REMOTE=
```

4. Copy to your `.env` and configure:

```bash
cp .env.example .env
# Edit .env and fill in backup settings
```

### Manual Test

1. Run backup manually:

```bash
cd apps/vaultwarden
./backup.sh
```

2. Verify backup was created:

```bash
ls -lh /var/backups/vaultwarden/
```

3. Check backup contents:

```bash
tar -tzf /var/backups/vaultwarden/vaultwarden_*.tar.gz | head -20
```

---

## Task 03 — Setup Automated Backups (Cron)

### Steps

1. Create systemd timer (recommended) or use cron:

**Option A: Systemd Timer (Recommended)**

Create `/etc/systemd/system/vaultwarden-backup.service`:

```ini
[Unit]
Description=Vaultwarden Backup
After=docker.service

[Service]
Type=oneshot
User=your-user
WorkingDirectory=/path/to/bedroom-server/apps/vaultwarden
ExecStart=/path/to/bedroom-server/apps/vaultwarden/backup.sh
StandardOutput=journal
StandardError=journal
```

Create `/etc/systemd/system/vaultwarden-backup.timer`:

```ini
[Unit]
Description=Vaultwarden Daily Backup Timer

[Timer]
# Run daily at 3 AM
OnCalendar=daily
OnCalendar=*-*-* 03:00:00
Persistent=true

[Install]
WantedBy=timers.target
```

Enable and start timer:

```bash
sudo systemctl daemon-reload
sudo systemctl enable vaultwarden-backup.timer
sudo systemctl start vaultwarden-backup.timer
```

**Option B: Cron Job**

```bash
crontab -e
```

Add line:

```cron
# Vaultwarden daily backup at 3 AM
0 3 * * * /path/to/bedroom-server/apps/vaultwarden/backup.sh >> /var/log/vaultwarden-backup.log 2>&1
```

2. Create log rotation config (optional):

Create `/etc/logrotate.d/vaultwarden-backup`:

```
/var/log/vaultwarden-backup.log {
    daily
    rotate 14
    compress
    delaycompress
    missingok
    notifempty
}
```

### Manual Test

**For Systemd:**

```bash
# Check timer status
sudo systemctl status vaultwarden-backup.timer

# List all timers
sudo systemctl list-timers

# Run backup manually via systemd
sudo systemctl start vaultwarden-backup.service

# Check logs
journalctl -u vaultwarden-backup.service -n 50
```

**For Cron:**

```bash
# List cron jobs
crontab -l

# Check logs
tail -f /var/log/vaultwarden-backup.log
```

---

## Task 04 — Create Restore Script

### Steps

1. Create `apps/vaultwarden/restore.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Vaultwarden Restore Script
# =============================================================================
# Restores Vaultwarden data from backup archive
# =============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "${SCRIPT_DIR}")"
ENV_FILE="${ROOT_DIR}/.env"

if [ ! -f "${ENV_FILE}" ]; then
    echo -e "${RED}Error: .env file not found${NC}"
    exit 1
fi

set -a
source "${ENV_FILE}"
set +a

# Configuration
BACKUP_DIR="${VW_BACKUP_DIR:-/var/backups/vaultwarden}"

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

log_warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Validation
if [ -z "${VW_DATA_DIR}" ]; then
    log_error "VW_DATA_DIR not set in .env"
    exit 1
fi

# List available backups
echo ""
log_info "Available backups:"
echo ""
BACKUPS=($(ls -t "${BACKUP_DIR}"/vaultwarden_*.tar.gz 2>/dev/null))

if [ ${#BACKUPS[@]} -eq 0 ]; then
    log_error "No backups found in ${BACKUP_DIR}"
    exit 1
fi

for i in "${!BACKUPS[@]}"; do
    SIZE=$(du -h "${BACKUPS[$i]}" | cut -f1)
    DATE=$(basename "${BACKUPS[$i]}" | sed 's/vaultwarden_\(.*\)\.tar\.gz/\1/')
    echo "  [$i] $(basename "${BACKUPS[$i]}") (${SIZE}) - ${DATE}"
done

echo ""
read -p "Select backup number to restore [0-$((${#BACKUPS[@]}-1))]: " BACKUP_NUM

if ! [[ "${BACKUP_NUM}" =~ ^[0-9]+$ ]] || [ "${BACKUP_NUM}" -ge "${#BACKUPS[@]}" ]; then
    log_error "Invalid backup number"
    exit 1
fi

SELECTED_BACKUP="${BACKUPS[$BACKUP_NUM]}"
log_info "Selected: $(basename "${SELECTED_BACKUP}")"

# Safety checks
if [ -d "${VW_DATA_DIR}" ]; then
    echo ""
    log_warn "Data directory exists: ${VW_DATA_DIR}"
    log_warn "Current data will be backed up to ${VW_DATA_DIR}.pre-restore-$(date +%s)"
    echo ""
    read -p "Continue with restore? [y/N] " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Restore cancelled"
        exit 0
    fi
fi

# Stop services
log_info "Stopping Vaultwarden services..."
cd "${SCRIPT_DIR}"
./down.sh || log_warn "Failed to stop services (may not be running)"

# Backup current data
if [ -d "${VW_DATA_DIR}" ]; then
    BACKUP_SUFFIX="pre-restore-$(date +%s)"
    log_info "Backing up current data to ${VW_DATA_DIR}.${BACKUP_SUFFIX}"
    mv "${VW_DATA_DIR}" "${VW_DATA_DIR}.${BACKUP_SUFFIX}"
fi

# Create data directory
mkdir -p "$(dirname "${VW_DATA_DIR}")"

# Extract backup
log_info "Extracting backup..."
if tar -xzf "${SELECTED_BACKUP}" -C "$(dirname "${VW_DATA_DIR}")"; then
    log_info "Backup extracted successfully"
else
    log_error "Failed to extract backup"
    if [ -d "${VW_DATA_DIR}.${BACKUP_SUFFIX}" ]; then
        log_info "Restoring previous data..."
        rm -rf "${VW_DATA_DIR}"
        mv "${VW_DATA_DIR}.${BACKUP_SUFFIX}" "${VW_DATA_DIR}"
    fi
    exit 1
fi

# Verify restored data
if [ -f "${VW_DATA_DIR}/db.sqlite3" ]; then
    log_info "Database file verified"
else
    log_error "Database file not found after restore"
    exit 1
fi

# Start services
log_info "Starting Vaultwarden services..."
./up.sh

echo ""
log_info "Restore completed successfully!"
log_info "Previous data saved at: ${VW_DATA_DIR}.${BACKUP_SUFFIX}"
log_info "You can delete it once you verify the restore: rm -rf ${VW_DATA_DIR}.${BACKUP_SUFFIX}"
echo ""
```

2. Make executable:

```bash
chmod +x apps/vaultwarden/restore.sh
```

### Manual Test

**Test restore to temporary location:**

```bash
# Create test restore directory
mkdir -p /tmp/vw-restore-test

# Extract backup
tar -xzf /var/backups/vaultwarden/vaultwarden_*.tar.gz -C /tmp/vw-restore-test

# Verify contents
ls -la /tmp/vw-restore-test/vaultwarden/

# Cleanup
rm -rf /tmp/vw-restore-test
```

---

## Task 05 — Setup Backup Monitoring

### Steps

1. Create health check script `apps/vaultwarden/check-backups.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Vaultwarden Backup Health Check
# =============================================================================
# Verifies backup status and alerts on issues
# =============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "${SCRIPT_DIR}")"
ENV_FILE="${ROOT_DIR}/.env"

set -a
source "${ENV_FILE}" 2>/dev/null || true
set +a

BACKUP_DIR="${VW_BACKUP_DIR:-/var/backups/vaultwarden}"
MAX_AGE_HOURS=26  # Alert if latest backup older than 26 hours

log_info() {
    echo -e "${GREEN}✓${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1" >&2
}

log_warn() {
    echo -e "${YELLOW}!${NC} $1"
}

EXIT_CODE=0

echo "=== Vaultwarden Backup Health Check ==="
echo ""

# Check if backup directory exists
if [ ! -d "${BACKUP_DIR}" ]; then
    log_error "Backup directory does not exist: ${BACKUP_DIR}"
    EXIT_CODE=1
else
    log_info "Backup directory exists: ${BACKUP_DIR}"
fi

# Find latest backup
LATEST_BACKUP=$(ls -t "${BACKUP_DIR}"/vaultwarden_*.tar.gz 2>/dev/null | head -1)

if [ -z "${LATEST_BACKUP}" ]; then
    log_error "No backups found in ${BACKUP_DIR}"
    EXIT_CODE=1
else
    # Check backup age
    BACKUP_AGE=$(($(date +%s) - $(stat -f %m "${LATEST_BACKUP}" 2>/dev/null || stat -c %Y "${LATEST_BACKUP}")))
    BACKUP_AGE_HOURS=$((BACKUP_AGE / 3600))
    
    if [ ${BACKUP_AGE_HOURS} -gt ${MAX_AGE_HOURS} ]; then
        log_error "Latest backup is too old: ${BACKUP_AGE_HOURS} hours ($(basename "${LATEST_BACKUP}"))"
        EXIT_CODE=1
    else
        log_info "Latest backup age: ${BACKUP_AGE_HOURS} hours ($(basename "${LATEST_BACKUP}"))"
    fi
    
    # Check backup integrity
    if tar -tzf "${LATEST_BACKUP}" > /dev/null 2>&1; then
        log_info "Latest backup integrity: OK"
    else
        log_error "Latest backup is corrupted: $(basename "${LATEST_BACKUP}")"
        EXIT_CODE=1
    fi
    
    # Check backup size
    BACKUP_SIZE=$(stat -f %z "${LATEST_BACKUP}" 2>/dev/null || stat -c %s "${LATEST_BACKUP}")
    BACKUP_SIZE_MB=$((BACKUP_SIZE / 1024 / 1024))
    
    if [ ${BACKUP_SIZE_MB} -lt 1 ]; then
        log_error "Latest backup is suspiciously small: ${BACKUP_SIZE_MB} MB"
        EXIT_CODE=1
    else
        log_info "Latest backup size: ${BACKUP_SIZE_MB} MB"
    fi
fi

# Count total backups
BACKUP_COUNT=$(ls "${BACKUP_DIR}"/vaultwarden_*.tar.gz 2>/dev/null | wc -l)
log_info "Total backups: ${BACKUP_COUNT}"

# Check disk space
BACKUP_DISK_USAGE=$(df -h "${BACKUP_DIR}" | tail -1 | awk '{print $5}' | sed 's/%//')
if [ ${BACKUP_DISK_USAGE} -gt 90 ]; then
    log_warn "Backup disk usage high: ${BACKUP_DISK_USAGE}%"
elif [ ${BACKUP_DISK_USAGE} -gt 80 ]; then
    log_warn "Backup disk usage: ${BACKUP_DISK_USAGE}%"
else
    log_info "Backup disk usage: ${BACKUP_DISK_USAGE}%"
fi

echo ""
if [ ${EXIT_CODE} -eq 0 ]; then
    echo -e "${GREEN}All backup checks passed${NC}"
else
    echo -e "${RED}Some backup checks failed${NC}"
fi

exit ${EXIT_CODE}
```

2. Make executable:

```bash
chmod +x apps/vaultwarden/check-backups.sh
```

3. Add to cron for daily health checks:

```bash
crontab -e
```

Add:

```cron
# Check backup health daily at 9 AM
0 9 * * * /path/to/bedroom-server/apps/vaultwarden/check-backups.sh || echo "Vaultwarden backup check failed" | mail -s "Backup Alert" your-email@example.com
```

Or use a monitoring service (see Task 06).

### Manual Test

```bash
./check-backups.sh
```

Should show all green checkmarks if backups are healthy.

---

## Task 06 — Setup Alerting (Optional)

### Option A: Email Alerts via SendGrid/Mailgun

1. Install mail utilities:

```bash
sudo apt-get install mailutils
```

2. Configure with your SMTP provider

3. Update backup script to send email on failure

### Option B: Healthchecks.io (Recommended)

1. Sign up at https://healthchecks.io (free plan available)

2. Create new check with schedule "Daily"

3. Add to backup script:

```bash
# At the end of backup.sh, before exit
HEALTHCHECK_URL="${VW_BACKUP_HEALTHCHECK_URL:-}"
if [ -n "${HEALTHCHECK_URL}" ]; then
    curl -fsS -m 10 --retry 5 "${HEALTHCHECK_URL}" > /dev/null
fi
```

4. Add to `.env`:

```bash
VW_BACKUP_HEALTHCHECK_URL=https://hc-ping.com/your-uuid-here
```

### Option C: Uptime Kuma (Self-hosted)

Set up Uptime Kuma and create HTTP push monitor for backup script.

---

## Task 07 — Document Recovery Procedures

### Quick Recovery Procedure

1. **Stop services:**
   ```bash
   cd apps/vaultwarden
   ./down.sh
   ```

2. **Run restore script:**
   ```bash
   ./restore.sh
   ```

3. **Select backup from list**

4. **Script automatically:**
   - Backs up current data
   - Extracts selected backup
   - Starts services

5. **Verify in browser:**
   - Open `https://vault.yourdomain.com`
   - Login and check data

### Cloud Restore

If local backups are lost:

1. **List cloud backups:**
   ```bash
   rclone ls remote:vaultwarden-backups/
   ```

2. **Download backup:**
   ```bash
   rclone copy remote:vaultwarden-backups/vaultwarden_TIMESTAMP.tar.gz /var/backups/vaultwarden/
   ```

3. **Run restore script:**
   ```bash
   cd apps/vaultwarden
   ./restore.sh
   ```

### Full Disaster Recovery

If entire server is lost:

1. **Setup new server** with Docker and Docker Compose

2. **Clone repository:**
   ```bash
   git clone <repo-url> bedroom-server
   cd bedroom-server
   ```

3. **Download backup from cloud:**
   ```bash
   mkdir -p /var/backups/vaultwarden
   rclone copy remote:vaultwarden-backups/ /var/backups/vaultwarden/
   ```

4. **Restore configuration:**
   - Copy `.env` from secure location
   - Or recreate from `.env.example`

5. **Run restore:**
   ```bash
   cd apps/vaultwarden
   ./restore.sh
   ```

6. **Reconfigure Cloudflare Tunnel** (if token changed)

---

## Task 08 — Test Recovery Procedures

### Steps

1. **Create test backup:**
   ```bash
   ./backup.sh
   ```

2. **Add test data** to Vaultwarden:
   - Login to web vault
   - Create unique test entry
   - Note the entry name/details

3. **Perform test restore:**
   ```bash
   ./restore.sh
   ```
   - Select a backup from before the test entry
   - Verify test entry is gone after restore

4. **Restore to current:**
   ```bash
   ./restore.sh
   ```
   - Select the latest backup
   - Verify test entry is back

5. **Test cloud recovery** (if configured):
   - Delete local backups
   - Restore from cloud
   - Verify data integrity

### Success Criteria

- [ ] Backup script runs without errors
- [ ] Backup files are created with correct timestamp
- [ ] Restore script successfully restores data
- [ ] Services start after restore
- [ ] Can login and access passwords after restore
- [ ] Cloud sync works (if enabled)
- [ ] Old backups are cleaned up per retention policy
- [ ] Monitoring/alerts work correctly

---

## Configuration Reference

### Environment Variables (.env)

```bash
# =============================================================================
# VAULTWARDEN BACKUPS
# =============================================================================

# Local backup directory (must exist and be writable)
VW_BACKUP_DIR=/var/backups/vaultwarden

# Number of days to keep local backups
VW_BACKUP_RETENTION_DAYS=30

# Enable cloud backup sync (true/false)
VW_BACKUP_CLOUD_ENABLED=true

# Rclone remote path (format: remote:path)
VW_BACKUP_CLOUD_REMOTE=b2:vaultwarden-backups

# Cloud backup retention (days) - cleanup manually or via rclone filters
VW_BACKUP_CLOUD_RETENTION_DAYS=90

# Healthcheck URL (optional, for monitoring)
VW_BACKUP_HEALTHCHECK_URL=https://hc-ping.com/your-uuid-here
```

### Disk Space Requirements

| Data Size | Local Backups (30d) | Cloud Backups (90d) | Total |
|-----------|---------------------|---------------------|-------|
| 100 MB    | ~3 GB               | ~9 GB               | ~12 GB |
| 500 MB    | ~15 GB              | ~45 GB              | ~60 GB |
| 1 GB      | ~30 GB              | ~90 GB              | ~120 GB |

*Assumes daily backups, ~0.7x compression ratio*

---

## Maintenance Tasks

### Weekly

- [ ] Check backup logs for errors
- [ ] Verify latest backup age

### Monthly

- [ ] Test restore procedure
- [ ] Check disk space usage
- [ ] Verify cloud backups exist
- [ ] Review retention policies

### Quarterly

- [ ] Perform full disaster recovery test
- [ ] Review and update documentation
- [ ] Update backup scripts if needed

---

## Troubleshooting

### Backup Script Fails

**Issue:** `VW_DATA_DIR not set in .env`
- **Solution:** Add `VW_DATA_DIR` to `.env` file

**Issue:** `Permission denied` when creating backup
- **Solution:** Check backup directory permissions:
  ```bash
  sudo chown $USER:$USER /var/backups/vaultwarden
  ```

**Issue:** `Disk quota exceeded`
- **Solution:** Clean old backups or increase disk space:
  ```bash
  df -h /var/backups
  find /var/backups/vaultwarden -name "*.tar.gz" -mtime +7 -delete
  ```

### Cloud Sync Fails

**Issue:** `rclone: command not found`
- **Solution:** Install rclone:
  ```bash
  curl https://rclone.org/install.sh | sudo bash
  ```

**Issue:** `Failed to copy: access denied`
- **Solution:** Reconfigure rclone remote with correct credentials:
  ```bash
  rclone config
  ```

### Restore Fails

**Issue:** `Backup is corrupted`
- **Solution:** Try previous backup or restore from cloud

**Issue:** Services won't start after restore
- **Solution:** Check logs and verify file permissions:
  ```bash
  docker compose logs vaultwarden
  sudo chown -R $USER:$USER ${VW_DATA_DIR}
  ```

---

## Security Considerations

### Backup Security

1. **Encryption at rest:**
   - Use encrypted filesystem for backup directory
   - Or encrypt backups before cloud upload:
     ```bash
     gpg --symmetric --cipher-algo AES256 backup.tar.gz
     ```

2. **Access control:**
   - Limit backup directory access:
     ```bash
     chmod 700 /var/backups/vaultwarden
     ```
   - Use separate cloud account for backups
   - Enable MFA on cloud storage

3. **Secrets management:**
   - **Never** backup `.env` file with automated scripts
   - Store `.env` separately in password manager or encrypted USB
   - Document how to recreate `.env` from scratch

### Recovery Testing

- Test restores regularly (quarterly minimum)
- Document recovery time objective (RTO): < 1 hour
- Verify restored data integrity
- Keep offline emergency vault export

---

## Alternative Approaches

### Database-only Backups

If storage is limited, backup only the SQLite database:

```bash
# In backup.sh, use sqlite3 backup command
sqlite3 ${VW_DATA_DIR}/db.sqlite3 ".backup ${BACKUP_DIR}/db_${TIMESTAMP}.sqlite3"
gzip ${BACKUP_DIR}/db_${TIMESTAMP}.sqlite3
```

**Pros:** Much smaller backups
**Cons:** Doesn't include attachments or keys

### Docker Volume Backups

Use docker volume backup tools:

```bash
docker run --rm \
  -v vaultwarden_data:/data \
  -v /var/backups:/backup \
  alpine tar czf /backup/vaultwarden_$(date +%Y%m%d).tar.gz -C /data .
```

---

## Resources

- [Vaultwarden Backup Wiki](https://github.com/dani-garcia/vaultwarden/wiki/Backing-up-your-vault)
- [SQLite Backup API](https://www.sqlite.org/backup.html)
- [Rclone Documentation](https://rclone.org/docs/)
- [Systemd Timers](https://www.freedesktop.org/software/systemd/man/systemd.timer.html)
- [Healthchecks.io](https://healthchecks.io)

---

## Summary

This plan provides a comprehensive backup solution for Vaultwarden with:

✅ Automated daily backups
✅ Multi-tier storage (local + cloud)
✅ Automated retention policies  
✅ One-command restore procedures
✅ Health monitoring and alerting
✅ Documented disaster recovery

**Implementation Time:** ~2-3 hours for basic setup + testing

**Next Steps:**
1. Complete Task 01-02 for basic backup functionality
2. Add Task 03 for automation
3. Implement Task 04-05 for restore and monitoring
4. Test thoroughly (Task 08)
5. Setup alerting (Task 06) for production
