FROM node:22-slim

# Install git, curl, and other dependencies
RUN apt-get update && apt-get install -y git curl ca-certificates python3 make g++ \
    && rm -rf /var/lib/apt/lists/*

# Install OpenClaw globally
RUN npm install -g openclaw

# Create directories
RUN mkdir -p /data/.openclaw/workspace /data/.openclaw/canvas

# Set environment variables
ENV OPENCLAW_STATE_DIR=/data/.openclaw
ENV OPENCLAW_WORKSPACE_DIR=/data/.openclaw/workspace
ENV OPENCLAW_GATEWAY_TOKEN=iao-fund-gateway-token-2026
ENV NODE_ENV=production

# Copy workspace files
COPY . /data/.openclaw/workspace/

# Copy config to state dir
COPY openclaw.json /data/.openclaw/openclaw.json

# Set working directory
WORKDIR /data/.openclaw/workspace

# Expose both gateway and canvas ports
EXPOSE 8080 8082

# Run OpenClaw gateway with explicit bind to 0.0.0.0 and port 8080
CMD ["openclaw", "gateway", "run", \
     "--bind", "0.0.0.0", \
     "--port", "8080", \
     "--auth", "token", \
     "--token", "iao-fund-gateway-token-2026"]
