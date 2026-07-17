# Reverse Proxy (Caddy)

## Overview

Caddy reverse proxy provides:

- **Single entry point** via your domain
- **Automatic SSL** via Let's Encrypt (HTTP-01 or Cloudflare DNS-01)
- **Domain-based routing** to individual services
- **Security headers** (HSTS, CORS, etc.)
- **HTTP/3** (QUIC) support
- **Automatic certificate renewal**

## Subdomains

| Subdomain | Service | Public? |
|-----------|---------|---------|
| `navidrome.$DOMAIN` | Navidrome streaming | Yes |
| `requests.$DOMAIN` | Musicseerr requests | Yes |
| `lidarr.$DOMAIN` | Lidarr management | No |
| `prowlarr.$DOMAIN` | Prowlarr indexers | No |
| `slskd.$DOMAIN` | slskd web UI | No |
| `qb.$DOMAIN` | qBittorrent web UI | No |
| `$DOMAIN` | Root → redirects to Navidrome | Yes |

## DNS Setup

### Option A — Cloudflare DNS-01 (recommended)

1. Add your domain to Cloudflare
2. Create an API token with `Zone:DNS:Edit` permission
3. Set `CF_API_TOKEN` in `.env`
4. Caddy automatically provisions wildcard-capable certs

### Option B — HTTP-01 (standard)

1. Point your domain's A/AAAA record to your server's public IP
2. Ensure port 80 is reachable from the internet
3. Leave `CF_API_TOKEN` empty in `.env`

## Usage

### With Caddy

```bash
./scripts/init.sh  # creates config/caddy/

# Edit .env — set DOMAIN and CADDY_EMAIL
nano .env

# Start full stack with proxy
docker compose \
  -f compose/compose.yml \
  -f compose/compose.vpn.yml \
  -f compose/compose.download.yml \
  -f compose/compose.media.yml \
  -f compose/compose.request.yml \
  -f compose/compose.proxy.yml \
  up -d
```

### With Caddy + Cloudflare Tunnel

Run both `compose.proxy.yml` and `compose.cloudflare.yml`.
In the Cloudflare Zero Trust dashboard, configure the tunnel to point to `http://caddy:80` or `https://caddy:443`.

## Security

- All admin subdomains (lidarr, prowlarr, etc.) should be protected with Caddy's `basicauth` or forward auth (e.g., Authelia) — add middleware in the Caddyfile
- Caddy runs with `no-new-privileges:true`
- The `caddy` container is on the `vpn` network solely to reach qBittorrent (via Gluetun)
