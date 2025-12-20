#!/bin/bash
# Quick verification script for Enjoyyy setup

echo "🔍 Verifying Enjoyyy Setup"
echo ""

# Check services
echo "1. Checking services..."
BACKEND_OK=false
FRONTEND_OK=false

if curl -s -o /dev/null -w "%{http_code}" http://localhost:5000/ | grep -q "200"; then
    echo "   ✓ Backend (localhost:5000) is running"
    BACKEND_OK=true
else
    echo "   ✗ Backend (localhost:5000) is not responding"
fi

if curl -s -o /dev/null -w "%{http_code}" http://localhost:3001/ 2>/dev/null | grep -q "200"; then
    echo "   ✓ Frontend (localhost:3001) is running"
    FRONTEND_OK=true
else
    echo "   ✗ Frontend (localhost:3001) is not responding"
fi

echo ""

# Check tunnel
echo "2. Checking Cloudflare tunnel..."
if pgrep -f "cloudflared.*tunnel" > /dev/null; then
    echo "   ✓ Cloudflared tunnel process is running"
else
    echo "   ✗ Cloudflared tunnel is not running"
fi

echo ""

# Check DNS (if possible)
echo "3. Checking DNS..."
if command -v dig >/dev/null 2>&1; then
    DNS_RESULT=$(dig +short enjoyyy.mmmmichael.com 2>/dev/null)
    if [ -n "$DNS_RESULT" ]; then
        echo "   ✓ DNS resolves: enjoyyy.mmmmichael.com → $DNS_RESULT"
    else
        echo "   ⚠ DNS may not be configured yet"
    fi
else
    echo "   ⚠ dig not available, skipping DNS check"
fi

echo ""

# Summary
echo "📋 Summary:"
if [ "$BACKEND_OK" = true ] && [ "$FRONTEND_OK" = true ]; then
    echo "   ✅ Services are ready!"
    echo ""
    echo "   Test locally:"
    echo "   - Frontend: http://localhost:3001"
    echo "   - Backend:  http://localhost:5000"
    echo ""
    echo "   Test via tunnel:"
    echo "   - https://enjoyyy.mmmmichael.com"
else
    echo "   ⚠ Some services need to be started"
    echo ""
    echo "   Start with: ./start_with_tunnel.sh"
fi

echo ""

