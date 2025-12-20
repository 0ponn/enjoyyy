# Fixing Cloudflare Tunnel Error 1033

Error 1033 means Cloudflare can't reach your tunnel connector. Here's how to fix it:

## Quick Checks

1. **Is cloudflared running?**
   ```bash
   ps aux | grep cloudflared
   ```
   ✅ You have this running

2. **Is the connector connected in dashboard?**
   - Go to Cloudflare Dashboard → Zero Trust → Tunnels
   - Click your tunnel
   - Check "Connectors" section
   - Should show "Connected" status

3. **Are your services running?**
   - Backend: `curl http://localhost:5000/`
   - Frontend: `curl http://localhost:3001/`

## Common Fixes

### Fix 1: Restart the Tunnel Connector

The tunnel connector might have disconnected. Restart it:

1. Stop the current cloudflared process:
   ```bash
   sudo pkill cloudflared
   ```

2. Get the new token from dashboard:
   - Go to Zero Trust → Tunnels → Your tunnel
   - Click "Configure"
   - Copy the command with the token

3. Run it again:
   ```bash
   cloudflared tunnel --token [YOUR-TOKEN]
   ```

### Fix 2: Verify Routes Match Services

In dashboard → Published applications, verify:
- Route 1: `/api/*` → `http://localhost:5000` ✅
- Route 2: `/` → `http://localhost:3001` ⚠️ (Make sure frontend is running!)

### Fix 3: Check Connector Status

1. Go to Cloudflare Dashboard → Zero Trust → Tunnels
2. Click your tunnel
3. Look at "Connectors" section
4. Should show your connector as "Connected"
5. If it shows "Disconnected", the connector isn't running or can't reach Cloudflare

### Fix 4: Start Missing Services

If frontend isn't running:
```bash
cd /home/mlayug/Documents/GitHub/enjoyyy/frontend
PORT=3001 npm run dev
```

If backend isn't running:
```bash
cd /home/mlayug/Documents/GitHub/enjoyyy
python3 backend_server.py
```

## Most Likely Issue

Based on your setup, the tunnel connector is running but might be:
1. **Not connected** - Check dashboard connector status
2. **Pointing to wrong services** - Verify routes match running services
3. **Frontend not running** - Start it on port 3001

## Verify Everything

Run this checklist:
```bash
# 1. Check services
curl http://localhost:5000/  # Should return HTML
curl http://localhost:3001/  # Should return HTML

# 2. Check tunnel
ps aux | grep cloudflared  # Should show running process

# 3. Check dashboard
# Go to Zero Trust → Tunnels → Your tunnel
# Connectors should show "Connected"
```

Once all three are good, wait 1-2 minutes and try `https://enjoyyy.mmmmichael.com` again.

