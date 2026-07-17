# Navidrome

## Access

- **Local**: http://localhost:4533
- **Domain**: https://navidrome.your.domain (with proxy)

## Clients

Navidrome is compatible with any Subsonic/OpenSubsonic client:

| Client | Platform | Notes |
|--------|----------|-------|
| **Ultrasonic** | Android | Free, open-source |
| **Symfonium** | Android | Paid, feature-rich |
| **iSub** | iOS | Paid |
| **play:Sub** | iOS/macOS | Paid |
| **Sonixd** | Desktop | Cross-platform |
| **Feishin** | Desktop | Modern UI |

## First-Time Setup

1. Open the web UI — login with credentials from `ND_USERS` in `.env`
2. Navidrome automatically scans `/music` on startup
3. For large libraries, the initial scan may take several minutes

## Volume Mounts

| Container path | Host path | Purpose |
|---------------|-----------|---------|
| `/data` | `./config/navidrome` | DB + cache |
| `/music` | `./data/media/music` | Music library |

## Configuration via .env

| Variable | Default | Description |
|----------|---------|-------------|
| `ND_LOGIN_ENABLED` | `true` | Require login |
| `ND_USERS` | — | Comma-separated `user:pass` pairs |

## Reverse Proxy Notes

When behind a reverse proxy, ensure:
- `X-Forwarded-For` header is passed (Caddy does this automatically)
- WebSocket support is enabled for real-time updates
