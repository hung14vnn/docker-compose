#!/usr/bin/env bash
# =============================================================================
# Media Stack — Restore
# =============================================================================
# Restores config, databases, and music from a previous backup.
# Usage:
#   ./scripts/restore.sh /path/to/media-stack_backup_20250717_120000.tar.gz
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

# ── Validate arguments ─────────────────────────────────────────────────────
if [ $# -lt 1 ]; then
  echo "Usage: $0 <backup-file.tar.gz> [--dry-run]"
  exit 1
fi

BACKUP_FILE="$1"
DRY_RUN="${2:-}"

if [ ! -f "$BACKUP_FILE" ]; then
  fail "Backup file not found: $BACKUP_FILE"
fi

# ── Confirm ─────────────────────────────────────────────────────────────────
echo ""
warn "This will OVERWRITE existing config/ and data/media/music directories."
echo ""
if [ "$DRY_RUN" != "--dry-run" ]; then
  read -rp "Continue? [y/N] " confirm
  if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "Aborted."
    exit 0
  fi
fi

# ── Stop the stack ──────────────────────────────────────────────────────────
if [ "$DRY_RUN" != "--dry-run" ]; then
  info "Stopping the media stack …"
  docker compose \
    -f compose/compose.yml \
    -f compose/compose.vpn.yml \
    -f compose/compose.download.yml \
    -f compose/compose.media.yml \
    -f compose/compose.request.yml \
    -f compose/compose.proxy.yml \
    down 2>/dev/null || warn "Could not stop stack (may not be running)."
fi

# ── Backup current state just in case ──────────────────────────────────────
SAFETY_BACKUP="/tmp/media-stack_pre_restore_$(date +%Y%m%d_%H%M%S).tar.gz"
if [ "$DRY_RUN" != "--dry-run" ]; then
  info "Creating safety backup at $SAFETY_BACKUP …"
  tar --create --gzip --file="$SAFETY_BACKUP" \
    config/ data/media/music data/soulseek 2>/dev/null || \
    warn "Safety backup failed — continuing anyway."
fi

# ── Extract ─────────────────────────────────────────────────────────────────
info "Restoring from $BACKUP_FILE …"

if [ "$DRY_RUN" == "--dry-run" ]; then
  info "[DRY-RUN] Would extract:"
  tar --list --gzip --file="$BACKUP_FILE" | head -40
  ok "Dry-run complete."
  exit 0
fi

tar --extract --gzip --file="$BACKUP_FILE" --overwrite --directory="$ROOT_DIR" 2>/dev/null || \
  fail "Extraction failed."

ok "Files restored."

# ── Restore databases from SQL dumps (if present) ──────────────────────────
restore_sqlite() {
  local label=$1
  local dump_file="${ROOT_DIR}/${label}.sql"
  local db_file="$2"
  if [ -f "$dump_file" ]; then
    info "Restoring ${label} database …"
    rm -f "$db_file"
    sqlite3 "$db_file" ".read $dump_file" 2>/dev/null && \
      ok "${label} database restored." || \
      warn "Failed to restore ${label} database."
    rm -f "$dump_file"
  fi
}

restore_sqlite "lidarr"   "config/lidarr/lidarr.db"
restore_sqlite "prowlarr" "config/prowlarr/prowlarr.db"

# ── Permissions ─────────────────────────────────────────────────────────────
info "Setting permissions …"
chmod -R 755 config/ 2>/dev/null || warn "Could not chmod config/"
chmod -R 755 data/ 2>/dev/null   || warn "Could not chmod data/"
ok "Permissions set."

# ── Done ────────────────────────────────────────────────────────────────────
echo ""
info "────────── Restore complete ──────────"
echo ""
echo "Restart the stack:"
echo "  docker compose -f compose/compose.yml \\"
echo "    -f compose/compose.vpn.yml \\"
echo "    -f compose/compose.download.yml \\"
echo "    -f compose/compose.media.yml \\"
echo "    -f compose/compose.request.yml up -d"
echo ""
