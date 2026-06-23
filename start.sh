#!/bin/sh

LISTEN_PORT=${PORT:-10000}
STATE_FILE="/var/lib/tailscale/tailscaled.state"

# Ensure the local tailscale system directory exists
mkdir -p /var/lib/tailscale

# 1. Download existing state from Supabase if it exists (Fixed URL)
if [ -n "$SUPABASE_URL" ] && [ -n "$SUPABASE_KEY" ]; then
    echo "Attempting to fetch Tailscale state from Supabase..."
    HTTP_CODE=$(curl -s -o "$STATE_FILE" -w "%{http_code}" \
        -H "Authorization: Bearer $SUPABASE_KEY" \
        -H "apikey: $SUPABASE_KEY" \
        "$SUPABASE_URL/storage/v1/object/tailscale/tailscaled.state")
    
    if [ "$HTTP_CODE" = "200" ]; then
        echo "Successfully restored Tailscale identity from Supabase."
    else
        echo "No existing state found (HTTP $HTTP_CODE). Proceeding with fresh provisioning."
        rm -f "$STATE_FILE"
    fi
fi

# 2. Start Tailscale daemon in userspace mode
tailscaled --tun=userspace-networking &
sleep 2

# 3. Connect to Tailscale and advertise as an exit node
echo "Connecting to Tailscale network..."
tailscale up --authkey="${TAILSCALE_AUTH_KEY}" --hostname="render-vpn-exit" --advertise-exit-node

# Give the daemon 3 seconds to fully finalize and write the state file to disk
sleep 3

# 4. Upload the generated state file back to Supabase (Fixed URL)
if [ -n "$SUPABASE_URL" ] && [ -n "$SUPABASE_KEY" ] && [ -f "$STATE_FILE" ]; then
    echo "Backing up current Tailscale state to Supabase..."
    UPLOAD_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST \
        -H "Authorization: Bearer $SUPABASE_KEY" \
        -H "apikey: $SUPABASE_KEY" \
        -H "x-upsert: true" \
        -H "Content-Type: application/octet-stream" \
        --data-binary @"$STATE_FILE" \
        "$SUPABASE_URL/storage/v1/object/tailscale/tailscaled.state")
    echo "State backup completed with HTTP status: $UPLOAD_CODE"
fi

# 5. Handle Render's required web server port smoothly
echo "VPN Node is ready. Starting web listener on port $LISTEN_PORT..."
while true; do 
    printf "HTTP/1.1 200 OK\r\nContent-Length: 15\r\nConnection: close\r\n\r\nVPN Node Online" | nc -l -p "$LISTEN_PORT"
done
