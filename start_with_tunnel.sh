#!/bin/bash
# Start Enjoyyy with Cloudflare Tunnel

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "🎭 Starting Enjoyyy with Cloudflare Tunnel"
echo ""

# Check if cloudflared is installed
if ! command -v cloudflared &> /dev/null; then
    echo "❌ cloudflared is not installed"
    echo "Install it: https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/installation/"
    exit 1
fi

# Check if tunnel config exists
if [ ! -f "cloudflare-tunnel.yml" ]; then
    echo "❌ cloudflare-tunnel.yml not found"
    exit 1
fi

# Check ports
check_port() {
    python3 -c "import socket; s = socket.socket(); s.settimeout(0.1); result = s.connect_ex(('127.0.0.1', $1)); s.close(); exit(0 if result == 0 else 1)" 2>/dev/null
}

# Find available ports
find_port() {
    local start=$1
    local port=$start
    while [ $port -lt $((start + 100)) ]; do
        if ! check_port $port; then
            echo $port
            return 0
        fi
        port=$((port + 1))
    done
    return 1
}

# Use fixed ports - don't auto-detect since Cloudflare routes are configured for these
BACKEND_PORT=5000
FRONTEND_PORT=3001

# Just verify services are accessible, don't change ports
if ! check_port $BACKEND_PORT; then
    echo "⚠️  Backend port $BACKEND_PORT is not responding"
    echo "   Make sure backend is running: python3 backend_server.py"
fi

if ! check_port $FRONTEND_PORT; then
    echo "⚠️  Frontend port $FRONTEND_PORT is not responding"
    echo "   Will start frontend on port $FRONTEND_PORT"
fi

echo ""
echo "Starting services:"
echo "  Backend:  http://localhost:$BACKEND_PORT"
echo "  Frontend: http://localhost:$FRONTEND_PORT"
echo "  Tunnel:   Running cloudflared"
echo ""
echo "Press Ctrl+C to stop all services"
echo ""

# Note: Services run in background, no cleanup trap needed
# User can stop them manually with pkill commands

# Check if backend is already running
if check_port $BACKEND_PORT; then
    echo "✓ Backend already running on port $BACKEND_PORT"
    BACKEND_PID=$(pgrep -f "python3 backend_server.py" | head -1)
else
    # Start backend
    export PORT=$BACKEND_PORT
    python3 backend_server.py > /tmp/enjoyyy_backend.log 2>&1 &
    BACKEND_PID=$!
    echo "✓ Backend started on port $BACKEND_PORT (PID: $BACKEND_PID)"
fi

# Wait for backend
sleep 2

# Start frontend
cd frontend
export PORT=$FRONTEND_PORT
# Use the dev:3001 script if port 3001, otherwise use regular dev
if [ "$FRONTEND_PORT" = "3001" ]; then
    npm run dev:3001 > /tmp/enjoyyy_frontend.log 2>&1 &
else
    PORT=$FRONTEND_PORT npm run dev > /tmp/enjoyyy_frontend.log 2>&1 &
fi
FRONTEND_PID=$!
echo "✓ Frontend started on port $FRONTEND_PORT (PID: $FRONTEND_PID)"

# Wait for frontend
sleep 3

# Check if cloudflared is already running as a service
if systemctl is-active --quiet cloudflared 2>/dev/null; then
    echo "✓ Cloudflare tunnel already running as systemd service"
    TUNNEL_PID="systemd-service"
elif pgrep -f "cloudflared.*tunnel" > /dev/null; then
    echo "✓ Cloudflare tunnel already running"
    TUNNEL_PID=$(pgrep -f "cloudflared.*tunnel" | head -1)
else
    # Start Cloudflare tunnel
    cd "$SCRIPT_DIR"
    cloudflared tunnel --config cloudflare-tunnel.yml run > /tmp/enjoyyy_tunnel.log 2>&1 &
    TUNNEL_PID=$!
    echo "✓ Cloudflare tunnel started (PID: $TUNNEL_PID)"
fi

echo ""
echo "🎉 All services running in background!"
echo ""
echo "View logs:"
echo "  Backend:  tail -f /tmp/enjoyyy_backend.log"
echo "  Frontend: tail -f /tmp/enjoyyy_frontend.log"
echo "  Tunnel:   tail -f /tmp/enjoyyy_tunnel.log"
echo ""
echo "To stop services:"
echo "  pkill -f 'python3 backend_server.py'"
echo "  pkill -f 'npm run dev'"
echo "  sudo systemctl stop cloudflared"
echo ""

# Exit immediately - services are running in background
exit 0

