# Fix Cloudflare Tunnel Service

If the tunnel service is failing, try these steps:

## Quick Fix

```bash
# Stop the service
sudo systemctl stop cloudflared

# Start it again
sudo systemctl start cloudflared

# Check status
sudo systemctl status cloudflared
```

## If Still Failing

The token might be expired or invalid. Get a fresh one:

1. Go to Cloudflare Dashboard → Zero Trust → Tunnels
2. Click your tunnel
3. Click "Configure" 
4. Copy the new token command
5. Run:
   ```bash
   sudo cloudflared service uninstall
   sudo cloudflared service install [NEW-TOKEN]
   sudo systemctl start cloudflared
   ```

## Check Logs

```bash
# View recent logs
sudo journalctl -u cloudflared -n 50 --no-pager

# Follow logs in real-time
sudo journalctl -u cloudflared -f
```

## Manual Start (Temporary)

If service won't start, run manually to test:

```bash
cloudflared tunnel --token [YOUR-TOKEN]
```

This will help identify if it's a service issue or token/network issue.

