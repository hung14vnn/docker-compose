# Installation

## Requirements

| Requirement | Version | Notes |
|-------------|---------|-------|
| Docker Engine | 24+ | [install guide](https://docs.docker.com/engine/install/) |
| Docker Compose | v2.21+ | Included with Docker Desktop / Engine |
| OS | Linux | Windows/macOS possible with limitations |
| Disk | 20 GB+ | For music library growth |

## Quick Start

```bash
git clone https://github.com/your-org/media-stack.git
cd media-stack

./scripts/init.sh

# Edit your .env file
nano .env

# Start the full stack
docker compose \
  -f compose/compose.yml \
  -f compose/compose.vpn.yml \
  -f compose/compose.download.yml \
  -f compose/compose.media.yml \
  -f compose/compose.request.yml \
  up -d

# Check health
./scripts/healthcheck.sh
```

## .env Configuration

| Variable | Required | Description |
|----------|----------|-------------|
| `VPN_SERVICE_PROVIDER` | Yes | VPN provider (mullvad, protonvpn, etc.) |
| `WIREGUARD_PRIVATE_KEY` | For WG | WireGuard private key |
| `WIREGUARD_ADDRESSES` | For WG | WireGuard IPs |
| `SLSKD_USERNAME` | Yes | Soulseek username |
| `SLSKD_PASSWORD` | Yes | Soulseek password |
| `ND_USERS` | Yes | Navidrome user:pass |
| `DOMAIN` | For proxy | Your domain (e.g. `music.example.com`) |
| `CADDY_EMAIL` | For proxy | Email for Let's Encrypt |
| `CF_API_TOKEN` | Optional | Cloudflare DNS-01 challenge |
| `TUNNEL_TOKEN` | For CF | Cloudflare tunnel token |
| `PUID`/`PGID` | Yes | User/group ID for file permissions |

## Running Subsets

```bash
# VPN + qBittorrent only
docker compose -f compose/compose.yml -f compose/compose.vpn.yml up -d

# Add download services (Prowlarr, slskd)
docker compose -f compose/compose.yml -f compose/compose.vpn.yml \
  -f compose/compose.download.yml up -d

# Media management + streaming
docker compose -f compose/compose.yml -f compose/compose.vpn.yml \
  -f compose/compose.download.yml -f compose/compose.media.yml up -d

# With reverse proxy
docker compose -f compose/compose.yml -f compose/compose.vpn.yml \
  -f compose/compose.download.yml -f compose/compose.media.yml \
  -f compose/compose.request.yml -f compose/compose.proxy.yml up -d

# Full stack with Cloudflare Tunnel
docker compose -f compose/compose.yml -f compose/compose.vpn.yml \
  -f compose/compose.download.yml -f compose/compose.media.yml \
  -f compose/compose.request.yml -f compose/compose.proxy.yml \
  -f compose/compose.cloudflare.yml up -d
```

## Port Reference

| Port | Service | Purpose |
|------|---------|---------|
| 8080 | qBittorrent | Web UI (via Gluetun) |
| 9696 | Prowlarr | Web UI |
| 8686 | Lidarr | Web UI |
| 5030 | slskd | Web UI |
| 5000 | slskd | Soulseek P2P |
| 4533 | Navidrome | Streaming |
| 5055 | Musicseerr | Request portal |
| 80/443 | Caddy | Reverse proxy |
