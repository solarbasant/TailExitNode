#!/bin/sh

# 1. Start Tailscale daemon in userspace mode
tailscaled --tun=userspace-networking &
sleep 2

# 2. Connect to Tailscale and advertise as an exit node
echo "Connecting to Tailscale network..."
tailscale up --authkey="${TAILSCALE_AUTH_KEY}" --hostname="render-vpn-exit" --advertise-exit-node

# 3. Handle Render's required web server port
echo "VPN Node is ready. Starting web listener..."
while true; do 
    printf "HTTP/1.1 200 OK\r\nContent-Length: 15\r\n\r\nVPN Node Online" | nc -l -p 8080
done
