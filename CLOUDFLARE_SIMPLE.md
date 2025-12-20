# Cloudflare Tunnel Setup - Simple Guide

Clean, step-by-step instructions to get `enjoyyy.mmmmichael.com` working.

## Prerequisites

- Cloudflare account with `mmmmichael.com` added
- Domain DNS managed by Cloudflare
- Backend running on `localhost:5000`
- Frontend running on `localhost:3001` (port 3000 is taken)

## Step 1: Create Tunnel in Cloudflare Dashboard

1. Go to [Cloudflare Dashboard](https://dash.cloudflare.com)
2. Click **Zero Trust** (or **Cloudflare One**)
3. Go to **Networks** → **Tunnels**
4. Click **Create a tunnel**
5. Select **Cloudflared**
6. Name it: `enjoyyy-tunnel`
7. Click **Save tunnel**

**Copy the Tunnel ID** - you'll need it (format: `xxxx-xxxx-xxxx-xxxx-xxxx`)

## Step 2: Install Cloudflared (if not already installed)

```bash
# Linux
wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64
sudo mv cloudflared-linux-amd64 /usr/local/bin/cloudflared
sudo chmod +x /usr/local/bin/cloudflared

# macOS
brew install cloudflared
```

## Step 3: Authenticate Cloudflared

```bash
cloudflared tunnel login
```

This will:
- Open your browser
- Ask you to select domain: choose `mmmmichael.com`
- Save credentials automatically

## Step 4: Configure Tunnel Routing in Dashboard

Go back to **Zero Trust** → **Networks** → **Tunnels** → Click your tunnel

**Note**: You'll see two sections:
- **Published applications** - This is what you need! Use this for routing.
- **Hostname routes** - This is for private hostnames/DNS resolver policies. Ignore this for now.

### Add Backend Route (API)

1. Go to **Published applications** section
2. Click **Add an application** or **Add application**
3. Fill in:
   - **Subdomain**: `enjoyyy`
   - **Domain**: `mmmmichael.com`
   - **Path**: `/api/*`
   - **Service**: `http://localhost:5000`
4. Click **Save** or **Add application**

### Add Frontend Route

1. Still in **Published applications** section
2. Click **Add an application** or **Add application** again
3. Fill in:
   - **Subdomain**: `enjoyyy`
   - **Domain**: `mmmmichael.com`
   - **Path**: (leave empty - this is for root `/`)
   - **Service**: `http://localhost:3001`
4. Click **Save** or **Add application**

**Important**: Make sure `/api/*` route is listed ABOVE the `/` route. The order matters - more specific paths must come first.

## Step 5: Add DNS Record

1. Go to **DNS** → **Records**
2. Click **Add record**
3. Fill in:
   - **Type**: `CNAME`
   - **Name**: `enjoyyy`
   - **Target**: `[YOUR-TUNNEL-ID].cfargotunnel.com`
     - Replace `[YOUR-TUNNEL-ID]` with the tunnel ID from Step 1
     - Example: `fb12a7ad-53d1-4cc8-9e48-c5ffa5062e5d.cfargotunnel.com`
   - **Proxy status**: Click the cloud icon to make it **🟠 Proxied** (orange)
   - **TTL**: Auto
4. Click **Save**

## Step 6: Run Cloudflared

You have two options:

### Option A: Run with Token (Recommended - Managed)

1. In Cloudflare Dashboard → **Zero Trust** → **Tunnels** → Your tunnel
2. Click **Configure**
3. Copy the **Quick Start** command (it will have a token)
4. Run that command on your server

It will look like:
```bash
cloudflared tunnel --token eyJhIjoi...
```

### Option B: Run with Config File

1. Update `cloudflare-tunnel.yml` with your tunnel ID:
```yaml
tunnel: [YOUR-TUNNEL-ID]
credentials-file: /home/mlayug/.cloudflared/[TUNNEL-ID].json

ingress:
  - hostname: enjoyyy.mmmmichael.com
    path: /api/*
    service: http://localhost:5000
  - hostname: enjoyyy.mmmmichael.com
    service: http://localhost:3001
  - service: http_status:404
```

2. Run:
```bash
cloudflared tunnel --config cloudflare-tunnel.yml run
```

## Step 7: Start Your Services

Make sure both services are running:

**Terminal 1 - Backend:**
```bash
cd /home/mlayug/Documents/GitHub/enjoyyy
python3 backend_server.py
```

**Terminal 2 - Frontend:**
```bash
cd /home/mlayug/Documents/GitHub/enjoyyy/frontend
PORT=3001 npm run dev
```

**Terminal 3 - Tunnel:**
```bash
# Use the command from Step 6 (Option A or B)
```

## Step 8: Test

Wait 1-2 minutes for DNS to propagate, then:

```bash
# Test DNS
dig enjoyyy.mmmmichael.com

# Test site
curl https://enjoyyy.mmmmichael.com/

# Test API
curl https://enjoyyy.mmmmichael.com/api/
```

Or visit `https://enjoyyy.mmmmichael.com` in your browser!

## Troubleshooting

### DNS not resolving
- Wait 5-60 minutes for propagation
- Verify DNS record is **Proxied** (orange cloud)
- Check target is correct: `[TUNNEL-ID].cfargotunnel.com`

### 502/503 errors
- Verify services are running:
  ```bash
  curl http://localhost:5000/
  curl http://localhost:3001/
  ```
- Check tunnel is running: `ps aux | grep cloudflared`
- Verify routes in dashboard match your services

### Wrong route order
- In dashboard **Hostname routes**, `/api/*` must be above `/`
- Drag to reorder if needed, or delete and re-add in correct order

## Summary

1. ✅ Create tunnel in dashboard
2. ✅ Add public hostnames (2 routes)
3. ✅ Add DNS CNAME record (proxied)
4. ✅ Run cloudflared
5. ✅ Start backend (port 5000) and frontend (port 3001)
6. ✅ Test!

That's it! 🎉

