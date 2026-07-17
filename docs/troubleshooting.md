# Troubleshooting

## Healthcheck Fails

```bash
# Run detailed health check
./scripts/healthcheck.sh

# Check container logs
docker compose -f compose/compose.yml -f compose/compose.vpn.yml logs gluetun
docker compose -f compose/compose.yml -f compose/compose.download.yml logs prowlarr
docker compose -f compose/compose.yml -f compose/compose.media.yml logs lidarr
```

## VPN Not Connecting

1. Verify WireGuard keys in `.env`
2. Check Gluetun logs: `docker compose logs gluetun`
3. Test: `docker exec media-stack-gluetun-1 curl -s ifconfig.me` (should show VPN IP)
4. If using OpenVPN, set `VPN_TYPE=openvpn` and provide credentials

## qBittorrent Unreachable

1. Ensure Gluetun is healthy first (`depends_on: condition: service_healthy`)
2. qBittorrent shares Gluetun's network — check Gluetun logs for port conflicts
3. If port 8080 is in use, change the mapping in `compose.vpn.yml`

## Prowlarr / Lidarr Can't Connect

If services are in different compose groups, ensure all required files are loaded:

```bash
docker compose -f compose/compose.yml -f compose/compose.vpn.yml \
  -f compose/compose.download.yml -f compose/compose.media.yml \
  -f compose/compose.request.yml up -d
```

## Permission Issues

Files written by containers may be owned by `root` or the container user.

```bash
# Fix permissions
sudo chown -R $USER:$USER config/ data/
# Or
chmod -R 755 config/ data/
```

## Navidrome Not Scanning

- Check logs: `docker compose -f compose/compose.media.yml logs navidrome`
- Verify `/music` mount points to `./data/media/music`
- Ensure files have correct permissions (`PUID/PGID` in `.env`)

## Backup / Restore

| Issue | Solution |
|-------|----------|
| `tar` command not found | `apt install tar` or `brew install gnu-tar` |
| Restore overwrites files | Safety backup is created automatically before restore |
| Backup too large | Exclude patterns are built-in; run `./scripts/backup.sh` with destination on a different drive |

## Common Errors

| Error | Cause | Fix |
|-------|-------|-----|
| `port is already allocated` | Port conflict with host | Change the host port mapping in compose files |
| `network not found` | Networks not created | Run `./scripts/init.sh` or let Compose create them |
| `permission denied` | Incorrect PUID/PGID | Set correct values in `.env` |
| `no space left on device` | Disk full | `docker system prune -a` to clean unused images |
