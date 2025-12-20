#!/bin/bash
# Quick setup script for Cloudflare Tunnel

set -e

echo "🔧 Setting up Cloudflare Tunnel for Enjoyyy"
echo ""

# Check if cloudflared is installed
if ! command -v cloudflared &> /dev/null; then
    echo "❌ cloudflared is not installed"
    echo ""
    echo "Install it:"
    echo "  Linux:   wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64"
    echo "  macOS:   brew install cloudflared"
    echo ""
    exit 1
fi

echo "✓ cloudflared is installed"
echo ""

# Check if already logged in
if [ ! -f ~/.cloudflared/cert.pem ]; then
    echo "🔐 Authenticating with Cloudflare..."
    echo "   (This will open your browser)"
    cloudflared tunnel login
else
    echo "✓ Already authenticated with Cloudflare"
fi

echo ""

# Check if tunnel exists
if cloudflared tunnel list | grep -q "enjoyyy-tunnel"; then
    echo "✓ Tunnel 'enjoyyy-tunnel' already exists"
else
    echo "📦 Creating tunnel 'enjoyyy-tunnel'..."
    cloudflared tunnel create enjoyyy-tunnel
    echo "✓ Tunnel created"
fi

echo ""

# Configure DNS routes
echo "🌐 Configuring DNS routes..."
echo "   (You may need to confirm in Cloudflare dashboard)"

cloudflared tunnel route dns enjoyyy-tunnel enjoyyy.mmmmichael.com 2>/dev/null || echo "   Note: enjoyyy.mmmmichael.com route may already exist"

echo ""
echo "✅ Setup complete!"
echo ""
echo "📋 Next steps:"
echo ""
echo "1. Configure DNS in Cloudflare Dashboard:"
echo "   - Go to: https://dash.cloudflare.com"
echo "   - Select domain: mmmmichael.com"
echo "   - Go to: DNS → Records"
echo "   - Add CNAME:"
echo "     Name: enjoyyy"
echo "     Target: [see tunnel info above]"
echo "     Proxy: 🟠 Proxied (ON)"
echo ""
echo "   OR run this to get the tunnel target:"
echo "   cloudflared tunnel route dns list"
echo ""
echo "2. Start services: ./start_with_tunnel.sh"
echo "   Or manually:"
echo "   - Terminal 1: python3 backend_server.py"
echo "   - Terminal 2: cd frontend && npm run dev"
echo "   - Terminal 3: cloudflared tunnel --config cloudflare-tunnel.yml run"
echo ""
echo "📖 See CLOUDFLARE_SETUP.md for detailed dashboard instructions"
echo ""

