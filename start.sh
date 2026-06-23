#!/bin/sh

# 1. Use Render's assigned port (defaults to 10000)
LISTEN_PORT=${PORT:-10000}

# 2. Start Tailscale daemon in userspace mode
tailscaled --tun=userspace-networking &
sleep 2

# 3. Connect to Tailscale and advertise as an exit node
echo "Connecting to Tailscale network..."
tailscale up --authkey="${TAILSCALE_AUTH_KEY}" --hostname="render-vpn-exit" --advertise-exit-node

# 4. Handle Render's required web server port smoothly
echo "VPN Node is ready. Starting web listener on port $LISTEN_PORT..."
while true; do 
    # Adding 'Connection: close' forces Render to drop the connection immediately, 
    # allowing the loop to quickly reset for the next health check.
    printf "HTTP/1.1 200 OK\r\nContent-Length: 15\r\nConnection: close\r\n\r\nVPN Node Online" | nc -l -p "$LISTEN_PORT"
done
