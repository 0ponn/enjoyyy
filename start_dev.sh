#!/bin/bash
# Reliable development server starter with automatic port detection

check_port() {
    local port=$1
    # connect_ex returns 0 if connection succeeds (port in use), non-zero if fails (port available)
    python3 -c "import socket; s = socket.socket(); s.settimeout(0.1); result = s.connect_ex(('127.0.0.1', $port)); s.close(); exit(0 if result == 0 else 1)" 2>/dev/null
    # Return 0 if port is available, non-zero if in use
    return $?
}

find_available_port() {
    local start_port=$1
    local port=$start_port
    local max_port=$((start_port + 100))
    
    while [ $port -lt $max_port ]; do
        if check_port $port; then
            # check_port returns 0 if available
            echo $port
            return 0
        fi
        port=$((port + 1))
    done
    
    return 1
}

# Backend port detection
BACKEND_PORT=5000
if ! check_port $BACKEND_PORT; then
    echo "Port $BACKEND_PORT is in use, finding alternative..."
    alt_port=$(find_available_port 5001)
    if [ -n "$alt_port" ]; then
        BACKEND_PORT=$alt_port
        echo "Using port $BACKEND_PORT for backend"
    else
        echo "Error: Could not find available port for backend"
        exit 1
    fi
fi

# Frontend port detection
FRONTEND_PORT=3000
if ! check_port $FRONTEND_PORT; then
    echo "Port $FRONTEND_PORT is in use, finding alternative..."
    alt_port=$(find_available_port 3001)
    if [ -n "$alt_port" ]; then
        FRONTEND_PORT=$alt_port
        echo "Using port $FRONTEND_PORT for frontend"
    else
        echo "Error: Could not find available port for frontend"
        exit 1
    fi
fi

echo ""
echo "Starting servers:"
echo "  Backend:  http://localhost:$BACKEND_PORT"
echo "  Frontend: http://localhost:$FRONTEND_PORT"
echo ""
echo "Press Ctrl+C to stop both servers"
echo ""

# Start backend in background
export PORT=$BACKEND_PORT
python3 backend_server.py > /tmp/enjoyyy_backend.log 2>&1 &
BACKEND_PID=$!

# Wait a moment for backend to start
sleep 2

# Start frontend
cd frontend
export PORT=$FRONTEND_PORT
npm run dev > /tmp/enjoyyy_frontend.log 2>&1 &
FRONTEND_PID=$!

# Function to cleanup on exit
cleanup() {
    echo ""
    echo "Stopping servers..."
    kill $BACKEND_PID 2>/dev/null
    kill $FRONTEND_PID 2>/dev/null
    exit 0
}

trap cleanup SIGINT SIGTERM

# Wait for both processes
wait

