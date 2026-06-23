FROM debian:bookworm-slim

# Install core dependencies, then run official Tailscale setup script
RUN apt-get update && apt-get install -y \
    curl \
    netcat-openbsd \
    && curl -fsSL https://tailscale.com/install.sh | sh \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy and prepare the startup script
COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

# Expose the port Render expects
EXPOSE 8080

CMD ["/app/start.sh"]
