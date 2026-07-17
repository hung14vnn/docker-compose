#!/usr/bin/env bash
# =============================================================================
# Media Stack — Initialisation
# =============================================================================
# One-time setup: directories, .env, permissions, Docker check, network.
# Usage:
#   cd /path/to/media-stack
#   ./scripts/init.sh
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$ROOT_DIR"

# ── Colours ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

info()  { echo -e "${CYAN}[INFO]${NC}  $*"; }
ok()    { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
fail()  { echo -e "${RED}[FAIL]${NC}  $*"; exit 1; }

# ── 1. Check Docker ─────────────────────────────────────────────────────────
info "Checking Docker installation..."

if ! command -v docker &>/dev/null; then
  fail "Docker is not installed. See https://docs.docker.com/engine/install/"
fi

if ! docker compose version &>/dev/null; then
  fail "Docker Compose v2 is not available. Update Docker."
fi

ok "Docker $(docker --version) | Compose $(docker compose version --short)"

# ── 2. Create directory structure ───────────────────────────────────────────
info "Creating directory structure..."

mkdir -p \
  config/gluetun \
  config/qbittorrent \
  config/prowlarr \
  config/lidarr \
  config/slskd \
  config/soularr \
  config/navidrome \
  config/musicseerr \
  config/caddy \
  data/torrents \
  data/soulseek \
  data/media/music \
  compose \
  scripts \
  docs

ok "Directories created."

# ── 3. Create .env from example ─────────────────────────────────────────────
if [ -f .env ]; then
  warn ".env already exists — skipping."
else
  if [ -f .env.example ]; then
    cp .env.example .env
    ok ".env created from .env.example — EDIT IT with your settings."
  else
    warn ".env.example not found — creating minimal .env"
    cat > .env <<-EOF
PUID=$(id -u 2>/dev/null || echo 1000)
PGID=$(id -g 2>/dev/null || echo 1000)
TZ=UTC
CONFIG_DIR=./config
DATA_DIR=./data
VPN_SERVICE_PROVIDER=mullvad
VPN_TYPE=wireguard
WIREGUARD_PRIVATE_KEY=
WIREGUARD_ADDRESSES=
WIREGUARD_DNS=
SERVER_REGIONS=
QBITTORRENT_USER=admin
QBITTORRENT_PASS=adminadmin
PROWLARR_API_KEY=
LIDARR_API_KEY=
SLSKD_USERNAME=
SLSKD_PASSWORD=
ND_LOGIN_ENABLED=true
ND_USERS=admin:password
EOF
    ok "Minimal .env created — EDIT IT."
  fi
fi

# ── 4. Set permissions ──────────────────────────────────────────────────────
info "Setting permissions on config/ and data/ …"
chmod -R 755 config/ 2>/dev/null || warn "Could not chmod config/ (run as root if needed)"
chmod -R 755 data/ 2>/dev/null   || warn "Could not chmod data/"
ok "Permissions set."

# ── 5. Create Docker network if missing ─────────────────────────────────────
info "Checking Docker networks …"
if ! docker network ls --format '{{.Name}}' | grep -q '^media_stack_internal$'; then
  docker network create media_stack_internal --driver bridge --internal 2>/dev/null || \
    warn "Could not create 'media_stack_internal' — will be auto-created by Compose."
else
  ok "Network 'media_stack_internal' exists."
fi

if ! docker network ls --format '{{.Name}}' | grep -q '^media_stack_media$'; then
  docker network create media_stack_media --driver bridge 2>/dev/null || \
    warn "Could not create 'media_stack_media'."
else
  ok "Network 'media_stack_media' exists."
fi

# ── 6. Summary ──────────────────────────────────────────────────────────────
echo ""
info "────────── Setup complete ──────────"
echo ""
echo -e "  ${CYAN}Next steps:${NC}"
echo "    1. Edit .env with your settings"
echo "    2. Start the stack:"
echo "       docker compose -f compose/compose.yml \\"
echo "         -f compose/compose.vpn.yml \\"
echo "         -f compose/compose.download.yml \\"
echo "         -f compose/compose.media.yml \\"
echo "         -f compose/compose.request.yml up -d"
echo ""
    echo "    Or start individual groups:"
    echo "       make vpn     # Gluetun + qBittorrent"
    echo "       make dl      # + Prowlarr + slskd"
    echo "       make media   # + Lidarr + Soularr + Navidrome"
    echo "       make proxy   # + Caddy reverse proxy"
    echo "       make all     # full stack"
echo ""
