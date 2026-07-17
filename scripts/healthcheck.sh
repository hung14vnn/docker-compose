#!/usr/bin/env bash
# =============================================================================
# Media Stack — Health Check
# =============================================================================
# Checks each service's HTTP endpoint or container state.
# Usage:
#   ./scripts/healthcheck.sh         # verbose report
#   ./scripts/healthcheck.sh --quiet # exit code only
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$ROOT_DIR"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m'

info()    { echo -e "${CYAN}[INFO]${NC}    $*"; }
ok()      { echo -e "${GREEN}[HEALTHY]${NC} $*"; }
warn()    { echo -e "${YELLOW}[DEGRADED]${NC} $*"; }
critical(){ echo -e "${RED}[DOWN]${NC}    $*"; }

QUIET=false
[[ "${1:-}" == "--quiet" ]] && QUIET=true

declare -a FAILURES=()
declare -a DEGRADED=()

# ── Helper: check HTTP endpoint ─────────────────────────────────────────────
check_http() {
  local service=$1
  local url=$2
  local timeout=${3:-5}

  if curl -sf --max-time "$timeout" "$url" >/dev/null 2>&1; then
    "$QUIET" || ok "$service — $url"
    return 0
  else
    critical "$service — $url (unreachable)"
    FAILURES+=("$service")
    return 1
  fi
}

# ── Helper: check container health ─────────────────────────────────────────
check_container() {
  local service=$1
  local container_name

  # Try to get the container name from Docker Compose
  container_name=$(docker compose \
    -f compose/compose.yml \
    -f compose/compose.vpn.yml \
    -f compose/compose.download.yml \
    -f compose/compose.media.yml \
    -f compose/compose.request.yml \
    ps --format '{{.Name}}' 2>/dev/null | grep "$service" || true)

  if [ -z "$container_name" ]; then
    "$QUIET" || warn "$service — container not running"
    DEGRADED+=("$service")
    return 1
  fi

  local status
  status=$(docker inspect --format='{{.State.Health.Status}}' "$container_name" 2>/dev/null || echo "no-healthcheck")

  case "$status" in
    healthy)
      "$QUIET" || ok "$service — health: healthy"
      return 0
      ;;
    unhealthy)
      critical "$service — health: UNHEALTHY"
      FAILURES+=("$service")
      return 2
      ;;
    starting)
      warn "$service — health: starting"
      DEGRADED+=("$service")
      return 1
      ;;
    *)
      # Running but no healthcheck
      local running
      running=$(docker inspect --format='{{.State.Status}}' "$container_name" 2>/dev/null)
      if [ "$running" = "running" ]; then
        "$QUIET" || ok "$service — running (no healthcheck)"
        return 0
      else
        critical "$service — state: $running"
        FAILURES+=("$service")
        return 2
      fi
      ;;
  esac
}

# ── Checks ──────────────────────────────────────────────────────────────────
echo ""
"$QUIET" || info "Media Stack — Health Check"
"$QUIET" || echo ""

# VPN / Gateway
check_http "Gluetun" "http://localhost:8080" 5 || true

# Torrent
check_http "qBittorrent" "http://localhost:8080" 5 || true

# Download services
check_http "Prowlarr" "http://localhost:9696/ping" 5 || true
check_http "slskd" "http://localhost:5030/health" 5 || true

# Media services
check_http "Lidarr" "http://localhost:8686/ping" 5 || true
check_http "Navidrome" "http://localhost:4533/ping" 5 || true

# Reverse proxy
check_http "Caddy" "http://localhost:80" 5 || true

# Request services
check_http "Musicseerr" "http://localhost:5055/health" 5 || true

# Container-level checks (fallback for services without HTTP)
"$QUIET" || echo ""
"$QUIET" || info "Container-level checks:"
check_container "soularr" || true

# ── Report ──────────────────────────────────────────────────────────────────
echo ""
if [ ${#FAILURES[@]} -eq 0 ] && [ ${#DEGRADED[@]} -eq 0 ]; then
  "$QUIET" || ok "All services healthy."
  exit 0
fi

if [ ${#FAILURES[@]} -gt 0 ]; then
  critical "Unreachable: ${FAILURES[*]}"
fi
if [ ${#DEGRADED[@]} -gt 0 ]; then
  warn "Degraded: ${DEGRADED[*]}"
fi

"$QUIET" || echo ""
"$QUIET" || info "Hint: run ./scripts/update.sh to refresh containers."
echo ""

[ ${#FAILURES[@]} -eq 0 ]
