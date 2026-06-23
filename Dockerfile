FROM debian:bookworm-slim

# Install dependencies and Tailscale
RUN apt-get update && apt-get install -y \
    curl \
    gpg \
    netcat-openbsd \
    && curl -fsSL https://tailscale.com | gpg --dearmor -o /usr/share/keyrings/tailscale-archive-keyring.gpg \
    && curl -fsSL https://tailscale.com | tee /etc/apt/sources.list.d/tailscale.list \
    && apt-get update && apt-get install -y tailscale \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy and prepare the startup script
COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

# Expose a dummy port to satisfy Render's health checks
EXPOSE 8080

CMD ["/app/start.sh"]
