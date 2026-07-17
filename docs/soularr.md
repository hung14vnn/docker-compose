# Soularr — Lidarr ↔ Soulseek Bridge

## Overview

Soularr monitors Lidarr for albums that are missing or have no active downloads,
then searches for them on Soulseek (via slskd) and downloads the files.

## How It Works

```
Lidarr ──► Soularr checks for missing tracks
               │
               ▼
          slskd (Soulseek) searches
               │
               ▼
          Downloads found files
               │
               ▼
          /data/soulseek ──► Lidarr imports
```

## Configuration

Configure Soularr via environment variables in `.env`:

| Variable | Description |
|----------|-------------|
| `LIDARR_API_KEY` | API key from Lidarr **Settings > General** |
| `SLSKD_USERNAME` | Soulseek username (same as slskd) |
| `SLSKD_PASSWORD` | Soulseek password |

## Check Interval

Soularr checks every 30 minutes (configurable via `SOULARR_INTERVAL_MINUTES`).

## Logs

```bash
docker compose -f compose/compose.yml -f compose/compose.media.yml logs soularr
```

## Troubleshooting

- **Soularr can't connect to Lidarr**: Verify `LIDARR_URL=http://lidarr:8686` and the API key
- **Soularr can't connect to slskd**: Verify slskd is running and credentials are correct
- **No downloads**: Check Soulseek has results for the searched albums
