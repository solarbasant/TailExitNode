#!/bin/sh

# 1. Start Tailscale daemon in userspace mode (required for Render)
tailscaled --tun=userspace-networking &

# Wait for daemon to initialize
sleep 2

# 2. Connect to Tailscale and advertise as an exit node
echo "Connecting to Tailscale network..."
tailscale up --authkey="${TAILSCALE_AUTH_KEY}" --hostname="render-vpn-exit" --advertise-exit-node

# 3. Prevent Render from shutting down the app
# Keeps port 8080 open so Render's HTTP health check passes
echo "VPN Node is ready. Starting dummy web listener..."
while true; do 
    echo -e "HTTP/1.1 200 OK\r\nContent-Length: 15\r\n\r\nVPN Node Online" | nc -l -p 8080
done
