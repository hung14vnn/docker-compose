#!/usr/bin/env bash
# =============================================================================
# Media Stack — Update
# =============================================================================
# Pulls latest images, recreates containers, prunes old images.
# Usage:
#   ./scripts/update.sh              # full stack
#   ./scripts/update.sh vpn          # only VPN group
#   ./scripts/update.sh download     # only download group
#   ./scripts/update.sh media        # only media group
#   ./scripts/update.sh request      # only request group
#   ./scripts/update.sh proxy        # only reverse proxy
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

COMPOSE_BASE="-f compose/compose.yml"
COMPOSE_FILES=()

select_group() {
  case "${1:-all}" in
    vpn)
      COMPOSE_FILES=("$COMPOSE_BASE" "-f compose/compose.vpn.yml")
      ;;
    download|dl)
      COMPOSE_FILES=("$COMPOSE_BASE" "-f compose/compose.vpn.yml" "-f compose/compose.download.yml")
      ;;
    media)
      COMPOSE_FILES=("$COMPOSE_BASE" "-f compose/compose.vpn.yml" "-f compose/compose.download.yml" "-f compose/compose.media.yml")
      ;;
    request|req)
      COMPOSE_FILES=("$COMPOSE_BASE" "-f compose/compose.vpn.yml" "-f compose/compose.download.yml" "-f compose/compose.media.yml" "-f compose/compose.request.yml")
      ;;
    all)
      COMPOSE_FILES=("$COMPOSE_BASE" "-f compose/compose.vpn.yml" "-f compose/compose.download.yml" "-f compose/compose.media.yml" "-f compose/compose.request.yml" "-f compose/compose.proxy.yml")
      if [ -f compose/compose.cloudflare.yml ]; then
        COMPOSE_FILES+=("-f compose/compose.cloudflare.yml")
      fi
      ;;
    proxy)
      COMPOSE_FILES=("$COMPOSE_BASE" "-f compose/compose.proxy.yml")
      ;;
    *)
      echo "Usage: $0 [vpn|download|media|request|proxy|all]"
      exit 1
      ;;
  esac
}

select_group "${1:-all}"

echo ""
info "Updating group: ${1:-all}"
echo ""

# ── 1. Pull latest images ─────────────────────────────────────────────────
info "Pulling latest images …"
docker compose "${COMPOSE_FILES[@]}" pull
ok "Images pulled."

# ── 2. Recreate containers ────────────────────────────────────────────────
info "Recreating containers …"
docker compose "${COMPOSE_FILES[@]}" up --detach --remove-orphans
ok "Containers recreated."

# ── 3. Prune old images ───────────────────────────────────────────────────
info "Cleaning up unused images …"
docker image prune --force --filter "until=24h" 2>/dev/null || true
ok "Unused images pruned."

echo ""
info "────────── Update complete ──────────"
echo ""
