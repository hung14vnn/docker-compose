# Prowlarr Configuration

## Access

- **Local**: http://localhost:9696
- **Domain**: https://prowlarr.your.domain (with proxy)

## First-Time Setup

1. Open the web UI
2. Go to **Settings > Apps**
   - Click **Add Application**
   - Select **Lidarr**
   - Prowlarr URL: `http://prowlarr:9696`
   - Lidarr URL: `http://lidarr:8686`
   - API Key: from Lidarr **Settings > General**
3. Go to **Settings > Indexers**
   - Add your preferred indexers (public or private)

## Sync with Lidarr

Once the app connection is configured, Prowlarr automatically syncs indexers to Lidarr.
- Go to **Lidarr > Settings > Indexers** to verify
- Indexer categories for music: `Audio`, `Other`

## Volume Mounts

| Container path | Host path | Purpose |
|---------------|-----------|---------|
| `/config` | `./config/prowlarr` | Config + DB |

## API Key

Find your API key in **Settings > General**. Set it in `.env` as `PROWLARR_API_KEY`.
