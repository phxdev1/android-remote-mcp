#!/bin/bash
set -e

# Start Tailscale if TS_AUTHKEY is provided
if [ -n "$TS_AUTHKEY" ]; then
    echo "Starting Tailscale..."
    tailscale up --authkey="$TS_AUTHKEY" --hostname="android-mcp-server" --accept-routes --accept-dns
    
    # Wait for Tailscale to be fully connected
    echo "Waiting for Tailscale connection..."
    timeout=30
    count=0
    while ! tailscale status | grep -q "authenticated"; do
        sleep 1
        count=$((count + 1))
        if [ $count -ge $timeout ]; then
            echo "Timed out waiting for Tailscale to connect"
            exit 1
        fi
    done
    
    echo "Tailscale connected successfully!"
    tailscale status
    
    # Record local Tailscale IP
    TAILSCALE_IP=$(tailscale ip -4)
    echo "Tailscale IP: $TAILSCALE_IP"
    export TAILSCALE_IP
else
    echo "No TS_AUTHKEY provided. Tailscale will not be started."
    echo "You can add this later by setting the TS_AUTHKEY environment variable."
fi

# Start the Node.js application
echo "Starting MCP Server..."
cd /app
node server.js