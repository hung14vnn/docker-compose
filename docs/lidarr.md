# Lidarr Configuration

## Access

- **Local**: http://localhost:8686
- **Domain**: https://lidarr.your.domain (with proxy)

## First-Time Setup

1. Open the web UI
2. Go to **Settings > Media Management**
   - Enable "Rename Files"
   - Set "Standard Album Format" to `{Artist Name}/{Album Title} ({Release Year})/{track:00} {Track Title}`
3. Go to **Settings > Download Clients**
   - Add **qBittorrent**
   - Host: `qbittorrent` (Docker DNS name)
   - Port: `8080`
   - Username/password from `.env`
   - Category: `lidarr`
4. Go to **Settings > Indexers**
   - Add indexers via Prowlarr (recommended), or add manually
5. Go to **Settings > Connect**
   - Add your preferred notification service

## Volume Mounts

| Container path | Host path | Purpose |
|---------------|-----------|---------|
| `/config` | `./config/lidarr` | Config + DB |
| `/music` | `./data/media/music` | Final music library |
| `/downloads` | `./data/torrents` | Torrent downloads |

## API Key

Find your API key in **Settings > General**. Set it in `.env` as `LIDARR_API_KEY` for Soularr integration.
