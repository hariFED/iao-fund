FROM node:22-slim

RUN apt-get update && apt-get install -y git curl ca-certificates python3 make g++ \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g openclaw

RUN mkdir -p /data/.openclaw/workspace /data/.openclaw/canvas

ENV OPENCLAW_STATE_DIR=/data/.openclaw
ENV OPENCLAW_WORKSPACE_DIR=/data/.openclaw/workspace
ENV OPENCLAW_GATEWAY_TOKEN=iao-fund-gateway-token-2026
ENV NODE_ENV=production
ENV PORT=8080

# Copy config first (will be overridden by workspace copy if exists)
COPY openclaw.json /data/.openclaw/openclaw.json

# Copy workspace files
COPY . /data/.openclaw/workspace/

# Re-copy config to ensure it's correct (workspace copy might have old version)
COPY openclaw.json /data/.openclaw/openclaw.json

WORKDIR /data/.openclaw/workspace

EXPOSE 8080

# Use exec form to ensure proper signal handling
CMD ["sh", "-c", "openclaw gateway run --allow-unconfigured --port $PORT --bind lan"]
