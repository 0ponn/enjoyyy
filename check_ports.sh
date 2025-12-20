#!/bin/bash
# Reliable port checking using multiple methods

check_port() {
    local port=$1
    local in_use=0
    
    # Method 1: Try to connect to the port (most reliable)
    # connect_ex returns 0 if connection succeeds (port is in use), non-zero if fails (port available)
    if command -v python3 >/dev/null 2>&1; then
        python3 -c "import socket; s = socket.socket(); s.settimeout(0.1); result = s.connect_ex(('127.0.0.1', $port)); s.close(); exit(0 if result == 0 else 1)" 2>/dev/null
        if [ $? -eq 0 ]; then
            in_use=1  # Port is in use
        fi
    fi
    
    # Method 2: Check with lsof (if available)
    if [ $in_use -eq 0 ] && command -v lsof >/dev/null 2>&1; then
        if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
            in_use=1
        fi
    fi
    
    # Method 3: Check with ss (modern, reliable)
    if [ $in_use -eq 0 ] && command -v ss >/dev/null 2>&1; then
        if ss -tuln 2>/dev/null | grep -q ":$port "; then
            in_use=1
        fi
    fi
    
    # Method 4: Check with netstat (fallback)
    if [ $in_use -eq 0 ] && command -v netstat >/dev/null 2>&1; then
        if netstat -tuln 2>/dev/null | grep -q ":$port "; then
            in_use=1
        fi
    fi
    
    return $in_use
}

find_available_port() {
    local start_port=$1
    local port=$start_port
    local max_port=$((start_port + 100))
    
    while [ $port -lt $max_port ]; do
        if ! check_port $port; then
            # check_port returns 0 if available, so !check_port means available
            echo $port
            return 0
        fi
        port=$((port + 1))
    done
    
    echo ""  # No port found
    return 1
}

echo "Checking port availability..."
echo ""

# Check backend port (5000)
# check_port returns 0 if available, non-zero if in use
if check_port 5000; then
    echo "✓ Port 5000 (backend) is available"
else
    echo "✗ Port 5000 (backend) is in use"
    alt_port=$(find_available_port 5001)
    if [ -n "$alt_port" ]; then
        echo "  → Use port $alt_port instead:"
        echo "    PORT=$alt_port python3 backend_server.py"
    fi
fi

# Check frontend port (3000)
if check_port 3000; then
    echo "✓ Port 3000 (frontend) is available"
else
    echo "✗ Port 3000 (frontend) is in use"
    alt_port=$(find_available_port 3001)
    if [ -n "$alt_port" ]; then
        echo "  → Use port $alt_port instead:"
        echo "    cd frontend && PORT=$alt_port npm run dev"
    fi
fi

echo ""

