# Media Stack

Self-hosted music management, downloading, and streaming stack — fully containerised with Docker Compose.

```
User
  │
  ├──► Caddy (Reverse Proxy — optional)
  │
  ├──► Musicseerr (Request Portal)
  │       │
  │       ▼
  │     Lidarr (Music Manager)
  │     ┌─────┴──────┐
  │     ▼            ▼
  │  Prowlarr     Soularr
  │     │            │
  │     ▼            ▼
  │  qBittorrent   slskd
  │    (VPN)      (Soulseek)
  │     │            │
  │     └────┬───────┘
  │          ▼
  │     /data/media/music
  │          │
  │     Navidrome (Streaming)
  │          │
  │     Cloudflare Tunnel (optional)
```

## Architecture

| Layer | Services | Purpose |
|-------|----------|---------|
| **Proxy** | Caddy | Reverse proxy, SSL, domain routing |
| **Request** | Musicseerr | User-facing request portal |
| **Manager** | Lidarr, Soularr | Music library management, Soulseek bridge |
| **Download** | Prowlarr, qBittorrent, slskd | Indexers, torrenting, Soulseek |
| **VPN** | Gluetun | WireGuard/OpenVPN for qBittorrent |
| **Media** | Navidrome | Music streaming (Subsonic-compatible) |
| **Tunnel** | Cloudflare Tunnel | Zero-trust external access (optional) |

## Requirements

- Docker Engine 24+ & Compose v2.21+
- Linux (recommended), macOS, or Windows
- 20 GB+ disk for music library

## Quick Start

```bash
git clone https://github.com/your-org/media-stack.git
cd media-stack

./scripts/init.sh

# Edit .env
nano .env

# Start full stack
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

## Compose Files

| File | Services | Required |
|------|----------|----------|
| `compose.yml` | Networks, volumes, anchors | Yes |
| `compose.vpn.yml` | Gluetun, qBittorrent | Recommended |
| `compose.download.yml` | Prowlarr, slskd | Recommended |
| `compose.media.yml` | Lidarr, Soularr, Navidrome | Recommended |
| `compose.request.yml` | Musicseerr | Recommended |
| `compose.proxy.yml` | Caddy reverse proxy | Optional |
| `compose.cloudflare.yml` | Cloudflare Tunnel | Optional |

## Scripts

| Script | Purpose |
|--------|---------|
| `scripts/init.sh` | Create directories, .env, permissions, networks |
| `scripts/update.sh` | Pull images, recreate containers, prune old images |
| `scripts/backup.sh` | Backup config + music to `.tar.gz` |
| `scripts/restore.sh` | Restore from a backup archive |
| `scripts/healthcheck.sh` | Check all services' HTTP/health endpoints |

### Running subsets

```bash
./scripts/update.sh vpn      # only Gluetun + qBittorrent
./scripts/update.sh dl       # + Prowlarr + slskd
./scripts/update.sh media    # + Lidarr + Soularr + Navidrome
./scripts/update.sh proxy    # + Caddy
./scripts/update.sh all      # full stack
```

## Compose Features

- **Healthchecks** — every service has a configured healthcheck
- **depends_on condition** — services wait for healthy dependencies
- **YAML anchors** — shared `x-logging`, `x-restart`, `x-healthcheck` configs
- **.env** — all configuration via environment file
- **Logging limits** — `max-size: 10m`, `max-file: 3`
- **Named networks** — `vpn` (VPN-routed), `internal` (isolated), `media` (streaming)
- **Security opts** — `no-new-privileges:true` on all services
- **tmpfs** — volatile temp directories in containers
- **Restart policy** — `unless-stopped` on all services

## Ports

| Port | Service | Notes |
|------|---------|-------|
| 8080 | qBittorrent | Via Gluetun |
| 9696 | Prowlarr | — |
| 8686 | Lidarr | — |
| 5030 | slskd | Web UI |
| 5000 | slskd | Soulseek P2P |
| 4533 | Navidrome | — |
| 5055 | Musicseerr | — |
| 80/443 | Caddy | Reverse proxy |

## Data Layout

```
config/
├── gluetun/        # VPN config
├── qbittorrent/    # qBittorrent config
├── prowlarr/       # Prowlarr config + DB
├── lidarr/         # Lidarr config + DB
├── slskd/          # slskd config
├── soularr/        # Soularr config
├── navidrome/      # Navidrome DB + cache
├── musicseerr/     # Musicseerr config
└── caddy/          # Caddy config + SSL certs

data/
├── torrents/       # qBittorrent downloads
├── soulseek/       # slskd downloads
└── media/music/    # Final organised music library
```

## Documentation

- [Installation](docs/installation.md)
- [Reverse Proxy (Caddy)](docs/proxy.md)
- [Lidarr Configuration](docs/lidarr.md)
- [Prowlarr Configuration](docs/prowlarr.md)
- [Navidrome Setup](docs/navidrome.md)
- [Soularr (Soulseek Bridge)](docs/soularr.md)
- [Troubleshooting](docs/troubleshooting.md)

## Backup & Restore

```bash
# Backup
./scripts/backup.sh /path/to/backup/dir

# Restore (stops the stack first)
./scripts/restore.sh /path/to/media-stack_backup_20250717_120000.tar.gz
```

Backups include: all `config/`, `data/media/music`, `data/soulseek`, and SQL dumps of Lidarr/Prowlarr databases.

## Security

- All services run with `no-new-privileges:true`
- Internal services are on an `internal: true` network (no external access)
- qBittorrent routes through WireGuard/OpenVPN via Gluetun
- Caddy applies HSTS, security headers
- Cloudflare Tunnel option for zero-trust external access (no open ports)
- Admin subdomains (lidarr, prowlarr, etc.) should be protected with basic auth
