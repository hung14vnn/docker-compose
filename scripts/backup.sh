#!/usr/bin/env bash
# =============================================================================
# Media Stack — Backup
# =============================================================================
# Creates a timestamped .tar.gz archive of config/, databases, and music.
# Usage:
#   ./scripts/backup.sh                          # backup everything
#   ./scripts/backup.sh /path/to/backup/dir       # custom destination
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$ROOT_DIR"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

info()  { echo -e "${CYAN}[INFO]${NC}  $*"; }
ok()    { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
fail()  { echo -e "${RED}[FAIL]${NC}  $*"; exit 1; }

# ── Destination ─────────────────────────────────────────────────────────────
DEST="${1:-.}"
DEST_DIR="$(cd "$DEST" 2>/dev/null && pwd)" || fail "Destination '$DEST' does not exist."
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${DEST_DIR}/media-stack_backup_${TIMESTAMP}.tar.gz"

# ── Pre-flight checks ───────────────────────────────────────────────────────
[ -d config ]  || warn "config/ directory not found — backup may be incomplete."
[ -d data ]    || warn "data/ directory not found — backup may be incomplete."

info "Backup destination: $BACKUP_FILE"

# ── Disk space check ────────────────────────────────────────────────────────
SPACE_NEEDED=$(du -sb config data 2>/dev/null | awk '{s+=$1} END {print s/1024/1024/0}')
SPACE_AVAIL=$(df -m "$DEST_DIR" | awk 'NR==2 {print $4}')
if [ -n "$SPACE_NEEDED" ] && [ "$SPACE_NEEDED" -ge "$SPACE_AVAIL" ]; then
  fail "Not enough disk space. Need ~${SPACE_NEEDED}M, have ${SPACE_AVAIL}M."
fi

# ── Database dumps (Lidarr + Prowlarr) ─────────────────────────────────────
info "Dumping application databases …"
mkdir -p /tmp/media-stack-backup

dump_sqlite() {
  local label=$1
  local db_path=$2
  local dump_path="/tmp/media-stack-backup/${label}.sql"
  if [ -f "$db_path" ]; then
    sqlite3 "$db_path" ".dump" > "$dump_path" 2>/dev/null || \
      warn "Failed to dump ${label} database."
  else
    warn "Database not found: ${db_path}"
  fi
}

dump_sqlite "lidarr"   "config/lidarr/lidarr.db"
dump_sqlite "prowlarr" "config/prowlarr/prowlarr.db"

# ── Create archive ─────────────────────────────────────────────────────────
info "Creating archive (this may take a while) …"

tar --create \
  --gzip \
  --file="$BACKUP_FILE" \
  --exclude="data/torrents/*.!qB" \
  --exclude="data/torrents/*.parts" \
  --exclude="*/cache/*" \
  --exclude="*/logs/*" \
  --exclude="*/log/*" \
  config/ \
  data/media/music \
  data/soulseek \
  -C /tmp/media-stack-backup . 2>/dev/null || {
    # Fallback without db dumps
    warn "tar with db dumps failed — falling back to raw backup."
    tar --create --gzip --file="$BACKUP_FILE" \
      --exclude="data/torrents/*.!qB" \
      --exclude="data/torrents/*.parts" \
      --exclude="*/cache/*" \
      --exclude="*/logs/*" \
      --exclude="*/log/*" \
      config/ \
      data/media/music \
      data/soulseek
  }

# ── Cleanup temp ────────────────────────────────────────────────────────────
rm -rf /tmp/media-stack-backup

# ── Verify & report ─────────────────────────────────────────────────────────
if [ -f "$BACKUP_FILE" ]; then
  SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
  ok "Backup complete: $BACKUP_FILE  ($SIZE)"
else
  fail "Backup file was not created."
fi
