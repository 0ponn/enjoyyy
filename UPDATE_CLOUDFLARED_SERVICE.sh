#!/bin/bash
# Script to update cloudflared service with new token

echo "Updating cloudflared service..."

# Stop the service
echo "1. Stopping cloudflared service..."
sudo systemctl stop cloudflared

# Uninstall old service
echo "2. Uninstalling old cloudflared service..."
sudo cloudflared service uninstall

# Install with new token
echo "3. Installing cloudflared service with new token..."
sudo cloudflared service install eyJhIjoiN2VhYmYwOWFmN2ZkNjFhYTRjZDY1MzY5NzEwZTQ1MmUiLCJ0IjoiZTE0MTIxYWItODZkYy00NmEzLThlODgtYWJlMmQ4MjUwYjY5IiwicyI6Ik16RXlaVGd4TkRJdE1qWmpOQzAwT1dRMkxUaGhOVGN0WW1RME16RXhaV0l5T0dReiJ9

# Enable and start
echo "4. Enabling and starting service..."
sudo systemctl enable cloudflared
sudo systemctl start cloudflared

# Check status
echo ""
echo "5. Checking status..."
sleep 2
sudo systemctl status cloudflared --no-pager | head -15

echo ""
echo "✅ Done! Check Cloudflare dashboard to verify connector is 'Connected'"

