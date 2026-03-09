FROM node:22-slim

# Install git, curl, and other dependencies
RUN apt-get update && apt-get install -y git curl ca-certificates python3 make g++ \
    && rm -rf /var/lib/apt/lists/*

# Install OpenClaw globally
RUN npm install -g openclaw

# Create directories
RUN mkdir -p /data/.openclaw/workspace

# Set environment variables
ENV OPENCLAW_STATE_DIR=/data/.openclaw
ENV OPENCLAW_WORKSPACE_DIR=/data/.openclaw/workspace
ENV OPENCLAW_GATEWAY_TOKEN=iao-fund-gateway-token-2026
ENV NODE_ENV=production

# Copy workspace files
COPY . /data/.openclaw/workspace/

# Set working directory
WORKDIR /data/.openclaw/workspace

# Expose gateway port
EXPOSE 8080

# Run OpenClaw gateway in foreground mode, binding to 0.0.0.0 for Railway
CMD ["openclaw", "gateway", "run", \
     "--bind", "0.0.0.0", \
     "--port", "8080", \
     "--auth", "token", \
     "--token", "iao-fund-gateway-token-2026", \
     "--allow-unconfigured"]
