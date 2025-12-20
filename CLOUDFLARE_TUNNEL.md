# Deploying Enjoyyy with Cloudflare Tunnels

This guide will help you deploy Enjoyyy to **enjoyyy.mmmmichael.com** using Cloudflare Tunnels (formerly Argo Tunnel).

## Why Cloudflare Tunnels?

✅ **No open ports** - Services run behind Cloudflare's network  
✅ **Automatic SSL** - Free HTTPS certificates  
✅ **DDoS protection** - Built-in Cloudflare protection  
✅ **Easy domain setup** - Simple DNS configuration  
✅ **Run anywhere** - Local machine, VPS, or server  

## Architecture

```
┌─────────────────────────────────────────┐
│         Cloudflare Network              │
│  ┌───────────────────────────────────┐  │
│  │  enjoyyy.mmmmichael.com/          │  │
│  │    → Frontend (localhost:3000)    │  │
│  │  enjoyyy.mmmmichael.com/api/*     │  │
│  │    → Backend (localhost:5000)     │  │
│  └───────────────────────────────────┘  │
└─────────────────────────────────────────┘
              ↓ Tunnel
┌─────────────────────────────────────────┐
│         Your Server/Machine             │
│  ┌──────────────┐  ┌──────────────┐   │
│  │  Frontend    │  │  Backend     │   │
│  │  :3000       │  │  :5000       │   │
│  └──────────────┘  └──────────────┘   │
└─────────────────────────────────────────┘
```

## Prerequisites

1. **Cloudflare account** with `mmmmichael.com` added (base domain)
2. **Domain DNS** managed by Cloudflare
3. **cloudflared** installed on your server

## Step 1: Install cloudflared

### Linux
```bash
# Download latest release
wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64
sudo mv cloudflared-linux-amd64 /usr/local/bin/cloudflared
sudo chmod +x /usr/local/bin/cloudflared
```

### macOS
```bash
brew install cloudflared
```

### Or use package manager
```bash
# Debian/Ubuntu
sudo apt install cloudflared

# Fedora
sudo dnf install cloudflared
```

## Step 2: Authenticate with Cloudflare

```bash
cloudflared tunnel login
```

This will:
1. Open your browser
2. Select your domain (`mmmmichael.com` - the base domain)
3. Authorize the tunnel
4. Save credentials to `~/.cloudflared/cert.pem`

## Step 3: Create Tunnel

```bash
cloudflared tunnel create enjoyyy-tunnel
```

This creates a tunnel named `enjoyyy-tunnel` and saves credentials.

## Step 4: Configure DNS Routes

```bash
# Route subdomain to tunnel
cloudflared tunnel route dns enjoyyy-tunnel enjoyyy.mmmmichael.com
```

Or configure manually in Cloudflare Dashboard:
1. Go to DNS → Records
2. Add CNAME record:
   - **Name**: `enjoyyy` → **Target**: `enjoyyy-tunnel-xxxxx.cfargotunnel.com`

## Step 5: Configure Tunnel

The configuration file `cloudflare-tunnel.yml` is already set up:

- `enjoyyy.mmmmichael.com/` → Frontend (localhost:3000)
- `enjoyyy.mmmmichael.com/api/*` → Backend (localhost:5000)

## Step 6: Update CORS (Already Done!)

The backend CORS is already configured to allow:
- `https://enjoyyy.mmmmichael.com`

## Step 7: Start Services

### Option A: Manual Start

**Terminal 1 - Backend:**
```bash
cd /home/mlayug/Documents/GitHub/enjoyyy
python3 backend_server.py
```

**Terminal 2 - Frontend:**
```bash
cd /home/mlayug/Documents/GitHub/enjoyyy/frontend
npm run dev
```

**Terminal 3 - Cloudflare Tunnel:**
```bash
cd /home/mlayug/Documents/GitHub/enjoyyy
cloudflared tunnel --config cloudflare-tunnel.yml run
```

### Option B: Systemd Services (Recommended for Production)

Create systemd service files for automatic startup:

#### Backend Service

```bash
sudo nano /etc/systemd/system/enjoyyy-backend.service
```

```ini
[Unit]
Description=Enjoyyy Backend Server
After=network.target

[Service]
Type=simple
User=mlayug
WorkingDirectory=/home/mlayug/Documents/GitHub/enjoyyy
Environment="PORT=5000"
ExecStart=/usr/bin/python3 /home/mlayug/Documents/GitHub/enjoyyy/backend_server.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

#### Frontend Service

```bash
sudo nano /etc/systemd/system/enjoyyy-frontend.service
```

```ini
[Unit]
Description=Enjoyyy Frontend Server
After=network.target

[Service]
Type=simple
User=mlayug
WorkingDirectory=/home/mlayug/Documents/GitHub/enjoyyy/frontend
Environment="PORT=3000"
ExecStart=/usr/bin/npm run dev
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

#### Cloudflare Tunnel Service

```bash
sudo nano /etc/systemd/system/cloudflared-tunnel.service
```

```ini
[Unit]
Description=Cloudflare Tunnel for Enjoyyy
After=network.target

[Service]
Type=simple
User=mlayug
ExecStart=/usr/local/bin/cloudflared tunnel --config /home/mlayug/Documents/GitHub/enjoyyy/cloudflare-tunnel.yml run
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

**Enable and start services:**
```bash
sudo systemctl enable enjoyyy-backend
sudo systemctl enable enjoyyy-frontend
sudo systemctl enable cloudflared-tunnel

sudo systemctl start enjoyyy-backend
sudo systemctl start enjoyyy-frontend
sudo systemctl start cloudflared-tunnel

# Check status
sudo systemctl status enjoyyy-backend
sudo systemctl status enjoyyy-frontend
sudo systemctl status cloudflared-tunnel
```

### Option C: Docker Compose

Create `docker-compose.yml`:

```yaml
version: '3.8'

services:
  backend:
    build:
      context: .
      dockerfile: Dockerfile.backend
    ports:
      - "5000:5000"
    restart: unless-stopped
    environment:
      - PORT=5000

  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
    ports:
      - "3000:3000"
    restart: unless-stopped
    environment:
      - NEXT_PUBLIC_API_URL=https://enjoyyy.mmmmichael.com
      - PORT=3000
    depends_on:
      - backend

  cloudflared:
    image: cloudflare/cloudflared:latest
    command: tunnel --config /etc/cloudflared/config.yml run
    volumes:
      - ./cloudflare-tunnel.yml:/etc/cloudflared/config.yml:ro
      - ~/.cloudflared:/etc/cloudflared/credentials:ro
    restart: unless-stopped
    depends_on:
      - backend
      - frontend
```

## Step 8: Update Frontend API URL

The frontend is already configured to use the same origin (`enjoyyy.mmmmichael.com`) for API calls.

For local development, create `frontend/.env.local`:
```env
NEXT_PUBLIC_API_URL=http://localhost:5000
```

## Step 9: Verify Deployment

1. **Check services are running:**
   ```bash
   curl http://localhost:5000/  # Backend
   curl http://localhost:3000/  # Frontend
   ```

2. **Test through Cloudflare:**
   ```bash
   curl https://enjoyyy.mmmmichael.com/      # Frontend
   curl https://enjoyyy.mmmmichael.com/api/  # Backend API
   ```

3. **Test in browser:**
   - Visit `https://enjoyyy.mmmmichael.com`
   - Try creating a mystery link
   - Verify audio streaming works

## Troubleshooting

### Tunnel not connecting
```bash
# Check tunnel status
cloudflared tunnel info enjoyyy-tunnel

# View tunnel logs
cloudflared tunnel --config cloudflare-tunnel.yml run --loglevel debug
```

### Services not accessible
- Verify services are running: `ps aux | grep -E "(python|node|cloudflared)"`
- Check ports are listening: `netstat -tuln | grep -E "(3000|5000)"`
- Check firewall: `sudo ufw status`

### DNS not resolving
- Wait for DNS propagation (5-60 minutes)
- Check DNS records in Cloudflare dashboard
- Verify tunnel is running: `cloudflared tunnel list`

### CORS errors
- Verify backend CORS includes your domain
- Check browser console for specific CORS errors
- Ensure `https://` is used (not `http://`)

## Monitoring

### View tunnel metrics
```bash
cloudflared tunnel info enjoyyy-tunnel
```

### View service logs
```bash
# Backend
journalctl -u enjoyyy-backend -f

# Frontend
journalctl -u enjoyyy-frontend -f

# Tunnel
journalctl -u cloudflared-tunnel -f
```

## Security Considerations

1. **Keep services on localhost** - Only accessible through tunnel
2. **Use Cloudflare WAF** - Enable in Cloudflare dashboard
3. **Rate limiting** - Configure in Cloudflare dashboard
4. **Environment variables** - Don't commit secrets
5. **Regular updates** - Keep cloudflared and dependencies updated

## Benefits of This Setup

✅ **No VPS required** - Can run on your local machine  
✅ **Free SSL** - Automatic HTTPS  
✅ **DDoS protection** - Cloudflare's network  
✅ **Easy updates** - Just restart services  
✅ **Full control** - Your code, your server  

## Next Steps

1. ✅ Install cloudflared
2. ✅ Create tunnel and configure DNS
3. ✅ Start backend and frontend services
4. ✅ Start Cloudflare tunnel
5. ✅ Test the application
6. 🎉 Share your mystery music platform!

---

**Need help?** Check Cloudflare tunnel docs: https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/

